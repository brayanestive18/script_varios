#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script simple y rápido para probar conexión a MariaDB
Sin preguntas, usando valores por defecto
"""

import mysql.connector
from mysql.connector import Error as MySQLError
import sys
import io

# Forzar stdout a UTF-8 para evitar errores de encoding en Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

def test_mariadb_quick():
    """Test rápido de MariaDB"""
    
    print("\n" + "="*70)
    print("TEST RÁPIDO DE CONEXIÓN A MARIADB".center(70))
    print("="*70)
    
    # Configuración por defecto locales
    configs = [
        {
            'name': 'MariaDB Local (puerto 3306)',
            'host': 'localhost',
            'port': 3306,
            'user': 'root',
            'password': '',  # Sin contraseña
            'database': 'erp'
        },
        {
            'name': 'MariaDB Local (con contraseña)',
            'host': 'localhost',
            'port': 3306,
            'user': 'app',
            'password': 'apppass',
            'database': 'erp'
        },
        {
            'name': 'MariaDB Alternativo',
            'host': 'localhost',
            'port': 3306,
            'user': 'root',
            'password': 'admin',
            'database': 'erp'
        }
    ]
    
    print("\nIntentando conexiones...\n")
    
    for config in configs:
        print(f"Intento: {config['name']}")
        print(f"  → Conectando a {config['host']}:{config['port']}...")
        
        try:
            conn = mysql.connector.connect(
                host=config['host'],
                port=config['port'],
                user=config['user'],
                password=config['password'],
                database=config['database'],
                use_pure=True,
                autocommit=True
            )
            
            cursor = conn.cursor()
            
            # Obtener información
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()[0]
            
            cursor.execute("SHOW DATABASES")
            databases = [row[0] for row in cursor.fetchall()]
            
            cursor.execute("SHOW TABLES")
            tables = [row[0] for row in cursor.fetchall()]
            
            cursor.execute("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = '{}' GROUP BY TABLE_SCHEMA".format(config['database']))
            cursor.fetchone()  # Consumir resultado para evitar "Unread result found"

            cursor.close()
            conn.close()
            
            print(f"  ✓ ¡ÉXITO! Conectado correctamente")
            print(f"    Versión: {version}")
            print(f"    Base de datos actual: {config['database']}")
            print(f"    Tablas: {len(tables)}")
            if tables:
                print(f"    Primera tabla: {tables[0]}")
            
            print(f"\n{'='*70}")
            print(f"CONFIGURACIÓN EXITOSA:".center(70))
            print(f"{'='*70}")
            print(f"""
Config para migration_mariadb.py:

    MARIADB_HOST = "{config['host']}"
    MARIADB_PORT = {config['port']}
    MARIADB_USER = "{config['user']}"
    MARIADB_PASSWORD = "{config['password']}"
    MARIADB_DATABASE = "{config['database']}"
""")
            print("="*70 + "\n")
            
            return 0
            
        except MySQLError as err:
            error_code = err.errno if hasattr(err, 'errno') else 'N/A'
            error_msg = err.msg if hasattr(err, 'msg') else str(err)
            print(f"  ✗ Error #{error_code}: {error_msg}")
            
            # Diagnóstico específico
            if error_code == 1045:
                print(f"    → Acceso denegado (usuario/contraseña)")
            elif error_code == 1049:
                print(f"    → Base de datos no existe")
            elif error_code == 2003:
                print(f"    → No se puede conectar (¿MariaDB está corriendo?)")
            
        except Exception as err:
            print(f"  ✗ Error: {err}")
        
        print()
    
    print("\n" + "="*70)
    print("NINGUNA CONFIGURACIÓN FUNCIONÓ".center(70))
    print("="*70)
    print("""
Posibles soluciones:

1. Verificar que MariaDB está corriendo:
   Windows: Abrir Services (services.msc) y buscar MariaDB
   Linux:   sudo systemctl status mariadb

2. Verificar usuario/contraseña:
   mysql -h localhost -u root -p

3. Crear la base de datos si no existe:
   mysql -u root -p -e "CREATE DATABASE erp"

4. Ejecutar diagnóstico más detallado:
   python diagnostic_tool_mejorado.py

5. Ver documentación en:
   SOLUCION_MARIADB.md
""")
    print("="*70 + "\n")
    
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
