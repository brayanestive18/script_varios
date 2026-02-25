#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script mejorado de diagnóstico para MariaDB/MySQL y PostgreSQL
Verifica conectividad con información detallada de errores
"""

import sys
import io
import socket
from typing import Dict, List, Tuple

import mysql.connector
from mysql.connector import Error as MySQLError
import psycopg2
from psycopg2 import OperationalError
from tabulate import tabulate

# UTF-8 en consola Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")


class DatabaseDiagnostics:
    """Diagnóstico avanzado de bases de datos"""
    
    def __init__(self):
        self.results = []
    
    def test_host_reachability(self, host: str, port: int, timeout: int = 3) -> bool:
        """Verifica si el host y puerto son accesibles"""
        try:
            socket.create_connection((host, port), timeout=timeout)
            return True
        except (socket.timeout, socket.error) as err:
            print(f"  ⚠ Host {host}:{port} no es alcanzable: {err}")
            return False
    
    def test_mariadb_connection(self, config: Dict) -> Tuple[bool, str]:
        """Prueba conexión a MariaDB/MySQL con diagnóstico detallado"""
        
        print(f"\n🔍 Diagnosticando MariaDB/MySQL...")
        print(f"  Host: {config.get('host', 'localhost')}")
        print(f"  Puerto: {config.get('port', 3306)}")
        print(f"  Usuario: {config.get('user', 'desconocido')}")
        print(f"  BD: {config.get('database', 'N/A')}")
        
        # Verificar accesibilidad del host
        host = config.get('host', 'localhost')
        port = config.get('port', 3306)
        
        if not self.test_host_reachability(host, port):
            msg = f"No se puede alcanzar {host}:{port}"
            print(f"  ✗ {msg}")
            return False, msg
        
        print(f"  ✓ Host alcanzable")
        
        # Conectar al servidor sin base de datos para verificar credenciales
        try:
            server_config = {k: v for k, v in config.items() if k != "database"}
            server_config["use_pure"] = True

            print(f"  → Conectando al servidor...")
            conn = mysql.connector.connect(**server_config)
            cursor = conn.cursor()

            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()[0]
            print(f"  ✓ Version: {version}")

            # Verificar que la base de datos exista
            cursor.execute("SHOW DATABASES")
            databases = [row[0] for row in cursor.fetchall()]
            db_name = config.get("database")
            if db_name and db_name not in databases:
                msg = f"Base de datos '{db_name}' no encontrada"
                print(f"  ✗ {msg}")
                print(f"  ℹ Disponibles: {', '.join(databases[:8])}")
                cursor.close()
                conn.close()
                return False, msg

            cursor.close()
            conn.close()

            # Conectar ahora con la base de datos
            print(f"  → Conectando a base de datos '{db_name}'...")
            full_config = dict(config, use_pure=True)
            conn = mysql.connector.connect(**full_config)
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            conn.close()

            print(f"  ✓ Conexion MariaDB/MySQL exitosa")
            return True, "Conexion exitosa"
            
        except MySQLError as err:
            error_code = err.errno if hasattr(err, 'errno') else 'Desconocido'
            error_msg = str(err)
            
            print(f"  ✗ Error MySQL #{error_code}: {error_msg}")
            
            # Proporcionar diagnóstico específico por código de error
            diagnostics = {
                1045: "❌ Acceso denegado: usuario/contraseña incorrecta",
                1049: "❌ Base de datos desconocida",
                2003: "❌ No se puede conectar al servidor (verificar host/puerto)",
                2006: "❌ Conexión perdida",
                2013: "❌ Conexión perdida",
            }
            
            if error_code in diagnostics:
                print(f"     {diagnostics[error_code]}")
            
            return False, error_msg
            
        except Exception as err:
            error_msg = str(err)
            print(f"  ✗ Error inesperado: {error_msg}")
            return False, error_msg
    
    def test_postgres_connection(self, config: Dict) -> Tuple[bool, str]:
        """Prueba conexión a PostgreSQL con diagnóstico detallado"""
        
        print(f"\n🔍 Diagnosticando PostgreSQL...")
        print(f"  Host: {config.get('host', 'localhost')}")
        print(f"  Puerto: {config.get('port', 5432)}")
        print(f"  Usuario: {config.get('user', 'desconocido')}")
        print(f"  BD: {config.get('database', 'N/A')}")
        
        # Verificar accesibilidad del host
        host = config.get('host', 'localhost')
        port = config.get('port', 5432)
        
        if not self.test_host_reachability(host, port):
            msg = f"No se puede alcanzar {host}:{port}"
            print(f"  ✗ {msg}")
            return False, msg
        
        print(f"  ✓ Host alcanzable")
        
        try:
            print(f"  → Conectando...")
            conn = psycopg2.connect(**config)
            cursor = conn.cursor()
            
            # Obtener versión
            cursor.execute("SELECT version()")
            version = cursor.fetchone()[0]
            print(f"  ✓ Versión: {version.split(',')[0]}")
            
            cursor.execute("SELECT 1")
            cursor.close()
            conn.close()
            
            print(f"  ✓ Conexión PostgreSQL exitosa")
            return True, "Conexión exitosa"
            
        except OperationalError as err:
            error_msg = str(err)
            print(f"  ✗ Error operacional: {error_msg}")
            
            if "could not connect" in error_msg:
                print(f"     ❌ No se puede conectar (verificar que PostgreSQL esté corriendo)")
            elif "password authentication" in error_msg:
                print(f"     ❌ Error de autenticación (revisar usuario/contraseña)")
            elif "does not exist" in error_msg:
                print(f"     ❌ Base de datos no existe")
            
            return False, error_msg
            
        except Exception as err:
            error_msg = str(err)
            print(f"  ✗ Error inesperado: {error_msg}")
            return False, error_msg
    
    def test_mariadb_tables(self, config: Dict) -> List[str]:
        """Lista tablas en MariaDB"""
        try:
            conn = mysql.connector.connect(**config)
            cursor = conn.cursor()
            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]
            cursor.close()
            conn.close()
            return sorted(tables)
        except Exception as err:
            print(f"  ✗ Error listando tablas: {err}")
            return []
    
    def test_postgres_tables(self, config: Dict) -> List[str]:
        """Lista tablas en PostgreSQL"""
        try:
            conn = psycopg2.connect(**config)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_type = 'BASE TABLE'
            """)
            tables = [row[0] for row in cursor.fetchall()]
            cursor.close()
            conn.close()
            return sorted(tables)
        except Exception as err:
            print(f"  ✗ Error listando tablas: {err}")
            return []
    
    def get_mariadb_row_count(self, config: Dict, table_name: str) -> int:
        """Obtiene contador de filas en MariaDB"""
        try:
            conn = mysql.connector.connect(**config)
            cursor = conn.cursor()
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            count = cursor.fetchone()[0]
            cursor.close()
            conn.close()
            return count
        except Exception as err:
            return 0
    
    def print_full_report(self, mariadb_config: Dict, postgres_config: Dict):
        """Imprime reporte completo de diagnóstico"""
        
        print("\n" + "=" * 100)
        print("REPORTE COMPLETO DE DIAGNÓSTICO".center(100))
        print("=" * 100)
        
        # Test MariaDB
        mariadb_ok, mariadb_msg = self.test_mariadb_connection(mariadb_config)
        
        # Test PostgreSQL
        postgres_ok, postgres_msg = self.test_postgres_connection(postgres_config)
        
        print("\n" + "=" * 100)
        print("RESUMEN DE CONEXIONES")
        print("=" * 100)
        
        summary_data = [
            ["MariaDB/MySQL", "✓" if mariadb_ok else "✗", mariadb_msg],
            ["PostgreSQL", "✓" if postgres_ok else "✗", postgres_msg]
        ]
        
        print(tabulate(summary_data,
                      headers=['Base de Datos', 'Estado', 'Mensaje'],
                      tablefmt='grid'))
        
        if not (mariadb_ok and postgres_ok):
            print("\n⚠️  ADVERTENCIA: No se puede proceder con la migración")
            print("    Revisa los errores anteriores y verifica la configuración\n")
            return False
        
        # Listar tablas si la conexión es exitosa
        print("\n" + "=" * 100)
        print("TABLAS DISPONIBLES")
        print("=" * 100)
        
        mariadb_tables = self.test_mariadb_tables(mariadb_config)
        postgres_tables = self.test_postgres_tables(postgres_config)
        
        print(f"\n📊 MariaDB ({mariadb_config['database']}): {len(mariadb_tables)} tablas")
        if mariadb_tables[:10]:
            print(f"   Primeras 10: {', '.join(mariadb_tables[:10])}")
        
        print(f"\n📊 PostgreSQL ({postgres_config['database']}): {len(postgres_tables)} tablas")
        if postgres_tables[:10]:
            print(f"   Primeras 10: {', '.join(postgres_tables[:10])}")
        
        # Tablas críticas
        critical_tables = {
            'roles': ('roles', 'roles'),
            'usuarios': ('users', 'users'),
        }
        
        print("\n" + "=" * 100)
        print("TABLAS CRÍTICAS PARA MIGRACIÓN")
        print("=" * 100)
        
        critical_data = []
        for name, (mysql_table, pg_table) in critical_tables.items():
            mysql_exists = mysql_table in mariadb_tables
            pg_exists = pg_table in postgres_tables
            mysql_count = self.get_mariadb_row_count(mariadb_config, mysql_table) if mysql_exists else 0
            pg_count = 0  # Asumimos que está vacía antes de migración
            
            mysql_status = f"{'✓' if mysql_exists else '✗'} {mysql_count} registros"
            pg_status = f"{'✓' if pg_exists else '✗'}"
            
            critical_data.append([name, mysql_status, pg_status])
        
        print(tabulate(critical_data,
                      headers=['Tabla', 'MariaDB', 'PostgreSQL'],
                      tablefmt='grid'))
        
        print("\n" + "=" * 100)
        print("✅ DIAGNÓSTICO COMPLETADO")
        print("=" * 100 + "\n")
        
        return mariadb_ok and postgres_ok


def interactive_diagnostic():
    """Interfaz interactiva de diagnóstico"""
    
    print("\n" + "=" * 100)
    print("HERRAMIENTA DE DIAGNÓSTICO - MARIADB/MYSQL Y POSTGRESQL".center(100))
    print("=" * 100)
    
    print("\nCONFIGURACION PREDETERMINADA:")
    print("  MariaDB:    localhost:3306  usuario=app  password=apppass  db=erp")
    print("  PostgreSQL: localhost:5432  usuario=postgres password=admin db=almadb")

    print("\n¿Deseas ingresar credenciales manualmente? (s/n) [n]: ", end="")
    manual = input().strip().lower() == "s"

    if manual:
        print("\nMARIADB:")
        mariadb_host = input("  Host     [localhost]: ").strip() or "localhost"
        mariadb_port = int(input("  Puerto   [3306]:      ").strip() or "3306")
        mariadb_user = input("  Usuario  [app]:       ").strip() or "app"
        mariadb_password = input("  Password [apppass]:   ").strip() or "apppass"
        mariadb_db = input("  Base     [erp]:       ").strip() or "erp"

        print("\nPOSTGRESQL:")
        postgres_host = input("  Host     [localhost]: ").strip() or "localhost"
        postgres_port = int(input("  Puerto   [5432]:      ").strip() or "5432")
        postgres_user = input("  Usuario  [postgres]:  ").strip() or "postgres"
        postgres_password = input("  Password:             ").strip()
        postgres_db = input("  Base     [ALMA_BE_V2]:").strip() or "ALMA_BE_V2"
    else:
        mariadb_host, mariadb_port = "localhost", 3306
        mariadb_user, mariadb_password, mariadb_db = "app", "apppass", "erp"

        postgres_host, postgres_port = "localhost", 5432
        postgres_user, postgres_password, postgres_db = "postgres", "admin", "almadb"

    mariadb_config = {
        "host": mariadb_host,
        "port": mariadb_port,
        "user": mariadb_user,
        "password": mariadb_password,
        "database": mariadb_db,
        "autocommit": True,
    }

    postgres_config = {
        "host": postgres_host,
        "port": postgres_port,
        "user": postgres_user,
        "password": postgres_password,
        "database": postgres_db,
    }

    diagnostics = DatabaseDiagnostics()
    success = diagnostics.print_full_report(mariadb_config, postgres_config)

    if success:
        print("Conexiones correctas. Puedes proceder con la migracion.\n")
        return 0
    else:
        print("Hay problemas de conexion. Verifica la configuracion.\n")
        return 1


if __name__ == "__main__":
    try:
        sys.exit(interactive_diagnostic())
    except KeyboardInterrupt:
        print("\n\n⚠️  Operación cancelada por el usuario\n")
        sys.exit(1)
    except Exception as err:
        print(f"\n❌ Error inesperado: {err}\n")
        sys.exit(1)
