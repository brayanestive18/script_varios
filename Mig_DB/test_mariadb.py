#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test rápido de conexión a MariaDB.
Carga credenciales desde .env (un nivel arriba) y las prueba primero.
Si falla, intenta configuraciones de fallback.
"""

import io
import os
import sys
from pathlib import Path

import mysql.connector
from mysql.connector import Error as MySQLError
from dotenv import load_dotenv

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

_ENV_PATH = Path(__file__).parent.parent / ".env"
load_dotenv(_ENV_PATH)


def _build_configs() -> list:
    """
    Devuelve lista de configuraciones a intentar.
    La del .env va siempre primera si las variables están definidas.
    """
    configs = []

    # ── Config desde .env (prioritaria)
    env_host = os.getenv("DB_HOST", "").strip()
    env_user = os.getenv("DB_USER", "").strip()
    env_pass = os.getenv("DB_PASSWORD", "").strip()
    env_db   = os.getenv("DB_NAME", "").strip()
    env_port = int(os.getenv("DB_PORT", "3306").strip() or "3306")

    if env_host and env_user and env_db:
        configs.append({
            "name":     f"[.env]  {env_user}@{env_host}:{env_port}/{env_db}",
            "host":     env_host,
            "port":     env_port,
            "user":     env_user,
            "password": env_pass,
            "database": env_db,
        })

    # ── Fallbacks
    configs += [
        {
            "name":     "Fallback — root sin contraseña",
            "host":     "localhost",
            "port":     3306,
            "user":     "root",
            "password": "",
            "database": "erp",
        },
        {
            "name":     "Fallback — app/apppass",
            "host":     "localhost",
            "port":     3306,
            "user":     "app",
            "password": "apppass",
            "database": "erp",
        },
        {
            "name":     "Fallback — root/admin",
            "host":     "localhost",
            "port":     3306,
            "user":     "root",
            "password": "admin",
            "database": "erp",
        },
    ]

    return configs


def test_mariadb_quick() -> int:
    print("\n" + "=" * 70)
    print("TEST RÁPIDO DE CONEXIÓN A MARIADB".center(70))
    print("=" * 70)

    if _ENV_PATH.exists():
        print(f"\n  .env cargado desde: {_ENV_PATH}")
    else:
        print(f"\n  .env no encontrado en {_ENV_PATH} — usando solo fallbacks.")

    configs = _build_configs()
    print(f"\n  Configuraciones a probar: {len(configs)}\n")

    for config in configs:
        print(f"  ┌─ {config['name']}")
        print(f"  │  Conectando a {config['host']}:{config['port']}...")

        try:
            conn = mysql.connector.connect(
                host=config["host"],
                port=config["port"],
                user=config["user"],
                password=config["password"],
                database=config["database"],
                use_pure=True,
                autocommit=True,
            )

            cursor = conn.cursor()
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()[0]

            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]

            cursor.close()
            conn.close()

            print(f"  │  ✓ Conectado — MariaDB {version}")
            print(f"  │  Base de datos: {config['database']}  |  Tablas: {len(tables)}")
            if tables:
                print(f"  │  Primera tabla: {tables[0]}")
            print(f"  └─ ¡ÉXITO!\n")

            print("=" * 70)
            print("CREDENCIALES VÁLIDAS".center(70))
            print("=" * 70)
            print(f"""
  Agrega o actualiza en tu .env:

    DB_HOST={config['host']}
    DB_PORT={config['port']}
    DB_USER={config['user']}
    DB_PASSWORD={config['password']}
    DB_NAME={config['database']}
""")
            print("=" * 70 + "\n")
            return 0

        except MySQLError as err:
            code = err.errno if hasattr(err, "errno") else "N/A"
            msg  = err.msg  if hasattr(err, "msg")   else str(err)
            print(f"  │  ✗ Error #{code}: {msg}")
            if code == 1045:
                print("  │    → Acceso denegado (usuario/contraseña incorrectos)")
            elif code == 1049:
                print("  │    → Base de datos no existe")
            elif code == 2003:
                print("  │    → No se puede conectar (¿MariaDB está corriendo?)")
            print("  └─ Fallo\n")

        except Exception as err:
            print(f"  │  ✗ {err}")
            print("  └─ Fallo\n")

    print("=" * 70)
    print("NINGUNA CONFIGURACIÓN FUNCIONÓ".center(70))
    print("=" * 70)
    print("""
  Posibles soluciones:

  1. Verificar que MariaDB está corriendo:
       macOS/Linux:  sudo systemctl status mariadb
       Docker:       docker-compose up -d

  2. Revisar credenciales en el .env del proyecto

  3. Crear la base de datos si no existe:
       mysql -u root -p -e "CREATE DATABASE erp"

  4. Ejecutar diagnóstico detallado:
       python diagnostic_tool_mejorado.py
""")
    print("=" * 70 + "\n")
    return 1


if __name__ == "__main__":
    try:
        sys.exit(test_mariadb_quick())
    except KeyboardInterrupt:
        print("\n\nCancelado por usuario\n")
        sys.exit(1)
    except Exception as err:
        print(f"\nError: {err}\n")
        sys.exit(1)
