#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Centro de control - Migración ERP (MariaDB) → ALMA_BE_V2 (PostgreSQL)
"""

import os
import sys
import io
import subprocess
from pathlib import Path

# UTF-8 en consola Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

BASE_DIR = Path(__file__).parent

# Scripts ejecutables disponibles
SCRIPTS = {
    "1": ("test_mariadb.py",             "Test de conexión MariaDB"),
    "2": ("diagnostic_tool_mejorado.py", "Diagnóstico avanzado MariaDB"),
    "3": ("migration_mariadb.py",        "Migración MariaDB → PostgreSQL"),
    "4": ("setup.py",                    "Instalación y configuración"),
}

# Archivos de documentación
DOCS = {
    "5": ("SOLUCION_MARIADB.md", "Solución de problemas MariaDB"),
    "6": ("GUIA_COMPLETA.md",    "Guía completa de uso"),
}


# ─────────────────────────────────────────────────────────────────────────────

def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")


def open_file(path: Path):
    """Abre un archivo con la aplicación predeterminada del sistema."""
    try:
        os.startfile(path)
        print(f"\n  Abriendo: {path.name}")
    except Exception as err:
        print(f"\n  Error al abrir el archivo: {err}")


def run_script(path: Path):
    """Ejecuta un script Python en el mismo intérprete."""
    subprocess.run([sys.executable, str(path)], check=False)


def print_menu():
    print("\n" + "=" * 70)
    print("MIGRACIÓN ERP → ALMA_BE_V2".center(70))
    print("=" * 70)
    print()
    print("  ─── Scripts ──────────────────────────────────────────────────")
    for key, (filename, label) in SCRIPTS.items():
        status = "" if (BASE_DIR / filename).exists() else "  [no encontrado]"
        print(f"  {key}. {label}{status}")
    print()
    print("  ─── Documentación ────────────────────────────────────────────")
    for key, (filename, label) in DOCS.items():
        status = "" if (BASE_DIR / filename).exists() else "  [no encontrado]"
        print(f"  {key}. {label}{status}")
    print()
    print("  0. Salir")
    print()
    print("=" * 70)


# ─────────────────────────────────────────────────────────────────────────────

def main():
    while True:
        clear_screen()
        print_menu()

        choice = input("  Selecciona una opcion (0-6): ").strip()

        if choice == "0":
            print("\n  Hasta luego.\n")
            sys.exit(0)

        elif choice in SCRIPTS:
            filename, label = SCRIPTS[choice]
            path = BASE_DIR / filename

            clear_screen()
            print(f"\n{'=' * 70}")
            print(f"  {label}".upper())
            print(f"{'=' * 70}\n")

            if path.exists():
                run_script(path)
            else:
                print(f"  Script no encontrado: {filename}")

            print(f"\n{'=' * 70}")
            input("  Presiona Enter para volver al menu...")

        elif choice in DOCS:
            filename, label = DOCS[choice]
            path = BASE_DIR / filename

            clear_screen()
            print(f"\n{'=' * 70}")
            print(f"  {label}".upper())
            print(f"{'=' * 70}")

            if path.exists():
                open_file(path)
            else:
                print(f"\n  Archivo no encontrado: {filename}")

            input("\n  Presiona Enter para volver al menu...")

        else:
            print("\n  Opcion invalida.")
            input("  Presiona Enter para continuar...")


# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n  Operacion cancelada por el usuario.\n")
        sys.exit(0)
    except Exception as err:
        print(f"\n  Error: {err}\n")
        sys.exit(1)
