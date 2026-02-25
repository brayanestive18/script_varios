#!/usr/bin/env python3
"""
Script de instalación y configuración rápida
Ayuda a configurar el entorno para la migración
"""

import os
import sys
import subprocess
from pathlib import Path


def print_header(text: str):
    """Imprime un encabezado formateado"""
    print("\n" + "=" * 80)
    print(text.center(80))
    print("=" * 80)


def check_python_version():
    """Verifica la versión de Python"""
    version_info = sys.version_info
    if version_info.major >= 3 and version_info.minor >= 8:
        print(f"✓ Python {version_info.major}.{version_info.minor} detectado")
        return True
    else:
        print(f"✗ Se requiere Python 3.8+, encontrado: {version_info.major}.{version_info.minor}")
        return False


def install_requirements():
    """Instala los requisitos del project"""
    print("\nInstalando paquetes requeridos...")
    try:
        requirements_file = Path(__file__).parent / 'requirements.txt'
        if requirements_file.exists():
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', str(requirements_file)])
            print("✓ Paquetes instalados correctamente")
            return True
        else:
            print(f"✗ No se encontró {requirements_file}")
            return False
    except subprocess.CalledProcessError as err:
        print(f"✗ Error instalando paquetes: {err}")
        return False


def create_config_template():
    """Crea un archivo de configuración de plantilla"""
    config_template = '''# Configuración de migración - ACTUALIZA ESTOS VALORES
# ====================================================

# Credenciales MySQL (ERP_DB_TABLES)
MYSQL_HOST = "localhost"
MYSQL_USER = "root"
MYSQL_PASSWORD = ""  # Ingresa tu contraseña
MYSQL_DATABASE = "ERP_DB_TABLES"

# Credenciales PostgreSQL (ALMA_BE_V2)
POSTGRES_HOST = "localhost"
POSTGRES_USER = "postgres"
POSTGRES_PASSWORD = ""  # Ingresa tu contraseña
POSTGRES_DATABASE = "ALMA_BE_V2"
POSTGRES_PORT = 5432

# Configuración de migración
LOG_LEVEL = "INFO"  # DEBUG, INFO, WARNING, ERROR
BATCH_SIZE = 1000
CONTINUE_ON_ERROR = True
VERIFY_AFTER_MIGRATION = True
'''
    
    config_file = Path(__file__).parent / 'credentials.py'
    if not config_file.exists():
        with open(config_file, 'w', encoding='utf-8') as f:
            f.write(config_template)
        print(f"✓ Archivo de credenciales creado: {config_file}")
        print("  ⚠ IMPORTANTE: Edita credenciales.py con tus datos reales")
        return True
    else:
        print(f"ℹ Archivo de credenciales ya existe: {config_file}")
        return False


def test_imports():
    """Verifica que los módulos se pueden importar"""
    print("\nVerificando módulos...")
    
    modules = ['mysql.connector', 'psycopg2', 'tabulate']
    all_ok = True
    
    for module in modules:
        try:
            __import__(module)
            print(f"✓ {module}")
        except ImportError:
            print(f"✗ {module} no instalado")
            all_ok = False
    
    return all_ok


def print_next_steps():
    """Imprime los siguientes pasos"""
    print_header("SIGUIENTES PASOS")
    
    print("""
1. EDITAR CREDENCIALES:
   Abre el archivo 'credentials.py' y actualiza:
   - MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD
   - POSTGRES_HOST, POSTGRES_USER, POSTGRES_PASSWORD

2. PROBAR CONECTIVIDAD:
   python diagnostic_tool.py

3. EJECUTAR MIGRACIÓN:
   Opción A - Script básico:
     python migration_script.py
   
   Opción B - Script avanzado:
     python advanced_migration.py

4. VERIFICAR RESULTADOS:
   - Revisar archivos de log:
     * migration.log (script básico)
     * migration_detailed.log (script avanzado)
   - Consultar migration_report.json (reporte)

5. VALIDAR DATOS:
   Ejecutar queries SQL en ambas bases de datos para verificar
   que los datos se migraron correctamente.
    """)


def main():
    """Ejecución principal"""
    print_header("INSTALADOR Y CONFIGURADOR DE MIGRACIÓN DE BD")
    
    # 1. Verificar Python
    print("\n1. Verificando versión de Python...")
    if not check_python_version():
        print("Por favor, instala Python 3.8 o superior")
        return 1
    
    # 2. Instalar dependencias
    print("\n2. Instalando dependencias...")
    if not install_requirements():
        print("\n⚠ Advertencia: Algunos paquetes podrían no estar instalados")
        print("Intenta instalar manualmente:")
        print("  pip install -r requirements.txt")
    
    # 3. Verificar importaciones
    if not test_imports():
        print("\n✗ Algunos módulos no pudieron ser importados")
        print("Intenta instalar nuevamente: pip install -r requirements.txt")
        return 1
    
    # 4. Crear archivo de configuración
    print("\n3. Creando archivos de configuración...")
    create_config_template()
    
    # 5. Mostrar siguiente pasos
    print_next_steps()
    
    print_header("INSTALACIÓN COMPLETADA")
    print("\n✓ La herramienta está lista para usar")
    print("  Próximo paso: edita 'credentials.py' con tus datos\n")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
