#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Migración ERP (MariaDB) → ALMA_BE_V2 (PostgreSQL) — Módulo Académico
Integra pandas para lecturas vectorizadas, transformaciones y deduplicación.
Las escrituras usan psycopg2.execute_values (más rápido que DataFrame.to_sql).

Tablas cubiertas (orden FK estricto):
  institutes, campuses, campus_spaces,
  program_courses, course_requirements,
  course_groups, group_sessions,
  group_profiles, group_profile_assistance,
  course_media_resources, group_session_videos,
  course_group_media_resources

Prerequisito: migration_mariadb.py debe haberse ejecutado primero.
"""

import io
import os
import sys
import traceback
import uuid
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from urllib.parse import quote_plus

from dotenv import load_dotenv

# Buscar .env en el directorio raíz del proyecto (un nivel arriba de Mig_DB/)
_ENV_PATH = Path(__file__).parent.parent / ".env"
load_dotenv(_ENV_PATH)

import numpy as np
import pandas as pd
from sqlalchemy import create_engine, text
import psycopg2
from psycopg2.extras import execute_values

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)-8s] %(message)s",
    handlers=[
        logging.FileHandler("migration_academic.log", encoding="utf-8"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger(__name__)

NOW = datetime.now()
BATCH = 5000


# ──────────────────────────────────────────────────────────────────────────────
# Utilidades de datos
# ──────────────────────────────────────────────────────────────────────────────

def det_uuid(namespace: str, key: str) -> str:
    """UUID determinista: misma entrada → mismo UUID en cada ejecución."""
    return str(uuid.uuid5(uuid.NAMESPACE_OID, f"{namespace}:{key}"))


def to_records(df: pd.DataFrame) -> list:
    """
    Convierte un DataFrame a lista de tuplas compatible con psycopg2:
      - NaN / NaT / pd.NA  → None
      - pd.Timestamp        → datetime (Python nativo)
      - pd.Timedelta        → "HH:MM:SS"
      - np.integer          → int
      - np.floating         → float (o None si NaN)
      - np.bool_            → bool
    """
    def _clean(v):
        # NA check primero (NaN, NaT, None, pd.NA)
        try:
            if pd.isna(v):
                return None
        except (TypeError, ValueError):
            pass
        if isinstance(v, pd.Timestamp):
            return v.to_pydatetime()
        if isinstance(v, pd.Timedelta):
            total = int(v.total_seconds())
            h, rem = divmod(abs(total), 3600)
            m, s = divmod(rem, 60)
            return f"{h:02d}:{m:02d}:{s:02d}"
        if isinstance(v, np.integer):
            return int(v)
        if isinstance(v, np.floating):
            return None if np.isnan(v) else float(v)
        if isinstance(v, np.bool_):
            return bool(v)
        return v

    return [tuple(_clean(v) for v in row) for row in df.itertuples(index=False, name=None)]


# ──────────────────────────────────────────────────────────────────────────────
# Transformaciones de estado ERP → enum almadb (funciones escalares)
# Se usan con Series.map() en pandas
# ──────────────────────────────────────────────────────────────────────────────

def map_vigente(v) -> str:
    return "ACTIVE" if v else "INACTIVE"


def map_course_status(estado: Optional[str]) -> str:
    if not estado:
        return "ACTIVE"
    s = estado.strip().lower()
    return "INACTIVE" if any(w in s for w in ("inactiv", "cerrad", "anulad")) else "ACTIVE"


def map_space_status(estado: Optional[str]) -> str:
    if not estado:
        return "ACTIVE"
    s = estado.strip().lower()
    return "INACTIVE" if any(w in s for w in ("inactiv", "cerrad", "anulad")) else "ACTIVE"


def map_group_status(estado: Optional[str]) -> str:
    if not estado:
        return "ACTIVE"
    s = estado.strip().lower()
    if any(w in s for w in ("cerrad", "finaliz", "closed", "finish", "suspendid", "suspend")):
        return "INACTIVE"
    return "ACTIVE"


def map_session_status(estado: Optional[str]) -> str:
    if not estado:
        return "SCHEDULED"
    s = estado.strip().lower()
    if any(w in s for w in ("cancelad", "cancel")):
        return "CANCELLED"
    if any(w in s for w in ("realiz", "complet", "dictad", "finish")):
        return "COMPLETED"
    return "SCHEDULED"


def map_material_type(tipo: Optional[str]) -> str:
    if not tipo:
        return "DOCUMENT"
    s = tipo.strip().lower()
    if "video" in s:
        return "VIDEO"
    if "audio" in s:
        return "AUDIO"
    if any(w in s for w in ("enlace", "link", "url")):
        return "LINK"
    return "DOCUMENT"


# ──────────────────────────────────────────────────────────────────────────────
# Migrador
# ──────────────────────────────────────────────────────────────────────────────

class AcademicMigrator:
    def __init__(
        self,
        mariadb_config: Dict,
        postgres_config: Dict,
        institute_name: str = "Corporación La Comunidad",
        institute_acronym: str = "CLC",
        limit: Optional[int] = None,
    ):
        self.mariadb_config = mariadb_config
        self.postgres_config = postgres_config
        self.institute_name = institute_name
        self.institute_acronym = institute_acronym
        self.limit = limit

        # Conexiones DBAPI (psycopg2 para escrituras)
        self.pg_conn = None

        # Engines SQLAlchemy (pandas reads)
        self.mysql_engine = None
        self.pg_engine = None

        # ── ID maps ERP → PostgreSQL (pd.Series para .map() vectorizado)
        self.profile_map: pd.Series = pd.Series(dtype="Int64")
        # índice: erp_usuario.id → valor: pg_profiles.id

        self.campus_map: pd.Series = pd.Series(dtype="Int64")
        self.space_map: pd.Series = pd.Series(dtype="Int64")
        # espacio: índice compuesto como "sede_salon" string

        self.course_map: pd.Series = pd.Series(dtype="Int64")
        self.group_map: pd.Series = pd.Series(dtype="Int64")
        self.session_map: pd.Series = pd.Series(dtype="Int64")
        self.media_url_map: Dict[str, int] = {}

        self.institute_id: Optional[int] = None

        # ── Lookup tables ERP: id → texto (pd.Series para .map() vectorizado)
        self.est_grupo_ser: pd.Series = pd.Series(dtype=str)
        self.est_clase_ser: pd.Series = pd.Series(dtype=str)
        self.est_materia_ser: pd.Series = pd.Series(dtype=str)
        self.est_salon_ser: pd.Series = pd.Series(dtype=str)
        self.t_material_ser: pd.Series = pd.Series(dtype=str)

        self.stats = {
            "migrated_tables": 0,
            "total_records": 0,
            "migrated_records": 0,
            "errors": [],
            "start_time": datetime.now(),
        }

    # ──────────────────────────────────────────────────────────────────────────
    # Conexiones
    # ──────────────────────────────────────────────────────────────────────────

    def connect(self) -> bool:
        mc = self.mariadb_config
        pc = self.postgres_config

        # MySQL SQLAlchemy engine (pandas reads)
        try:
            url = (
                f"mysql+mysqlconnector://{quote_plus(mc['user'])}:{quote_plus(mc['password'])}"
                f"@{mc['host']}:{mc.get('port', 3306)}/{mc['database']}"
            )
            self.mysql_engine = create_engine(url, pool_pre_ping=True)
            with self.mysql_engine.connect() as conn:
                ver = conn.execute(text("SELECT VERSION()")).scalar()
            logger.info(f"✓ MariaDB {ver}")
        except Exception as err:
            logger.error(f"✗ MariaDB SQLAlchemy: {err}")
            return False

        # PostgreSQL psycopg2 (escrituras con execute_values)
        try:
            self.pg_conn = psycopg2.connect(**pc)
            self.pg_conn.autocommit = False
            with self.pg_conn.cursor() as cur:
                cur.execute("SET synchronous_commit = OFF")
                cur.execute("SET work_mem = '256MB'")
                cur.execute("SET maintenance_work_mem = '512MB'")
            self.pg_conn.commit()
            logger.info("✓ PostgreSQL psycopg2 OK")
        except psycopg2.Error as err:
            logger.error(f"✗ PostgreSQL psycopg2: {err}")
            return False

        # PostgreSQL SQLAlchemy engine (pandas reads: rebuild maps)
        try:
            url_pg = (
                f"postgresql+psycopg2://{quote_plus(pc['user'])}:{quote_plus(pc['password'])}"
                f"@{pc['host']}:{pc.get('port', 5432)}/{pc['database']}"
            )
            self.pg_engine = create_engine(url_pg, pool_pre_ping=True)
            logger.info("✓ PostgreSQL SQLAlchemy OK")
        except Exception as err:
            logger.error(f"✗ PostgreSQL SQLAlchemy: {err}")
            return False

        return True

    def disconnect(self):
        if self.pg_conn:
            self.pg_conn.close()
        if self.mysql_engine:
            self.mysql_engine.dispose()
        if self.pg_engine:
            self.pg_engine.dispose()

    # ──────────────────────────────────────────────────────────────────────────
    # Helpers internos
    # ──────────────────────────────────────────────────────────────────────────

    def _limit_sql(self) -> str:
        return f"LIMIT {self.limit}" if self.limit is not None else ""

    def _rq(self, sql: str) -> pd.DataFrame:
        """Read query from MySQL → DataFrame."""
        with self.mysql_engine.connect() as conn:
            return pd.read_sql(text(sql), conn)

    def _rqpg(self, sql: str) -> pd.DataFrame:
        """Read query from PostgreSQL → DataFrame."""
        with self.pg_engine.connect() as conn:
            return pd.read_sql(text(sql), conn)

    def _bulk_write(self, sql: str, rows: list) -> int:
        """Batch insert with execute_values. Returns number of rows sent."""
        if not rows:
            return 0
        cur = self.pg_conn.cursor()
        for i in range(0, len(rows), BATCH):
            execute_values(cur, sql, rows[i : i + BATCH], page_size=BATCH)
        cur.close()
        return len(rows)

    def _bulk_write_returning(self, sql: str, rows: list) -> List[tuple]:
        """execute_values con RETURNING. Devuelve lista de (id, uuid) sin query extra."""
        if not rows:
            return []
        cur = self.pg_conn.cursor()
        result: List[tuple] = []
        for i in range(0, len(rows), BATCH):
            result.extend(
                execute_values(cur, sql, rows[i : i + BATCH], page_size=BATCH, fetch=True)
            )
        cur.close()
        return result

    def _copy_insert(self, table: str, columns: List[str], rows: list, conflict_col: str = "uuid") -> int:
        """
        COPY vía STDIN a tabla temporal, luego INSERT ON CONFLICT desde temp.
        3–10x más rápido que execute_values para tablas > 50k filas.
        """
        if not rows:
            return 0
        buf = io.StringIO()
        for row in rows:
            parts: List[str] = []
            for v in row:
                if v is None:
                    parts.append(r"\N")
                elif isinstance(v, bool):
                    parts.append("t" if v else "f")
                elif isinstance(v, datetime):
                    parts.append(v.strftime("%Y-%m-%d %H:%M:%S"))
                else:
                    parts.append(
                        str(v)
                        .replace("\\", "\\\\")
                        .replace("\t", "\\t")
                        .replace("\n", "\\n")
                        .replace("\r", "")
                    )
            buf.write("\t".join(parts) + "\n")
        buf.seek(0)

        tmp = "_mig_copy_tmp"
        col_list = ", ".join(f'"{c}"' for c in columns)
        cur = self.pg_conn.cursor()
        cur.execute(
            f"CREATE TEMP TABLE IF NOT EXISTS {tmp} "
            f"(LIKE {table} INCLUDING DEFAULTS) ON COMMIT DROP"
        )
        cur.execute(f"TRUNCATE {tmp}")
        cur.copy_from(buf, tmp, columns=columns, null=r"\N")
        cur.execute(
            f"INSERT INTO {table} ({col_list}) SELECT {col_list} FROM {tmp} "
            f"ON CONFLICT ({conflict_col}) DO NOTHING"
        )
        n = cur.rowcount
        cur.close()
        return n

    def _pg_map_from_uuids(self, table: str, uuids: List[str]) -> pd.DataFrame:
        """Fallback: reconstruye uuid→id consultando la tabla destino."""
        if not uuids:
            return pd.DataFrame({"uuid": pd.Series(dtype=str), "pg_id": pd.Series(dtype="Int64")})
        cur = self.pg_conn.cursor()
        cur.execute(f"SELECT uuid::text, id FROM {table} WHERE uuid = ANY(%s)", (uuids,))
        rows = cur.fetchall()
        cur.close()
        df = pd.DataFrame(rows, columns=["uuid", "pg_id"])
        df["uuid"]  = df["uuid"].astype(str)
        df["pg_id"] = df["pg_id"].astype("Int64")
        return df

    def _log_step(self, table: str, migrated: int, total: int):
        self.stats["migrated_tables"] += 1
        self.stats["migrated_records"] += migrated
        self.stats["total_records"] += total
        logger.info(f"✓ {migrated}/{total} {table}")

    def _insert_one(self, sql: str, params: tuple) -> Optional[int]:
        """Inserta un único registro con SAVEPOINT. Devuelve el id o None."""
        cur = self.pg_conn.cursor()
        cur.execute("SAVEPOINT sp_one")
        try:
            cur.execute(sql, params)
            row = cur.fetchone()
            cur.execute("RELEASE SAVEPOINT sp_one")
            cur.close()
            return row[0] if row else None
        except psycopg2.IntegrityError:
            cur.execute("ROLLBACK TO SAVEPOINT sp_one")
            cur.execute("RELEASE SAVEPOINT sp_one")
            cur.close()
            return None

    # ──────────────────────────────────────────────────────────────────────────
    # Tablas de referencia ERP → pd.Series para .map() vectorizado
    # ──────────────────────────────────────────────────────────────────────────

    def _load_lookup_tables(self):
        for table, attr in [
            ("est_grupo",   "est_grupo_ser"),
            ("est_clase",   "est_clase_ser"),
            ("est_materia", "est_materia_ser"),
            ("est_salon",   "est_salon_ser"),
        ]:
            try:
                df = self._rq(f"SELECT id, estado FROM {table}")
                setattr(self, attr, df.set_index("id")["estado"])
                logger.info(f"  lookup {table}: {len(df)} filas")
            except Exception as err:
                logger.warning(f"  No se pudo cargar {table}: {err}")

        try:
            df = self._rq("SELECT id, tipo FROM t_material")
            self.t_material_ser = df.set_index("id")["tipo"]
            logger.info(f"  lookup t_material: {len(df)} filas")
        except Exception as err:
            logger.warning(f"  No se pudo cargar t_material: {err}")

    def _rebuild_profile_map(self):
        """
        Reconstruye el mapa erp_usuario.id → pg_profiles.id desde PostgreSQL.
        provider_auth_id = 'erp_usuario_{id}_{dni}'
        """
        df = self._rqpg(
            """
            SELECT u.provider_auth_id, p.id AS profile_id
            FROM profiles p
            JOIN users u ON p.user_id = u.id
            WHERE u.provider_auth_id LIKE 'erp_usuario_%'
            """
        )
        if df.empty:
            logger.warning("  profile_map vacío — ¿se ejecutó migration_mariadb.py?")
            return

        # Extraer erp_usuario.id del provider_auth_id con regex
        df["erp_id"] = (
            df["provider_auth_id"]
            .str.extract(r"^erp_usuario_(\d+)_")[0]
            .astype("Int64")
        )
        df = df.dropna(subset=["erp_id"])
        # Si el mismo erp_id tiene varios profiles (múltiples tipos de doc), quedarse con el menor
        df = df.sort_values("profile_id").drop_duplicates(subset=["erp_id"], keep="first")
        self.profile_map = df.set_index("erp_id")["profile_id"].astype("Int64")
        logger.info(f"  profile_map: {len(self.profile_map)} entradas")

    # ──────────────────────────────────────────────────────────────────────────
    # 1. institutes
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_institute(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: institutes")
        try:
            inst_uuid = det_uuid("institute", self.institute_name)
            pg_id = self._insert_one(
                """
                INSERT INTO institutes (uuid, name, acronym, status, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (uuid) DO UPDATE SET name = EXCLUDED.name
                RETURNING id
                """,
                (inst_uuid, self.institute_name, self.institute_acronym, "ACTIVE", NOW, NOW),
            )
            if pg_id is None:
                cur = self.pg_conn.cursor()
                cur.execute("SELECT id FROM institutes WHERE uuid = %s", (inst_uuid,))
                row = cur.fetchone()
                cur.close()
                pg_id = row[0] if row else None

            self.institute_id = pg_id
            self.pg_conn.commit()
            self._log_step("institutes", 1, 1)
            logger.info(f"  institute_id={pg_id}  '{self.institute_name}'")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ institutes: {err}")
            self.stats["errors"].append(f"institutes: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 2. campuses  ←  sede
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_campuses(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: campuses  ←  sede")
        try:
            df = self._rq(
                "SELECT id, nombre, direccion, email, telefono, vigente, fecha_trans"
                " FROM sede ORDER BY id"
            )

            # Transformaciones vectorizadas
            df["uuid"]       = [det_uuid("campus", str(x)) for x in df["id"].values]
            df["status"]     = df["vigente"].fillna(0).astype(bool).map({True: "ACTIVE", False: "INACTIVE"})
            df["created_at"] = pd.to_datetime(df["fecha_trans"]).fillna(NOW)
            df["updated_at"] = NOW
            # email es NOT NULL en almadb; usar placeholder cuando ERP no lo tiene
            df["email"] = df["email"].fillna(
                df["nombre"].str.lower().str.replace(r"\s+", "", regex=True) + "@noemail.co"
            )

            cols = ["uuid", "nombre", "direccion", "email", "telefono",
                    "status", "created_at", "updated_at"]
            rows = to_records(df[cols])

            returned = self._bulk_write_returning(
                """
                INSERT INTO campuses (uuid, name, address, email, phone,
                                      status, created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO UPDATE
                    SET name = EXCLUDED.name, status = EXCLUDED.status
                RETURNING id, uuid
                """,
                rows,
            )
            self.pg_conn.commit()

            uuid_pgid = {str(r[1]): r[0] for r in returned}
            self.campus_map = df.set_index("id")["uuid"].map(uuid_pgid).astype("Int64")

            self._log_step("campuses", len(merged), len(df))
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ campuses: {err}")
            self.stats["errors"].append(f"campuses: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 3. campus_spaces  ←  salon
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_campus_spaces(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: campus_spaces  ←  salon")
        try:
            df = self._rq(
                """
                SELECT s.sede, s.id, s.descripcion, s.capacidad,
                       es.estado  AS est_nombre,
                       s.fecha_trans    AS created_at,
                       s.fecha_modificar AS updated_at
                FROM salon s
                LEFT JOIN est_salon es ON es.id = s.est_salon
                ORDER BY s.sede, s.id
                """
            )

            # Mapear campus_id y descartar sin sede
            df["campus_id"] = df["sede"].map(self.campus_map)
            before = len(df)
            df = df.dropna(subset=["campus_id"])
            skipped = before - len(df)

            # Transformaciones vectorizadas
            df["uuid"]       = [det_uuid("campus_space", f"{a}_{b}") for a, b in zip(df["sede"].values, df["id"].values)]
            df["code"]       = "S" + df["sede"].astype(str) + "-" + df["id"].astype(str)
            df["name"]       = df["descripcion"].where(df["descripcion"].notna(), df["code"])
            df["type"]       = "CLASSROOM"
            df["status"]     = df["est_nombre"].map(map_space_status).fillna("ACTIVE")
            df["campus_id"]  = df["campus_id"].astype(int)
            df["created_at"] = pd.to_datetime(df["created_at"]).fillna(NOW)
            df["updated_at"] = pd.to_datetime(df["updated_at"]).fillna(NOW)

            cols = ["uuid", "campus_id", "name", "code", "capacidad",
                    "type", "status", "created_at", "updated_at"]
            rows = to_records(df[cols])

            returned = self._bulk_write_returning(
                """
                INSERT INTO campus_spaces
                    (uuid, campus_id, name, code, capacity, type, status,
                     created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO UPDATE
                    SET name = EXCLUDED.name, status = EXCLUDED.status
                RETURNING id, uuid
                """,
                rows,
            )
            self.pg_conn.commit()

            uuid_pgid = {str(r[1]): r[0] for r in returned}
            merged = df[["sede", "id", "uuid"]].copy()
            merged["pg_id"] = merged["uuid"].map(uuid_pgid)
            merged = merged.dropna(subset=["pg_id"])
            self.space_map = pd.Series(
                merged["pg_id"].values,
                index=merged["sede"].astype(str) + "_" + merged["id"].astype(str),
                dtype="Int64",
            )

            self._log_step("campus_spaces", len(merged), len(df) + skipped)
            if skipped:
                logger.warning(f"  Omitidos sin sede mapeada: {skipped}")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ campus_spaces: {err}")
            traceback.print_exc()
            self.stats["errors"].append(f"campus_spaces: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 4. program_courses  ←  materia
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_program_courses(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: program_courses  ←  materia")
        try:
            df = self._rq(
                """
                SELECT m.id, m.nombre, m.descripcion, m.creditos, m.valor_matricula,
                       em.estado  AS est_nombre,
                       m.fecha_trans     AS created_at,
                       m.fecha_modificar AS updated_at
                FROM materia m
                LEFT JOIN est_materia em ON em.id = m.est_materia
                ORDER BY m.id
                """
            )

            df["uuid"]                = [det_uuid("program_course", str(x)) for x in df["id"].values]
            df["status"]              = df["est_nombre"].map(map_course_status).fillna("ACTIVE")
            df["institute_program_id"] = self.institute_id
            df["created_at"]          = pd.to_datetime(df["created_at"]).fillna(NOW)
            df["updated_at"]          = pd.to_datetime(df["updated_at"]).fillna(NOW)

            cols = ["uuid", "institute_program_id", "nombre", "descripcion",
                    "status", "valor_matricula", "creditos", "created_at", "updated_at"]
            rows = to_records(df[cols])

            returned = self._bulk_write_returning(
                """
                INSERT INTO program_courses
                    (uuid, institute_program_id, name, description, status,
                     enrollment_value, credits, created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO UPDATE
                    SET name = EXCLUDED.name, status = EXCLUDED.status
                RETURNING id, uuid
                """,
                rows,
            )
            self.pg_conn.commit()

            uuid_pgid = {str(r[1]): r[0] for r in returned}
            self.course_map = df.set_index("id")["uuid"].map(uuid_pgid).astype("Int64")

            self._log_step("program_courses", len(merged), len(df))
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ program_courses: {err}")
            self.stats["errors"].append(f"program_courses: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 5. course_requirements  ←  prerrequisito_materia + correquisito_materia
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_course_requirements(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: course_requirements")
        try:
            frames: List[pd.DataFrame] = []
            for table, req_type, req_col in [
                ("prerrequisito_materia", "PREREQUISITE", "prerrequisito"),
                ("correquisito_materia",  "COREQUISITE",  "correquisito"),
            ]:
                try:
                    df = self._rq(f"SELECT materia, {req_col} AS req FROM {table}")
                    df["type"] = req_type
                    frames.append(df)
                except Exception as err:
                    logger.warning(f"  No se pudo leer {table}: {err}")

            if not frames:
                self._log_step("course_requirements", 0, 0)
                return True

            df = pd.concat(frames, ignore_index=True)

            # Mapeo vectorizado
            df["course_id"] = df["materia"].map(self.course_map)
            df["req_id"]    = df["req"].map(self.course_map)
            before = len(df)
            df = df.dropna(subset=["course_id", "req_id"])
            skipped = before - len(df)

            df["uuid"] = [
                det_uuid("course_req", f"{t}_{m}_{r}")
                for t, m, r in zip(df["type"].values, df["materia"].values, df["req"].values)
            ]
            df["course_id"] = df["course_id"].astype(int)
            df["req_id"]    = df["req_id"].astype(int)

            rows = to_records(df[["uuid", "type", "course_id", "req_id"]])
            self._bulk_write(
                """
                INSERT INTO course_requirements (uuid, type, course_id, requirement_id)
                VALUES %s ON CONFLICT (uuid) DO NOTHING
                """,
                rows,
            )
            self.pg_conn.commit()
            self._log_step("course_requirements", len(rows), before)
            if skipped:
                logger.warning(f"  Omitidos sin materia mapeada: {skipped}")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ course_requirements: {err}")
            self.stats["errors"].append(f"course_requirements: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 6. course_groups  ←  grupo + horario_grupo
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_course_groups(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: course_groups  ←  grupo + horario_grupo")
        try:
            df = self._rq(
                f"""
                SELECT g.id, g.materia, g.sede, g.fecha_inicio, g.fecha_fin,
                       g.title,
                       eg.estado AS est_nombre,
                       h.dia, h.hora_inicio, h.salon,
                       g.fecha_trans     AS created_at,
                       g.fecha_modificar AS updated_at,
                       COALESCE(sc.cnt, 0) AS planned_sessions
                FROM grupo g
                LEFT JOIN est_grupo eg ON eg.id = g.est_grupo
                LEFT JOIN (
                    SELECT grupo, COUNT(*) AS cnt FROM clase GROUP BY grupo
                ) sc ON sc.grupo = g.id
                LEFT JOIN horario_grupo h
                    ON h.grupo = g.id
                    AND h.id = (SELECT MIN(h2.id) FROM horario_grupo h2 WHERE h2.grupo = g.id)
                ORDER BY g.id
                {self._limit_sql()}
                """
            )

            # Mapeos vectorizados FK
            df["program_course_id"] = df["materia"].map(self.course_map)
            df["campus_id"]         = df["sede"].map(self.campus_map)

            # campus_space_id por clave compuesta "sede_salon"
            space_key = df["sede"].astype(str) + "_" + df["salon"].astype(str)
            df["campus_space_id"] = space_key.map(self.space_map).where(df["salon"].notna())

            before = len(df)
            df = df.dropna(subset=["program_course_id"])   # obligatorio; sede puede ser None
            skipped = before - len(df)

            # Transformaciones vectorizadas
            df["uuid"]              = [det_uuid("course_group", str(x)) for x in df["id"].values]
            df["public_id"]         = df["title"].where(df["title"].notna(), "G-" + df["id"].astype(str))
            df["groupStatus"]       = df["est_nombre"].map(map_group_status).fillna("ACTIVE")
            df["attendance_mode"]   = "IN_PERSON"       # CourseAttendanceMode
            df["delivery_mode"]     = "SYNCHRONOUS_LIVE"  # CourseDeliveryMode
            df["program_course_id"] = df["program_course_id"].astype(int)
            df["campus_id"]         = df["campus_id"].where(df["campus_id"].notna())
            df["campus_space_id"]   = df["campus_space_id"].where(df["campus_space_id"].notna())
            df["hora_inicio"]       = df["hora_inicio"].fillna("00:00:00")

            # hora_inicio: Timedelta → "HH:MM:SS"  (via to_records)
            df["created_at"] = pd.to_datetime(df["created_at"]).fillna(NOW)
            df["updated_at"] = pd.to_datetime(df["updated_at"]).fillna(NOW)

            cols = [
                "uuid", "public_id", "program_course_id", "campus_id", "campus_space_id",
                "fecha_inicio", "fecha_fin", "groupStatus",
                "attendance_mode", "delivery_mode",
                "dia", "hora_inicio",
                "created_at", "updated_at",
            ]
            rows = to_records(df[cols])

            returned = self._bulk_write_returning(
                """
                INSERT INTO course_groups
                    (uuid, public_id, program_course_id, campus_id, campus_space_id,
                     start_date, end_date, "groupStatus",
                     attendance_mode, delivery_mode,
                     scheduled_week_day, scheduled_hour,
                     created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO UPDATE
                    SET "groupStatus" = EXCLUDED."groupStatus",
                        public_id     = EXCLUDED.public_id
                RETURNING id, uuid
                """,
                rows,
            )
            self.pg_conn.commit()

            uuid_pgid = {str(r[1]): r[0] for r in returned}
            self.group_map = df.set_index("id")["uuid"].map(uuid_pgid).astype("Int64")

            self._log_step("course_groups", len(merged), before)
            if skipped:
                logger.warning(f"  Omitidos sin materia mapeada: {skipped}")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ course_groups: {err}")
            traceback.print_exc()
            self.stats["errors"].append(f"course_groups: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 7. group_sessions  ←  clase
    # session_number calculado con groupby().cumcount() — ventaja clave de pandas
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_group_sessions(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: group_sessions  ←  clase")
        try:
            df = self._rq(
                """
                SELECT c.id, c.grupo, c.fecha_inicio,
                       ec.estado AS est_nombre,
                       h.hora_inicio,
                       c.fecha_inicio                              AS created_at,
                       COALESCE(c.fecha_cancelar, c.fecha_asistencia) AS updated_at
                FROM clase c
                LEFT JOIN est_clase ec ON ec.id = c.est_clase
                LEFT JOIN horario_grupo h ON h.id = c.horario
                ORDER BY c.grupo, c.fecha_inicio, c.id
                """
            )

            df["course_group_id"] = df["grupo"].map(self.group_map)
            before = len(df)
            df = df.dropna(subset=["course_group_id"])
            skipped = before - len(df)

            # session_number: pandas groupby cumcount (sin window function en SQL)
            df = df.sort_values(["course_group_id", "fecha_inicio", "id"])
            df["session_number"] = (
                df.groupby("course_group_id").cumcount() + 1
            )

            df["uuid"]          = [det_uuid("group_session", str(x)) for x in df["id"].values]
            df["sessionStatus"] = df["est_nombre"].map(map_session_status).fillna("SCHEDULED")
            df["course_group_id"] = df["course_group_id"].astype(int)
            df["created_at"]    = pd.to_datetime(df["created_at"]).fillna(NOW)
            df["updated_at"]    = pd.to_datetime(df["updated_at"]).fillna(NOW)

            # hora_inicio: Timedelta → "HH:MM:SS" via to_records
            cols = ["uuid", "course_group_id", "session_number", "fecha_inicio",
                    "sessionStatus", "hora_inicio", "created_at", "updated_at"]
            rows = to_records(df[cols])

            returned = self._bulk_write_returning(
                """
                INSERT INTO group_sessions
                    (uuid, course_group_id, session_number, session_date,
                     "sessionStatus", session_hour, created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO UPDATE SET session_date = EXCLUDED.session_date
                RETURNING id, uuid
                """,
                rows,
            )
            self.pg_conn.commit()

            uuid_pgid = {str(r[1]): r[0] for r in returned}
            tmp = df[["id", "uuid"]].drop_duplicates(subset=["id"], keep="first")
            self.session_map = tmp.set_index("id")["uuid"].map(uuid_pgid).astype("Int64")

            self._log_step("group_sessions", len(uuid_pgid), before)
            if skipped:
                logger.warning(f"  Omitidos sin grupo mapeado: {skipped}")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ group_sessions: {err}")
            traceback.print_exc()
            self.stats["errors"].append(f"group_sessions: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 8. group_profiles  ←  matricula_materia / maestro / asistente / monitor
    # pd.concat + drop_duplicates reemplaza el set() manual
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_group_profiles(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: group_profiles  ←  matrículas / maestros / asistentes / monitores")
        try:
            frames: List[pd.DataFrame] = []

            # 1. Alumnos matriculados
            df_s = self._rq(
                """
                SELECT mm.grupo, mm.id_alumno AS usuario_id
                FROM matricula_materia mm
                WHERE mm.vigente = 1
                  AND mm.grupo IS NOT NULL
                  AND mm.id_alumno IS NOT NULL
                """
            )
            df_s["role"] = "STUDENT"
            frames.append(df_s)
            logger.info(f"  alumnos matriculados (vigente): {len(df_s)}")

            # 2. Maestros (maestro.id = usuario.id)
            df_t = self._rq(
                """
                SELECT g.id AS grupo, m.id AS usuario_id
                FROM grupo g
                JOIN maestro m ON m.id = g.id_maestro
                WHERE g.id_maestro IS NOT NULL
                """
            )
            df_t["role"] = "TEACHER"
            frames.append(df_t)

            # 3. Asistentes
            try:
                df_a = self._rq(
                    "SELECT grupo, id_asistente AS usuario_id FROM grupo_x_asistente"
                    " WHERE id_asistente IS NOT NULL"
                )
                df_a["role"] = "ASSISTANT"
                frames.append(df_a)
            except Exception as err:
                logger.warning(f"  grupo_x_asistente no disponible: {err}")

            # 4. Monitores
            try:
                df_m = self._rq(
                    "SELECT grupo, id_monitor AS usuario_id FROM grupo_x_monitor"
                    " WHERE id_monitor IS NOT NULL"
                )
                df_m["role"] = "MONITOR"
                frames.append(df_m)
            except Exception as err:
                logger.warning(f"  grupo_x_monitor no disponible: {err}")

            # Consolidar con concat + mapeo vectorizado
            df = pd.concat(frames, ignore_index=True)
            df = df.rename(columns={"grupo": "erp_grupo"})
            total = len(df)

            df["course_group_id"] = df["erp_grupo"].map(self.group_map)
            df["profile_id"]      = df["usuario_id"].map(self.profile_map)

            df = df.dropna(subset=["course_group_id", "profile_id"])
            skipped = total - len(df)

            # Deduplicar (misma combinación grupo+perfil+rol)
            df = df.drop_duplicates(subset=["course_group_id", "profile_id", "role"])

            df["uuid"] = [
                det_uuid("group_profile", f"{a}_{b}_{c}")
                for a, b, c in zip(df["erp_grupo"].values, df["usuario_id"].values, df["role"].values)
            ]
            df["course_group_id"] = df["course_group_id"].astype(int)
            df["profile_id"]      = df["profile_id"].astype(int)
            df["created_at"]      = NOW
            df["updated_at"]      = NOW

            rows = to_records(df[["uuid", "course_group_id", "profile_id",
                                  "role", "created_at", "updated_at"]])
            self._bulk_write(
                """
                INSERT INTO group_profiles
                    (uuid, course_group_id, profile_id, enrollment_role,
                     created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO NOTHING
                """,
                rows,
            )
            self.pg_conn.commit()
            self._log_step("group_profiles", len(rows), total)
            if skipped:
                logger.warning(f"  Omitidos sin mapeo: {skipped}")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ group_profiles: {err}")
            traceback.print_exc()
            self.stats["errors"].append(f"group_profiles: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 9. group_profile_assistance  ←  asistencia_clase
    # Lectura por chunks para tablas potencialmente grandes
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_group_profile_assistance(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: group_profile_assistance  ←  asistencia_clase")
        try:
            sql = (
                "SELECT ac.clase, ac.id_alumno, ac.tipo_asistencia, "
                "ac.created_at, ac.updated_at "
                "FROM asistencia_clase ac "
                "WHERE ac.clase IS NOT NULL AND ac.id_alumno IS NOT NULL "
                "ORDER BY ac.clase, ac.id_alumno"
            )

            PRESENT = {"1", "a", "asistio", "asistió", "p", "presente", "true"}
            GPA_COLS = ["uuid", "group_session_id", "profile_id", "attended", "created_at", "updated_at"]

            # Crear tabla temporal reutilizable para COPY por chunks
            with self.pg_conn.cursor() as cur:
                cur.execute(
                    "CREATE TEMP TABLE IF NOT EXISTS _mig_gpa ("
                    "  uuid text, group_session_id int, profile_id int, "
                    "  attended bool, created_at timestamptz, updated_at timestamptz"
                    ") ON COMMIT DELETE ROWS"
                )
            self.pg_conn.commit()

            total, migrated, skipped = 0, 0, 0

            with self.mysql_engine.connect() as _conn:
                for chunk in pd.read_sql(text(sql), _conn, chunksize=20_000):
                    chunk_total = len(chunk)
                    total += chunk_total

                    chunk["group_session_id"] = chunk["clase"].map(self.session_map)
                    chunk["profile_id"]       = chunk["id_alumno"].map(self.profile_map)
                    chunk = chunk.dropna(subset=["group_session_id", "profile_id"])
                    skipped += chunk_total - len(chunk)

                    chunk["attended"] = (
                        chunk["tipo_asistencia"]
                        .astype(str).str.strip().str.lower().isin(PRESENT)
                    )
                    chunk["uuid"] = [
                        det_uuid("assistance", f"{a}_{b}")
                        for a, b in zip(chunk["clase"].values, chunk["id_alumno"].values)
                    ]
                    chunk["group_session_id"] = chunk["group_session_id"].astype(int)
                    chunk["profile_id"]       = chunk["profile_id"].astype(int)
                    chunk["created_at"]       = pd.to_datetime(chunk["created_at"]).fillna(NOW)
                    chunk["updated_at"]       = pd.to_datetime(chunk["updated_at"]).fillna(NOW)

                    rows = to_records(chunk[GPA_COLS])
                    # COPY a temp + upsert desde temp → tabla real (más rápido que execute_values)
                    n = self._copy_insert(
                        "group_profile_assistance", GPA_COLS, rows, conflict_col="uuid"
                    )
                    migrated += n
                    self.pg_conn.commit()   # commit por chunk: libera WAL y memoria

            self._log_step("group_profile_assistance", migrated, total)
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ group_profile_assistance: {err}")
            self.stats["errors"].append(f"group_profile_assistance: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 10. course_media_resources  ←  material_materia  +  clase.url_video
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_course_media_resources(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: course_media_resources  ←  material_materia + clase.url_video")
        try:
            # ── Materiales de materia
            df_mat = self._rq(
                """
                SELECT m.id, m.titulo, m.url, m.t_material, m.vigente,
                       m.formacion AS materia_id, m.fecha_trans AS created_at
                FROM material_materia m
                WHERE m.url IS NOT NULL AND m.url != ''
                ORDER BY m.id
                """
            )
            df_mat["resource_type"]   = df_mat["t_material"].map(self.t_material_ser).map(map_material_type).fillna("DOCUMENT")
            df_mat["resource_status"] = df_mat["vigente"].fillna(0).astype(bool).map({True: "ACTIVE", False: "INACTIVE"})
            df_mat["resource_scope"]  = "COURSE"
            df_mat["course_id"]       = df_mat["materia_id"].map(self.course_map)
            df_mat["name"]            = df_mat["titulo"].where(df_mat["titulo"].notna(), df_mat["url"])
            df_mat["uuid"]            = [det_uuid("media_mat", str(x)) for x in df_mat["id"].values]
            df_mat["created_at"]      = pd.to_datetime(df_mat["created_at"]).fillna(NOW)
            df_mat["updated_at"]      = NOW

            # ── Videos de clase (url_video)
            df_vid = self._rq(
                """
                SELECT c.id AS clase_id, c.grupo, c.url_video AS url,
                       c.fecha_inicio AS created_at
                FROM clase c
                WHERE c.url_video IS NOT NULL AND c.url_video != ''
                ORDER BY c.id
                """
            )
            # Descartar URLs ya cubiertas por material_materia
            known_urls = set(df_mat["url"].dropna())
            df_vid = df_vid[~df_vid["url"].isin(known_urls)].drop_duplicates(subset=["url"])

            grupo_materia = self._rq("SELECT id, materia FROM grupo WHERE materia IS NOT NULL")
            df_vid = df_vid.merge(
                grupo_materia.rename(columns={"id": "grupo", "materia": "materia_id"}),
                on="grupo", how="left"
            )
            df_vid["course_id"]       = df_vid["materia_id"].map(self.course_map)
            df_vid["name"]            = "Video — sesión " + df_vid["clase_id"].astype(str)
            df_vid["resource_type"]   = "VIDEO"
            df_vid["resource_status"] = "ACTIVE"
            df_vid["resource_scope"]  = "SESSION"
            df_vid["uuid"]            = [det_uuid("media_video", str(x)) for x in df_vid["clase_id"].values]
            df_vid["created_at"]      = pd.to_datetime(df_vid["created_at"]).fillna(NOW)
            df_vid["updated_at"]      = NOW

            # Unificar ambas fuentes
            shared_cols = ["uuid", "name", "url", "resource_type", "resource_status",
                           "resource_scope", "course_id", "created_at", "updated_at"]
            df_all = pd.concat([df_mat[shared_cols], df_vid[shared_cols]], ignore_index=True)

            # Descartar registros sin course_id (grupo sin materia o materia no migrada)
            before = len(df_all)
            df_all = df_all.dropna(subset=["course_id"])
            dropped = before - len(df_all)
            if dropped:
                logger.warning(f"  Omitidos {dropped} recursos sin course_id mapeado")

            # Deduplicar por uuid antes de insertar (mismo video puede aparecer en df_mat y df_vid)
            df_all = df_all.drop_duplicates(subset=["uuid"])
            df_all["course_id"] = df_all["course_id"].astype(int)
            rows = to_records(df_all)
            returned = self._bulk_write_returning(
                """
                INSERT INTO course_media_resources
                    (uuid, name, url, resource_type, resource_status,
                     resource_scope, course_id, created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO UPDATE SET url = EXCLUDED.url
                RETURNING id, uuid
                """,
                rows,
            )
            self.pg_conn.commit()

            uuid_pgid = {str(r[1]): r[0] for r in returned}
            self.media_url_map = {
                url: uuid_pgid[uid]
                for uid, url in zip(df_all["uuid"], df_all["url"])
                if uid in uuid_pgid
            }

            self._log_step(
                "course_media_resources", len(uuid_pgid),
                len(df_mat) + len(df_vid)
            )
            logger.info(f"  Detalle: {len(df_mat)} materiales + {len(df_vid)} videos de clase")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ course_media_resources: {err}")
            traceback.print_exc()
            self.stats["errors"].append(f"course_media_resources: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 11. group_session_videos  ←  clase.url_video
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_group_session_videos(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: group_session_videos  ←  clase.url_video")
        try:
            df = self._rq(
                """
                SELECT id AS clase_id, url_video AS url,
                       fecha_asistencia, fecha_inicio
                FROM clase
                WHERE url_video IS NOT NULL AND url_video != ''
                ORDER BY id
                """
            )

            df["group_session_id"]  = df["clase_id"].map(self.session_map)
            df["media_resource_id"] = df["url"].map(self.media_url_map)
            before = len(df)
            df = df.dropna(subset=["group_session_id", "media_resource_id"])
            skipped = before - len(df)

            df["released_at"] = pd.to_datetime(
                df["fecha_asistencia"].where(df["fecha_asistencia"].notna(), df["fecha_inicio"])
            ).fillna(pd.NaT)
            df["uuid"] = [
                det_uuid("session_video", f"{a}_{b[:64]}")
                for a, b in zip(df["clase_id"].values, df["url"].values)
            ]
            df["group_session_id"]  = df["group_session_id"].astype(int)
            df["media_resource_id"] = df["media_resource_id"].astype(int)
            df["created_at"]        = NOW
            df["updated_at"]        = NOW

            rows = to_records(df[["uuid", "group_session_id", "media_resource_id",
                                   "released_at", "created_at", "updated_at"]])
            self._bulk_write(
                """
                INSERT INTO group_session_videos
                    (uuid, group_session_id, media_resource_id,
                     released_at, created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO NOTHING
                """,
                rows,
            )
            self.pg_conn.commit()
            self._log_step("group_session_videos", len(rows), before)
            if skipped:
                logger.warning(f"  Omitidos sin sesión o recurso mapeado: {skipped}")
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ group_session_videos: {err}")
            self.stats["errors"].append(f"group_session_videos: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # 12. course_group_media_resources  (tabla pivote)
    # merge pandas en lugar de loops anidados
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_course_group_media_resources(self) -> bool:
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: course_group_media_resources  (pivote grupos ↔ materiales)")
        try:
            df_mat = self._rq(
                "SELECT url, formacion AS materia_id FROM material_materia"
                " WHERE url IS NOT NULL AND url != ''"
            )
            df_grp = self._rq(
                "SELECT id AS erp_grupo, materia FROM grupo WHERE materia IS NOT NULL"
            )

            # Merge: material → materia → grupos
            df = df_mat.merge(
                df_grp.rename(columns={"materia": "materia_id"}),
                on="materia_id", how="inner"
            )

            df["media_resource_id"] = df["url"].map(self.media_url_map)
            df["course_group_id"]   = df["erp_grupo"].map(self.group_map)
            df = df.dropna(subset=["media_resource_id", "course_group_id"])

            # Deduplicar el producto cruzado
            df = df.drop_duplicates(subset=["course_group_id", "media_resource_id"])

            df["course_group_id"]   = df["course_group_id"].astype(int)
            df["media_resource_id"] = df["media_resource_id"].astype(int)
            df["uuid"] = [
                det_uuid("cgmr", f"{a}_{b}")
                for a, b in zip(df["course_group_id"].values, df["media_resource_id"].values)
            ]
            df["released_at"]       = None
            df["created_at"]        = NOW
            df["updated_at"]        = NOW

            rows = to_records(df[["uuid", "course_group_id", "media_resource_id",
                                   "released_at", "created_at", "updated_at"]])
            self._bulk_write(
                """
                INSERT INTO course_group_media_resources
                    (uuid, course_group_id, media_resource_id,
                     released_at, created_at, updated_at)
                VALUES %s
                ON CONFLICT (uuid) DO NOTHING
                """,
                rows,
            )
            self.pg_conn.commit()
            self._log_step("course_group_media_resources", len(rows), len(rows))
            return True

        except Exception as err:
            self.pg_conn.rollback()
            logger.error(f"✗ course_group_media_resources: {err}")
            self.stats["errors"].append(f"course_group_media_resources: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # Orquestación
    # ──────────────────────────────────────────────────────────────────────────

    def execute_migration(self) -> bool:
        try:
            if not self.connect():
                return False

            logger.info("\n" + "█" * 60)
            logger.info("MIGRACIÓN ACADÉMICA ERP → ALMA_BE_V2".center(60))
            logger.info("█" * 60)
            logger.info(f"  pandas {pd.__version__}  |  numpy {np.__version__}")
            if self.limit:
                logger.info(f"  Modo prueba: LIMIT {self.limit} en course_groups")

            logger.info("\nCargando tablas de referencia ERP...")
            self._load_lookup_tables()

            logger.info("\nReconstruyendo profile_map desde PostgreSQL...")
            self._rebuild_profile_map()

            steps = [
                ("institutes",                   self.migrate_institute),
                ("campuses",                     self.migrate_campuses),
                ("campus_spaces",                self.migrate_campus_spaces),
                ("program_courses",              self.migrate_program_courses),
                ("course_requirements",          self.migrate_course_requirements),
                ("course_groups",                self.migrate_course_groups),
                ("group_sessions",               self.migrate_group_sessions),
                ("group_profiles",               self.migrate_group_profiles),
                ("group_profile_assistance",     self.migrate_group_profile_assistance),
                ("course_media_resources",       self.migrate_course_media_resources),
                ("group_session_videos",         self.migrate_group_session_videos),
                ("course_group_media_resources", self.migrate_course_group_media_resources),
            ]

            for name, step in steps:
                try:
                    step()
                except Exception as err:
                    logger.error(f"  Paso {name} fallido: {err}")
                    self.stats["errors"].append(f"{name}: {err}")

            elapsed = (datetime.now() - self.stats["start_time"]).total_seconds()
            logger.info("\n" + "█" * 60)
            logger.info("RESUMEN MIGRACIÓN ACADÉMICA".center(60))
            logger.info("█" * 60)
            logger.info(f"  Duración    : {elapsed:.1f}s")
            logger.info(f"  Tablas      : {self.stats['migrated_tables']}/{len(steps)}")
            logger.info(
                f"  Registros   : {self.stats['migrated_records']}"
                f" / {self.stats['total_records']}"
            )
            logger.info(f"  Errores     : {len(self.stats['errors'])}")
            for e in self.stats["errors"][:10]:
                logger.warning(f"  - {e}")
            logger.info("█" * 60 + "\n")
            return len(self.stats["errors"]) == 0

        except Exception as err:
            logger.error(f"Error fatal: {err}")
            traceback.print_exc()
            return False
        finally:
            self.disconnect()


# ──────────────────────────────────────────────────────────────────────────────
# Entrada
# ──────────────────────────────────────────────────────────────────────────────

def _env_complete() -> bool:
    """Devuelve True si el .env tiene todas las variables requeridas."""
    required = ["DB_HOST", "DB_USER", "DB_PASSWORD", "DB_NAME",
                "PG_HOST", "PG_USER", "PG_PASSWORD", "PG_NAME"]
    return all(os.getenv(k, "").strip() for k in required)


def _config_from_env() -> Dict:
    return {
        "mariadb": {
            "host":     os.getenv("DB_HOST", "localhost"),
            "port":     int(os.getenv("DB_PORT", "3306")),
            "user":     os.getenv("DB_USER", "root"),
            "password": os.getenv("DB_PASSWORD", ""),
            "database": os.getenv("DB_NAME", "erp"),
        },
        "postgres": {
            "host":     os.getenv("PG_HOST", "localhost"),
            "port":     int(os.getenv("PG_PORT", "5432")),
            "user":     os.getenv("PG_USER", "postgres"),
            "password": os.getenv("PG_PASSWORD", ""),
            "database": os.getenv("PG_NAME", "almadb"),
        },
        "institute_name":    os.getenv("INSTITUTE_NAME", "Corporación La Comunidad"),
        "institute_acronym": os.getenv("INSTITUTE_ACRONYM", "CLC"),
    }


def main():
    print("\n" + "=" * 70)
    print("MIGRACIÓN ACADÉMICA ERP (MariaDB) → ALMA_BE_V2 (PostgreSQL)".center(70))
    print("=" * 70)
    print("\n  PREREQUISITO: migration_mariadb.py debe haberse ejecutado primero.")

    if _ENV_PATH.exists() and _env_complete():
        cfg = _config_from_env()
        mc, pc = cfg["mariadb"], cfg["postgres"]
        print(f"\n  .env cargado desde: {_ENV_PATH}")
        print(f"\n  MariaDB   : {mc['user']}@{mc['host']}:{mc['port']}/{mc['database']}")
        print(f"  PostgreSQL: {pc['user']}@{pc['host']}:{pc['port']}/{pc['database']}")
        print(f"  Instituto : {cfg['institute_name']} ({cfg['institute_acronym']})")

        raw_limit = input("\n  Límite de grupos a migrar [vacío = todos]: ").strip()
        limit: Optional[int] = None
        if raw_limit:
            try:
                limit = int(raw_limit) or None
            except ValueError:
                pass

        migrator = AcademicMigrator(
            mariadb_config=mc,
            postgres_config=pc,
            institute_name=cfg["institute_name"],
            institute_acronym=cfg["institute_acronym"],
            limit=limit,
        )
    else:
        if _ENV_PATH.exists():
            print(f"\n  .env incompleto — se solicitarán los datos manualmente.")
        else:
            print(f"\n  .env no encontrado en {_ENV_PATH} — ingresa los datos manualmente.")

        print("\nMariaDB (ERP):")
        mariadb_host = input("  Host     [localhost]: ").strip() or "localhost"
        mariadb_port = int(input("  Puerto   [3306]:      ").strip() or "3306")
        mariadb_user = input("  Usuario  [root]:      ").strip() or "root"
        mariadb_pass = input("  Password:             ").strip()
        mariadb_db   = input("  Base     [erp]:       ").strip() or "erp"

        print("\nPostgreSQL (almadb):")
        pg_host = input("  Host     [localhost]: ").strip() or "localhost"
        pg_port = int(input("  Puerto   [5432]:      ").strip() or "5432")
        pg_user = input("  Usuario  [postgres]:  ").strip() or "postgres"
        pg_pass = input("  Password:             ").strip()
        pg_db   = input("  Base     [almadb]:    ").strip() or "almadb"

        print("\nInstituto (se crea si no existe):")
        institute_name    = input("  Nombre [Corporación La Comunidad]: ").strip() or "Corporación La Comunidad"
        institute_acronym = input("  Sigla  [CLC]: ").strip() or "CLC"

        raw_limit = input("\n  Límite de grupos a migrar [vacío = todos]: ").strip()
        limit: Optional[int] = None
        if raw_limit:
            try:
                limit = int(raw_limit) or None
            except ValueError:
                pass

        migrator = AcademicMigrator(
            mariadb_config={
                "host": mariadb_host, "port": mariadb_port,
                "user": mariadb_user, "password": mariadb_pass,
                "database": mariadb_db,
            },
            postgres_config={
                "host": pg_host, "port": pg_port,
                "user": pg_user, "password": pg_pass,
                "database": pg_db,
            },
            institute_name=institute_name,
            institute_acronym=institute_acronym,
            limit=limit,
        )

    sys.exit(0 if migrator.execute_migration() else 1)


if __name__ == "__main__":
    main()
