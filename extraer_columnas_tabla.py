#!/usr/bin/env python3
"""
Extrae todas las columnas de un esquema (desde un archivo SQL con CREATE TABLE,
o conectándose en vivo a MariaDB/MySQL o PostgreSQL) y genera un CSV de una
sola columna con el formato tabla.campo
"""
import csv
import os
import re
import sys
from urllib.parse import urlparse, unquote

SKIP_PREFIXES = (
    "primary key",
    "unique",
    "key ",
    "key(",
    "constraint",
    "foreign key",
    "index",
    "check",
    "fulltext",
    "spatial",
)


def find_matching_paren(text, start):
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("Paréntesis sin cerrar")


def split_top_level(body):
    parts = []
    depth = 0
    current = []
    for ch in body:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(ch)
    if current:
        parts.append("".join(current))
    return parts


def extract_columns(sql_text):
    rows = []
    for match in re.finditer(r"create\s+table\s+(?:if\s+not\s+exists\s+)?`?(\w+)`?\s*\(", sql_text, re.IGNORECASE):
        table_name = match.group(1)
        open_paren = match.end() - 1
        close_paren = find_matching_paren(sql_text, open_paren)
        body = sql_text[open_paren + 1:close_paren]

        for raw_field in split_top_level(body):
            field = raw_field.strip().strip("\n")
            field_lower = field.lower().lstrip("`")
            if not field or field_lower.startswith(SKIP_PREFIXES):
                continue
            col_match = re.match(r"`?(\w+)`?", field)
            if col_match:
                rows.append(f"{table_name}.{col_match.group(1)}")
    return rows


def extract_columns_from_mariadb(db_url):
    import mysql.connector

    parsed = urlparse(db_url)
    database = parsed.path.lstrip("/")
    conn = mysql.connector.connect(
        host=parsed.hostname or "localhost",
        port=parsed.port or 3306,
        user=unquote(parsed.username) if parsed.username else None,
        password=unquote(parsed.password) if parsed.password else None,
        database=database,
    )
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT table_name, column_name
            FROM information_schema.columns
            WHERE table_schema = %s
            ORDER BY table_name, ordinal_position
            """,
            (database,),
        )
        rows = [f"{table}.{column}" for table, column in cursor.fetchall()]
        cursor.close()
        return rows, database
    finally:
        conn.close()


def extract_columns_from_postgres(db_url):
    import psycopg2

    database = urlparse(db_url).path.lstrip("/")
    conn = psycopg2.connect(db_url)
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT table_name, column_name
            FROM information_schema.columns
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY table_name, ordinal_position
            """
        )
        rows = [f"{table}.{column}" for table, column in cursor.fetchall()]
        cursor.close()
        return rows, database
    finally:
        conn.close()


def extract_columns_from_db():
    print("Motor de base de datos:")
    print("1) MariaDB / MySQL")
    print("2) PostgreSQL")
    engine = input("Opción [1/2]: ").strip()

    if engine == "2":
        db_url = input(
            "Database URL (ej: postgresql://usuario:password@host:5432/nombre_bd): "
        ).strip()
        return extract_columns_from_postgres(db_url)

    db_url = input(
        "Database URL (ej: mysql://usuario:password@host:3306/nombre_bd): "
    ).strip()
    return extract_columns_from_mariadb(db_url)


def main():
    print("Origen de las columnas:")
    print("1) Archivo SQL con CREATE TABLE")
    print("2) Conexión en vivo a una base de datos")
    source = input("Opción [1/2]: ").strip()

    if source == "2":
        rows, db_name = extract_columns_from_db()
    else:
        sql_path = sys.argv[1] if len(sys.argv) > 1 else "ERP_DB_TABLES.sql"
        db_name = os.path.splitext(os.path.basename(sql_path))[0]
        with open(sql_path, "r", encoding="utf-8") as f:
            sql_text = f.read()
        rows = extract_columns(sql_text)

    output_path = sys.argv[2] if len(sys.argv) > 2 else f"field_{db_name}.csv"

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["tabla.campo"])
        for row in rows:
            writer.writerow([row])

    print(f"Generadas {len(rows)} columnas en {output_path}")


if __name__ == "__main__":
    main()
