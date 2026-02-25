#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Migración ERP (MariaDB) → ALMA_BE_V2 (PostgreSQL)
Tablas cubiertas: roles, users, user_roles, profiles,
                  profile_dni, profile_addresses, profile_employment, profile_family
"""

import sys
import io
import uuid
import traceback
import logging
from datetime import datetime
from typing import Dict, Tuple, Optional

import mysql.connector
from mysql.connector import Error as MySQLError
import psycopg2
from psycopg2.extras import execute_values

# Forzar UTF-8 en consola Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)-8s] %(message)s",
    handlers=[
        logging.FileHandler("migration_mariadb.log", encoding="utf-8"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger(__name__)

NOW = datetime.now()


def det_uuid(namespace: str, key: str) -> str:
    """UUID determinista: misma entrada → mismo UUID en cada ejecución."""
    return str(uuid.uuid5(uuid.NAMESPACE_OID, f"{namespace}:{key}"))


class MariaDBMigrator:
    def __init__(
        self,
        mariadb_config: Dict,
        postgres_config: Dict,
        limit: Optional[int] = None,
    ):
        self.mariadb_config = mariadb_config
        self.postgres_config = postgres_config
        self.limit = limit          # None = todos los registros | int = cantidad máxima
        self.mariadb_conn = None
        self.postgres_conn = None

        # ── Mapas ERP-ID → PostgreSQL-ID (construidos durante la migración)
        self.role_id_map: Dict[int, int] = {}
        # {erp_roles.id → pg_roles.id}

        self.erp_auth_user_map: Dict[int, int] = {}
        # {erp_users.id → pg_users.id}  (para mapear model_has_roles)

        self.usuario_id_map: Dict[Tuple[int, int], int] = {}
        # {(erp_usuario.id, erp_usuario.dni) → pg_users.id}

        self.profile_id_map: Dict[Tuple[int, int], int] = {}
        # {(erp_usuario.id, erp_usuario.dni) → pg_profiles.id}

        # ── Tablas de referencia ERP (IDs → nombres legibles)
        self.pais_map: Dict[int, str] = {}
        self.provincia_map: Dict[int, str] = {}
        self.t_dni_map: Dict[int, str] = {}       # id → abreviacion (CC, CE, ...)
        self.t_est_civil_map: Dict[int, str] = {}  # id → tipo
        self.t_ocupacion_map: Dict[int, str] = {}  # id → tipo

        self.stats = {
            "migrated_tables": 0,
            "total_records": 0,
            "migrated_records": 0,
            "errors": [],
            "start_time": datetime.now(),
        }

    # ──────────────────────────────────────────────────────────────────────────
    # Conexiones
    def _limit_sql(self) -> str:
        """Devuelve cláusula LIMIT si se configuró un máximo, o cadena vacía."""
        return f"LIMIT {self.limit}" if self.limit is not None else ""

    # ──────────────────────────────────────────────────────────────────────────

    def connect(self) -> bool:
        try:
            logger.info("Conectando a MariaDB...")
            self.mariadb_conn = mysql.connector.connect(
                **self.mariadb_config,
                autocommit=True,
                use_pure=True,
                get_warnings=True,
            )
            cur = self.mariadb_conn.cursor()
            cur.execute("SELECT VERSION()")
            version = cur.fetchone()[0]
            cur.close()
            logger.info(f"✓ MariaDB {version}")
        except MySQLError as err:
            logger.error(f"✗ MariaDB: {err}")
            return False

        try:
            logger.info("Conectando a PostgreSQL...")
            self.postgres_conn = psycopg2.connect(**self.postgres_config)
            self.postgres_conn.autocommit = False
            cur = self.postgres_conn.cursor()
            cur.execute("SELECT version()")
            cur.fetchone()
            cur.close()
            logger.info("✓ PostgreSQL OK")
        except psycopg2.Error as err:
            logger.error(f"✗ PostgreSQL: {err}")
            return False

        return True

    def disconnect(self):
        if self.mariadb_conn:
            self.mariadb_conn.close()
        if self.postgres_conn:
            self.postgres_conn.close()

    # ──────────────────────────────────────────────────────────────────────────
    # Tablas de referencia
    # ──────────────────────────────────────────────────────────────────────────

    def _load_lookup_tables(self):
        """Carga tablas pequeñas del ERP para convertir IDs a nombres."""
        cur = self.mariadb_conn.cursor()

        for table, attr, key_col, val_col in [
            ("pais",        "pais_map",        "id", "nombre"),
            ("provincia",   "provincia_map",   "id", "nombre"),
            ("t_est_civil", "t_est_civil_map", "id", "tipo"),
            ("t_ocupacion", "t_ocupacion_map", "id", "tipo"),
        ]:
            try:
                cur.execute(f"SELECT {key_col}, {val_col} FROM {table}")
                setattr(self, attr, {row[0]: row[1] for row in cur.fetchall()})
                logger.info(f"  lookup {table}: {len(getattr(self, attr))} filas")
            except MySQLError as err:
                logger.warning(f"  No se pudo cargar {table}: {err}")

        # t_dni usa la abreviacion (CC, CE, PP, …) como tipo legible
        try:
            cur.execute("SELECT id, abreviacion FROM t_dni")
            self.t_dni_map = {row[0]: row[1] for row in cur.fetchall()}
            logger.info(f"  lookup t_dni: {len(self.t_dni_map)} filas")
        except MySQLError as err:
            logger.warning(f"  No se pudo cargar t_dni: {err}")

        cur.close()

    # ──────────────────────────────────────────────────────────────────────────
    # Helpers
    # ──────────────────────────────────────────────────────────────────────────

    def _insert_one_with_savepoint(self, pg_cur, sql: str, params: tuple) -> Optional[int]:
        """
        Inserta una fila usando un SAVEPOINT para aislar errores de constraint.
        Devuelve el id generado o None si hubo conflicto.
        """
        pg_cur.execute("SAVEPOINT sp_row")
        try:
            pg_cur.execute(sql, params)
            row = pg_cur.fetchone()
            pg_cur.execute("RELEASE SAVEPOINT sp_row")
            return row[0] if row else None
        except psycopg2.IntegrityError:
            pg_cur.execute("ROLLBACK TO SAVEPOINT sp_row")
            pg_cur.execute("RELEASE SAVEPOINT sp_row")
            return None

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_roles
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_roles(self) -> bool:
        """
        ERP roles → ALMA roles
        Problema corregido: UUID determinista + mapa role_id_map para FK posteriores.
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: roles")
        try:
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                "SELECT id, name, guard_name, created_at, updated_at FROM roles"
            )
            rows = cur.fetchall()
            cur.close()

            if not rows:
                logger.warning("Sin roles en ERP")
                return True

            pg_cur = self.postgres_conn.cursor()
            migrated = 0

            for r in rows:
                role_uuid = det_uuid("role", str(r["id"]))
                pg_id = self._insert_one_with_savepoint(
                    pg_cur,
                    """
                    INSERT INTO roles
                        (uuid, name, description, "default", created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (uuid) DO UPDATE
                        SET name = EXCLUDED.name
                    RETURNING id
                    """,
                    (
                        role_uuid,
                        r["name"],
                        r.get("guard_name") or "",
                        False,
                        r["created_at"] or NOW,
                        r["updated_at"] or NOW,
                    ),
                )
                if pg_id:
                    self.role_id_map[r["id"]] = pg_id
                    migrated += 1

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += migrated
            self.stats["total_records"] += len(rows)
            logger.info(f"✓ {migrated}/{len(rows)} roles")
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ roles: {err}")
            self.stats["errors"].append(f"roles: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_users
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_users(self) -> bool:
        """
        ERP usuario → ALMA users  (personas: fuente para profiles)
        ERP users   → ALMA users  (usuarios auth: fuente para user_roles vía model_has_roles)

        Problemas corregidos:
         - Fuente principal de personas es `usuario`, no `users`
         - UUIDs deterministas
         - Se construyen usuario_id_map y erp_auth_user_map para FK posteriores
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: users")
        try:
            pg_cur = self.postgres_conn.cursor()

            # ── 1. Tabla `usuario` (personas reales del ERP)
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                f"""
                SELECT id, dni, email, vigente,
                       email_verified_at, created_at, updated_at
                FROM usuario
                ORDER BY id, dni
                {self._limit_sql()}
                """
            )
            usuarios = cur.fetchall()
            cur.close()

            rows_usuario = []
            key_to_provider: Dict[Tuple[int, int], str] = {}

            for u in usuarios:
                provider_id = f"erp_usuario_{u['id']}_{u['dni']}"
                email = u["email"] or f"{provider_id}@noemail.local"
                status = "ACTIVE" if u.get("vigente", 1) else "INACTIVE"
                u_uuid = det_uuid("usuario", f"{u['id']}_{u['dni']}")

                rows_usuario.append((
                    u_uuid,
                    provider_id,
                    email,
                    status,
                    bool(u.get("email_verified_at")),
                    u["created_at"] or NOW,
                    u["updated_at"] or NOW,
                ))
                key_to_provider[(u["id"], u["dni"])] = provider_id

            if rows_usuario:
                execute_values(
                    pg_cur,
                    """
                    INSERT INTO users
                        (uuid, provider_auth_id, email, status,
                         is_email_verified, created_at, updated_at)
                    VALUES %s
                    ON CONFLICT (provider_auth_id) DO NOTHING
                    """,
                    rows_usuario,
                )
                # Reconstruir mapa (id, dni) → pg_users.id usando provider_auth_id
                provider_ids = list(key_to_provider.values())
                pg_cur.execute(
                    "SELECT id, provider_auth_id FROM users"
                    " WHERE provider_auth_id = ANY(%s)",
                    (provider_ids,),
                )
                provider_to_pg = {row[1]: row[0] for row in pg_cur.fetchall()}
                for key, provider_id in key_to_provider.items():
                    if provider_id in provider_to_pg:
                        self.usuario_id_map[key] = provider_to_pg[provider_id]

            # ── 2. Tabla `users` del ERP (auth Laravel → para user_roles)
            cur2 = self.mariadb_conn.cursor(dictionary=True)
            cur2.execute(
                "SELECT id, email, name, email_verified_at, created_at, updated_at"
                " FROM users"
            )
            auth_users = cur2.fetchall()
            cur2.close()

            rows_auth = []
            auth_key_to_provider: Dict[int, str] = {}

            for u in auth_users:
                provider_id = f"erp_auth_{u['id']}"
                email = u["email"] or f"{provider_id}@noemail.local"
                u_uuid = det_uuid("auth_user", str(u["id"]))

                rows_auth.append((
                    u_uuid,
                    provider_id,
                    email,
                    "ACTIVE",
                    bool(u.get("email_verified_at")),
                    u["created_at"] or NOW,
                    u["updated_at"] or NOW,
                ))
                auth_key_to_provider[u["id"]] = provider_id

            if rows_auth:
                execute_values(
                    pg_cur,
                    """
                    INSERT INTO users
                        (uuid, provider_auth_id, email, status,
                         is_email_verified, created_at, updated_at)
                    VALUES %s
                    ON CONFLICT (provider_auth_id) DO NOTHING
                    """,
                    rows_auth,
                )
                provider_ids = list(auth_key_to_provider.values())
                pg_cur.execute(
                    "SELECT id, provider_auth_id FROM users"
                    " WHERE provider_auth_id = ANY(%s)",
                    (provider_ids,),
                )
                provider_to_pg = {row[1]: row[0] for row in pg_cur.fetchall()}
                for erp_id, provider_id in auth_key_to_provider.items():
                    if provider_id in provider_to_pg:
                        self.erp_auth_user_map[erp_id] = provider_to_pg[provider_id]

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += len(rows_usuario) + len(rows_auth)
            self.stats["total_records"] += len(usuarios) + len(auth_users)
            logger.info(
                f"✓ {len(self.usuario_id_map)} personas"
                f" | {len(self.erp_auth_user_map)} auth users"
            )
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ users: {err}")
            traceback.print_exc()
            self.stats["errors"].append(f"users: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_user_roles
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_user_roles(self) -> bool:
        """
        ERP model_has_roles → ALMA user_roles

        Problema corregido: se usan role_id_map y erp_auth_user_map para
        traducir IDs del ERP a IDs reales de PostgreSQL antes de insertar.
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: user_roles")
        try:
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                """
                SELECT role_id, model_id
                FROM model_has_roles
                WHERE model_type = 'App\\\\Models\\\\User'
                """
            )
            rows = cur.fetchall()
            cur.close()

            if not rows:
                logger.warning("Sin registros en model_has_roles")
                return True

            pg_cur = self.postgres_conn.cursor()
            to_insert = []
            skipped = 0

            for r in rows:
                pg_role_id = self.role_id_map.get(r["role_id"])
                pg_user_id = self.erp_auth_user_map.get(r["model_id"])

                if pg_role_id is None or pg_user_id is None:
                    skipped += 1
                    continue

                to_insert.append((pg_user_id, pg_role_id, NOW))

            if to_insert:
                execute_values(
                    pg_cur,
                    """
                    INSERT INTO user_roles (user_id, role_id, created_at)
                    VALUES %s
                    ON CONFLICT (user_id, role_id) DO NOTHING
                    """,
                    to_insert,
                )

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += len(to_insert)
            self.stats["total_records"] += len(rows)
            logger.info(
                f"✓ {len(to_insert)}/{len(rows)} user_roles"
                f" (omitidos sin mapeo: {skipped})"
            )
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ user_roles: {err}")
            self.stats["errors"].append(f"user_roles: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_profiles
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_profiles(self) -> bool:
        """
        ERP usuario → ALMA profiles
        Construye profile_id_map para las tablas profile_* dependientes.

        Columnas ERP → ALMA:
          usuario.id        → profiles.dni  (el id del usuario ES el nro de documento)
          usuario.nombre1   → first_name
          usuario.nombre2   → middle_name
          usuario.apellido1 → last_name
          usuario.apellido2 → second_last_name
          usuario.genero    → gender
          usuario.fecha_nacimiento → birth_date
          usuario.telefono  → phone
          usuario.celular   → mobile
          usuario.imagen    → avatar_url
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: profiles")
        try:
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                f"""
                SELECT id, dni, nombre1, nombre2, apellido1, apellido2,
                       genero, fecha_nacimiento, telefono, celular, imagen,
                       created_at, updated_at
                FROM usuario
                ORDER BY id, dni
                {self._limit_sql()}
                """
            )
            rows = cur.fetchall()
            cur.close()

            pg_cur = self.postgres_conn.cursor()
            migrated = 0
            skipped = 0

            for u in rows:
                key = (u["id"], u["dni"])
                pg_user_id = self.usuario_id_map.get(key)
                if pg_user_id is None:
                    skipped += 1
                    continue

                profile_uuid = det_uuid("profile", f"{u['id']}_{u['dni']}")

                pg_id = self._insert_one_with_savepoint(
                    pg_cur,
                    """
                    INSERT INTO profiles
                        (uuid, user_id, dni, first_name, middle_name,
                         last_name, second_last_name, gender, birth_date,
                         phone, mobile, avatar_url, created_at, updated_at)
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    ON CONFLICT (uuid) DO NOTHING
                    RETURNING id
                    """,
                    (
                        profile_uuid,
                        pg_user_id,
                        str(u["id"]),         # nro de documento
                        u["nombre1"],
                        u.get("nombre2"),
                        u["apellido1"],
                        u.get("apellido2"),
                        u.get("genero"),
                        u.get("fecha_nacimiento"),
                        u.get("telefono"),
                        u.get("celular"),
                        u.get("imagen"),
                        u["created_at"] or NOW,
                        u["updated_at"] or NOW,
                    ),
                )
                if pg_id:
                    self.profile_id_map[key] = pg_id
                    migrated += 1

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += migrated
            self.stats["total_records"] += len(rows)
            logger.info(f"✓ {migrated}/{len(rows)} profiles (omitidos: {skipped})")
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ profiles: {err}")
            traceback.print_exc()
            self.stats["errors"].append(f"profiles: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_profile_addresses
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_profile_addresses(self) -> bool:
        """
        ERP usuario → ALMA profile_addresses

        Columnas ERP → ALMA:
          pais.nombre   → country   (join con tabla pais)
          provincia.nombre → state  (join con tabla provincia)
          usuario.ciudad   → city
          usuario.direccion → address_line
          usuario.barrio   → neighborhood
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: profile_addresses")
        try:
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                """
                SELECT id, dni, pais, provincia, ciudad, direccion, barrio,
                       created_at, updated_at
                FROM usuario
                WHERE pais IS NOT NULL
                   OR ciudad IS NOT NULL
                   OR direccion IS NOT NULL
                """
            )
            rows = cur.fetchall()
            cur.close()

            pg_cur = self.postgres_conn.cursor()
            to_insert = []

            for u in rows:
                key = (u["id"], u["dni"])
                pg_profile_id = self.profile_id_map.get(key)
                if pg_profile_id is None:
                    continue

                to_insert.append((
                    det_uuid("address", f"{u['id']}_{u['dni']}"),
                    pg_profile_id,
                    self.pais_map.get(u["pais"]) if u["pais"] else None,
                    self.provincia_map.get(u["provincia"]) if u["provincia"] else None,
                    u.get("ciudad"),
                    "HOME",
                    True,
                    u.get("direccion"),
                    u.get("barrio"),
                    u["created_at"] or NOW,
                    u["updated_at"] or NOW,
                ))

            if to_insert:
                execute_values(
                    pg_cur,
                    """
                    INSERT INTO profile_addresses
                        (uuid, profile_id, country, state, city,
                         "adressType", is_primary, address_line, neighborhood,
                         created_at, updated_at)
                    VALUES %s
                    ON CONFLICT (uuid) DO NOTHING
                    """,
                    to_insert,
                )

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += len(to_insert)
            self.stats["total_records"] += len(rows)
            logger.info(f"✓ {len(to_insert)}/{len(rows)} profile_addresses")
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ profile_addresses: {err}")
            self.stats["errors"].append(f"profile_addresses: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_profile_employment
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_profile_employment(self) -> bool:
        """
        ERP usuario → ALMA profile_employment

        Columnas ERP → ALMA:
          t_ocupacion.tipo   → occupation  (join con t_ocupacion)
          usuario.empresa    → company_name
          usuario.telefono_empresa → company_phone
          usuario.fecha_ingreso_empresa → start_date
          end_date → NULL (no disponible en ERP)
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: profile_employment")
        try:
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                """
                SELECT id, dni, ocupacion, empresa, telefono_empresa,
                       fecha_ingreso_empresa, created_at, updated_at
                FROM usuario
                WHERE empresa IS NOT NULL OR ocupacion IS NOT NULL
                """
            )
            rows = cur.fetchall()
            cur.close()

            pg_cur = self.postgres_conn.cursor()
            to_insert = []

            for u in rows:
                key = (u["id"], u["dni"])
                pg_profile_id = self.profile_id_map.get(key)
                if pg_profile_id is None:
                    continue

                occupation = (
                    self.t_ocupacion_map.get(u["ocupacion"])
                    if u["ocupacion"] else None
                )
                to_insert.append((
                    det_uuid("employment", f"{u['id']}_{u['dni']}"),
                    pg_profile_id,
                    occupation,
                    u.get("empresa"),
                    u.get("telefono_empresa"),
                    u.get("fecha_ingreso_empresa"),
                    None,   # end_date: no disponible en ERP
                    u["created_at"] or NOW,
                    u["updated_at"] or NOW,
                ))

            if to_insert:
                execute_values(
                    pg_cur,
                    """
                    INSERT INTO profile_employment
                        (uuid, profile_id, occupation, company_name, company_phone,
                         start_date, end_date, created_at, updated_at)
                    VALUES %s
                    ON CONFLICT (uuid) DO NOTHING
                    """,
                    to_insert,
                )

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += len(to_insert)
            self.stats["total_records"] += len(rows)
            logger.info(f"✓ {len(to_insert)}/{len(rows)} profile_employment")
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ profile_employment: {err}")
            self.stats["errors"].append(f"profile_employment: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_profile_family
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_profile_family(self) -> bool:
        """
        ERP usuario → ALMA profile_family

        Columnas ERP → ALMA:
          t_est_civil.tipo  → marital_status  (join con t_est_civil)
          usuario.cant_hijos → children_count
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: profile_family")
        try:
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                """
                SELECT id, dni, est_civil, cant_hijos, created_at, updated_at
                FROM usuario
                WHERE est_civil IS NOT NULL OR cant_hijos IS NOT NULL
                """
            )
            rows = cur.fetchall()
            cur.close()

            pg_cur = self.postgres_conn.cursor()
            to_insert = []

            for u in rows:
                key = (u["id"], u["dni"])
                pg_profile_id = self.profile_id_map.get(key)
                if pg_profile_id is None:
                    continue

                marital_status = (
                    self.t_est_civil_map.get(u["est_civil"])
                    if u["est_civil"] else None
                )
                to_insert.append((
                    det_uuid("family", f"{u['id']}_{u['dni']}"),
                    pg_profile_id,
                    marital_status,
                    u.get("cant_hijos"),
                    u["created_at"] or NOW,
                    u["updated_at"] or NOW,
                ))

            if to_insert:
                execute_values(
                    pg_cur,
                    """
                    INSERT INTO profile_family
                        (uuid, profile_id, marital_status, children_count,
                         created_at, updated_at)
                    VALUES %s
                    ON CONFLICT (profile_id) DO NOTHING
                    """,
                    to_insert,
                )

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += len(to_insert)
            self.stats["total_records"] += len(rows)
            logger.info(f"✓ {len(to_insert)}/{len(rows)} profile_family")
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ profile_family: {err}")
            self.stats["errors"].append(f"profile_family: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # migrate_profile_dni
    # ──────────────────────────────────────────────────────────────────────────

    def migrate_profile_dni(self) -> bool:
        """
        ERP usuario → ALMA profile_dni

        Columnas ERP → ALMA:
          usuario.id            → (el número de documento está en usuario.id)
          t_dni.abreviacion     → "dniType"  (CC, CE, PP, …)
          usuario.fecha_nacimiento → birthdate
          expedition_date → NULL (no disponible en ERP)
          is_current → True
        """
        logger.info("\n" + "=" * 60)
        logger.info("MIGRANDO: profile_dni")
        try:
            cur = self.mariadb_conn.cursor(dictionary=True)
            cur.execute(
                "SELECT id, dni, fecha_nacimiento, created_at, updated_at FROM usuario"
            )
            rows = cur.fetchall()
            cur.close()

            pg_cur = self.postgres_conn.cursor()
            to_insert = []

            for u in rows:
                key = (u["id"], u["dni"])
                pg_profile_id = self.profile_id_map.get(key)
                if pg_profile_id is None:
                    continue

                # Tipo de documento: usar abreviacion si existe, si no el ID como string
                dni_type = self.t_dni_map.get(u["dni"], str(u["dni"]))

                to_insert.append((
                    det_uuid("profile_dni", f"{u['id']}_{u['dni']}"),
                    pg_profile_id,
                    dni_type,
                    None,                       # expedition_date: no disponible
                    u.get("fecha_nacimiento"),  # birthdate
                    True,                       # is_current
                    u["created_at"] or NOW,
                    u["updated_at"] or NOW,
                ))

            if to_insert:
                execute_values(
                    pg_cur,
                    """
                    INSERT INTO profile_dni
                        (uuid, profile_id, "dniType", expedition_date,
                         birthdate, is_current, created_at, updated_at)
                    VALUES %s
                    ON CONFLICT (uuid) DO NOTHING
                    """,
                    to_insert,
                )

            self.postgres_conn.commit()
            pg_cur.close()

            self.stats["migrated_tables"] += 1
            self.stats["migrated_records"] += len(to_insert)
            self.stats["total_records"] += len(rows)
            logger.info(f"✓ {len(to_insert)}/{len(rows)} profile_dni")
            return True

        except Exception as err:
            self.postgres_conn.rollback()
            logger.error(f"✗ profile_dni: {err}")
            self.stats["errors"].append(f"profile_dni: {err}")
            return False

    # ──────────────────────────────────────────────────────────────────────────
    # Orquestación
    # ──────────────────────────────────────────────────────────────────────────

    def execute_migration(self) -> bool:
        try:
            if not self.connect():
                return False

            logger.info("\n" + "█" * 60)
            logger.info("INICIANDO MIGRACIÓN ERP → ALMA_BE_V2".center(60))
            logger.info("█" * 60)

            modo = f"primeros {self.limit} registros" if self.limit else "todos los registros"
            logger.info(f"  Modo: {modo}")
            logger.info("\nCargando tablas de referencia...")
            self._load_lookup_tables()

            # Orden estricto: respetar dependencias FK
            steps = [
                self.migrate_roles,
                self.migrate_users,
                self.migrate_user_roles,
                self.migrate_profiles,
                self.migrate_profile_addresses,
                self.migrate_profile_employment,
                self.migrate_profile_family,
                self.migrate_profile_dni,
            ]

            for step in steps:
                step()

            elapsed = (datetime.now() - self.stats["start_time"]).total_seconds()

            logger.info("\n" + "█" * 60)
            logger.info("MIGRACIÓN COMPLETADA".center(60))
            logger.info("█" * 60)
            logger.info(f"  Duración   : {elapsed:.1f}s")
            logger.info(f"  Tablas     : {self.stats['migrated_tables']}/8")
            logger.info(
                f"  Registros  : {self.stats['migrated_records']}"
                f" / {self.stats['total_records']}"
            )
            logger.info(f"  Errores    : {len(self.stats['errors'])}")
            if self.stats["errors"]:
                for e in self.stats["errors"][:10]:
                    logger.warning(f"  - {e}")
            logger.info("█" * 60 + "\n")
            return True

        except Exception as err:
            logger.error(f"Error fatal: {err}")
            traceback.print_exc()
            return False
        finally:
            self.disconnect()


# ──────────────────────────────────────────────────────────────────────────────
# Entrada
# ──────────────────────────────────────────────────────────────────────────────

def main():
    print("\n" + "=" * 70)
    print("MIGRACIÓN ERP (MariaDB) → ALMA_BE_V2 (PostgreSQL)".center(70))
    print("=" * 70)

    print("\nMariaDB (ERP):")
    mariadb_host = input("  Host     [localhost]: ").strip() or "localhost"
    mariadb_port = int(input("  Puerto   [3306]:      ").strip() or "3306")
    mariadb_user = input("  Usuario  [app]:       ").strip() or "app"
    mariadb_pass = input("  Password [apppass]:   ").strip() or "apppass"
    mariadb_db   = input("  Base     [erp]:       ").strip() or "erp"

    print("\nPostgreSQL (almadb):")
    pg_host = input("  Host     [localhost]: ").strip() or "localhost"
    pg_port = int(input("  Puerto   [5432]:      ").strip() or "5432")
    pg_user = input("  Usuario  [postgres]:  ").strip() or "postgres"
    pg_pass = input("  Password [admin]:     ").strip() or "admin"
    pg_db   = input("  Base     [almadb]:").strip() or "almadb"

    print("\nCantidad de registros a migrar:")
    print("  (Se aplica sobre la tabla principal 'usuario'.")
    print("   Las tablas de roles y permisos se migran completas siempre.)")
    raw_limit = input("  Cantidad [dejar vacio para todos]: ").strip()
    limit: Optional[int] = None
    if raw_limit:
        try:
            limit = int(raw_limit)
            if limit <= 0:
                print("  Valor invalido, se migraran todos los registros.")
                limit = None
            else:
                print(f"  Se migraran como maximo {limit} personas.")
        except ValueError:
            print("  Valor invalido, se migraran todos los registros.")

    migrator = MariaDBMigrator(
        mariadb_config={
            "host": mariadb_host,
            "port": mariadb_port,
            "user": mariadb_user,
            "password": mariadb_pass,
            "database": mariadb_db,
        },
        postgres_config={
            "host": pg_host,
            "port": pg_port,
            "user": pg_user,
            "password": pg_pass,
            "database": pg_db,
        },
        limit=limit,
    )

    sys.exit(0 if migrator.execute_migration() else 1)


if __name__ == "__main__":
    main()
