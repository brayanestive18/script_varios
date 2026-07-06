#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Actualiza las fechas de las clases de un grupo a partir de una clase dada
y agrega las clases faltantes hasta una fecha fin.

- Pide: grupo, clase de inicio, fecha de inicio y fecha de fin.
- A la clase de inicio le asigna esa fecha (conservando la hora existente).
- Cada clase siguiente recibe la fecha de la anterior + 7 días (mismo día de semana),
  conservando también su hora original.
- Si hay más semanas que clases existentes, inserta las clases faltantes
  copiando horario y est_clase de la última clase del grupo.
- La fecha de fin es opcional: si se deja en blanco, solo se actualizan las
  clases existentes desde la clase indicada hasta el último registro del
  grupo en la base de datos (sin insertar clases nuevas).
- Muestra una previsualización y pide confirmación antes de aplicar.
"""

from __future__ import annotations

import sys
import os
from datetime import datetime, timedelta
import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    'host':     os.getenv('DB_HOST', 'localhost'),
    'user':     os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'erp'),
    'port':     int(os.getenv('DB_PORT', 3306)),
}


def get_db_connection():
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        if conn.is_connected():
            return conn
    except Error as e:
        print(f"Error al conectar a la base de datos: {e}")
        sys.exit(1)


def pedir_entero(prompt: str) -> int:
    while True:
        valor = input(prompt).strip()
        if valor.isdigit():
            return int(valor)
        print("  Por favor ingresa un número entero válido.")


def pedir_fecha(prompt: str) -> datetime.date:
    while True:
        valor = input(prompt).strip()
        try:
            return datetime.strptime(valor, "%d/%m/%Y").date()
        except ValueError:
            print("  Formato no reconocido. Usa DD/MM/YYYY (ej: 25/03/2026).")


def pedir_fecha_opcional(prompt: str) -> datetime.date | None:
    while True:
        valor = input(prompt).strip()
        if not valor:
            return None
        try:
            return datetime.strptime(valor, "%d/%m/%Y").date()
        except ValueError:
            print("  Formato no reconocido. Usa DD/MM/YYYY (ej: 25/03/2026) o deja vacío.")


def calcular_cambios(clases: list[dict], fecha_inicio_nueva, fecha_fin_nueva,
                     grupo_id: int, siguiente_id: int) -> tuple[list[dict], list[dict]]:
    """
    Devuelve:
      actualizaciones — clases existentes con fechas nuevas.
      inserciones     — nuevas clases a insertar para cubrir hasta fecha_fin_nueva.

    Si fecha_fin_nueva es None, solo se generan tantas fechas como clases
    existentes (no se insertan clases nuevas).
    """
    if fecha_fin_nueva is None:
        fechas = [fecha_inicio_nueva + timedelta(weeks=i) for i in range(len(clases))]
    else:
        # Generar todas las fechas semanales en el rango
        fechas = []
        f = fecha_inicio_nueva
        while f <= fecha_fin_nueva:
            fechas.append(f)
            f += timedelta(weeks=1)

    ref = clases[-1]  # última clase: fuente de horario/est_clase/hora para nuevas
    actualizaciones = []
    inserciones = []

    for i, fecha in enumerate(fechas):
        if i < len(clases):
            clase = clases[i]
            fi_orig: datetime = clase['fecha_inicio']
            ff_orig: datetime = clase['fecha_fin']
            nueva_fi = datetime.combine(fecha, fi_orig.time())
            nueva_ff = datetime.combine(fecha, ff_orig.time())
            actualizaciones.append({
                'grupo':              clase['grupo'],
                'id':                 clase['id'],
                'fi_original':        fi_orig,
                'ff_original':        ff_orig,
                'nueva_fecha_inicio': nueva_fi,
                'nueva_fecha_fin':    nueva_ff,
            })
        else:
            nueva_fi = datetime.combine(fecha, ref['fecha_inicio'].time())
            nueva_ff = datetime.combine(fecha, ref['fecha_fin'].time())
            inserciones.append({
                'grupo':              grupo_id,
                'id':                 siguiente_id,
                'horario':            ref['horario'],
                'est_clase':          ref['est_clase'],
                'nueva_fecha_inicio': nueva_fi,
                'nueva_fecha_fin':    nueva_ff,
            })
            siguiente_id += 1

    return actualizaciones, inserciones


def mostrar_preview(actualizaciones: list[dict], inserciones: list[dict]):
    print("\n" + "=" * 80)

    if actualizaciones:
        print(f"  ACTUALIZACIONES ({len(actualizaciones)} clase(s))")
        print(f"{'CLASE':>6}  {'FECHA_INICIO ACTUAL':<22}  {'→':<2}  {'FECHA_INICIO NUEVA':<22}")
        print(f"{'':>6}  {'FECHA_FIN ACTUAL':<22}  {'→':<2}  {'FECHA_FIN NUEVA':<22}")
        print("-" * 80)
        for c in actualizaciones:
            print(f"  #{c['id']:>3}  {str(c['fi_original']):<22}     {str(c['nueva_fecha_inicio']):<22}")
            print(f"{'':>6}  {str(c['ff_original']):<22}     {str(c['nueva_fecha_fin']):<22}")
            print()

    if inserciones:
        if actualizaciones:
            print("-" * 80)
        print(f"  INSERCIONES ({len(inserciones)} clase(s) nueva(s))")
        print(f"{'CLASE':>6}  {'FECHA_INICIO':<22}  {'FECHA_FIN':<22}")
        print("-" * 80)
        for c in inserciones:
            print(f"  #{c['id']:>3}  {str(c['nueva_fecha_inicio']):<22}  {str(c['nueva_fecha_fin']):<22}")
        print()

    print("=" * 80)


def aplicar_cambios(conn, actualizaciones: list[dict], inserciones: list[dict]):
    cursor = conn.cursor()
    try:
        for c in actualizaciones:
            cursor.execute(
                """
                UPDATE clase
                   SET fecha_inicio = %s,
                       fecha_fin    = %s
                 WHERE grupo = %s
                   AND id    = %s
                """,
                (c['nueva_fecha_inicio'], c['nueva_fecha_fin'], c['grupo'], c['id'])
            )

        for c in inserciones:
            cursor.execute(
                """
                INSERT INTO clase (grupo, id, horario, fecha_inicio, fecha_fin, est_clase)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (c['grupo'], c['id'], c['horario'],
                 c['nueva_fecha_inicio'], c['nueva_fecha_fin'], c['est_clase'])
            )

        conn.commit()
        if actualizaciones:
            print(f"\n✓ Se actualizaron {len(actualizaciones)} clase(s).")
        if inserciones:
            print(f"✓ Se insertaron  {len(inserciones)} clase(s) nueva(s).")
    except Error as e:
        conn.rollback()
        print(f"\n✗ Error: {e}")
        print("  Se realizó un rollback; ningún cambio fue guardado.")
    finally:
        cursor.close()


def main():
    print("=== Actualizador de fechas de clases ===\n")

    grupo_id     = pedir_entero("Número de grupo  : ")
    clase_inicio = pedir_entero("ID de clase inicial (desde la que actualizar): ")
    fecha_inicio = pedir_fecha ("Fecha de inicio  (DD/MM/YYYY): ")
    fecha_fin    = pedir_fecha_opcional(
        "Fecha de fin     (DD/MM/YYYY, opcional, vacío = hasta la última clase existente): "
    )

    if fecha_fin is not None and fecha_fin < fecha_inicio:
        print("\n  La fecha de fin no puede ser anterior a la fecha de inicio.")
        sys.exit(1)

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Clases existentes desde la clase de inicio
    cursor.execute(
        """
        SELECT grupo, id, horario, est_clase, fecha_inicio, fecha_fin
          FROM clase
         WHERE grupo = %s
           AND id   >= %s
         ORDER BY id ASC
        """,
        (grupo_id, clase_inicio)
    )
    clases = cursor.fetchall()

    # Siguiente ID disponible para el grupo
    cursor.execute(
        "SELECT COALESCE(MAX(id), 0) + 1 AS siguiente FROM clase WHERE grupo = %s",
        (grupo_id,)
    )
    siguiente_id = cursor.fetchone()['siguiente']
    cursor.close()

    if not clases:
        print(f"\nNo se encontraron clases para el grupo {grupo_id} a partir de la clase {clase_inicio}.")
        conn.close()
        sys.exit(0)

    print(f"\nSe encontraron {len(clases)} clase(s) existentes en el grupo {grupo_id}.")
    if fecha_fin is None:
        print("No se indicó fecha de fin: se reprogramarán todas las clases existentes "
              "desde la indicada hasta la última registrada (sin insertar clases nuevas).")

    actualizaciones, inserciones = calcular_cambios(
        clases, fecha_inicio, fecha_fin, grupo_id, siguiente_id
    )

    if not actualizaciones and not inserciones:
        print("No hay cambios que aplicar.")
        conn.close()
        sys.exit(0)

    mostrar_preview(actualizaciones, inserciones)

    respuesta = input("¿Aplicar estos cambios? [s/N]: ").strip().lower()
    if respuesta == 's':
        aplicar_cambios(conn, actualizaciones, inserciones)
    else:
        print("Operación cancelada. No se realizaron cambios.")

    conn.close()


if __name__ == '__main__':
    main()
