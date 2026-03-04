#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Copia las URLs de video de las clases de un grupo de origen a un grupo de destino.

Este script replica la funcionalidad del SQL 'Copiar URL DIR.sql',
pero de una manera interactiva y más segura, pidiendo confirmación
antes de aplicar los cambios.
"""

import sys
import os
import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

# Cargar variables de entorno desde el archivo .env
load_dotenv()

# --- CONFIGURACIÓN DE LA BASE DE DATOS ---
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'erp')
}
# -----------------------------------------

def get_db_connection():
    """Establece y devuelve una conexión a la base de datos."""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        if conn.is_connected():
            return conn
    except Error as e:
        print(f"Error al conectar a la base de datos: {e}")
        sys.exit(1)

def get_source_urls(cursor, source_group_id, start_id):
    """Obtiene una lista ordenada de URLs del grupo de origen."""
    query = """
        SELECT url_video
        FROM clase
        WHERE grupo = %s
          AND id >= %s
          AND url_video IS NOT NULL
          AND url_video <> ''
        ORDER BY id
    """
    cursor.execute(query, (source_group_id, start_id))
    return [row[0] for row in cursor.fetchall()]

def get_target_classes(cursor, target_group_id, start_id):
    """Obtiene una lista ordenada de IDs de clase del grupo de destino."""
    query = """
        SELECT id, url_video
        FROM clase
        WHERE grupo = %s
          AND id >= %s
        ORDER BY id
    """
    cursor.execute(query, (target_group_id, start_id))
    return cursor.fetchall()

def main():
    """Función principal del script."""
    print("--- Script para Copiar URLs de Video entre Grupos de Clases ---")

    try:
        source_group_id = int(input("Introduce el ID del grupo de ORIGEN: "))
        source_start_id = int(input("Introduce el ID de la clase de ORIGEN desde la cual empezar [ej: 39]: "))
        target_group_id = int(input("Introduce el ID del grupo de DESTINO: "))
        target_start_id = int(input("Introduce el ID de la clase de DESTINO desde la cual empezar [ej: 39]: "))
    except ValueError:
        print("\nError: Los IDs deben ser números enteros.")
        sys.exit(1)

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # 1. Obtener datos de origen y destino
        print("\nObteniendo datos...")
        source_urls = get_source_urls(cursor, source_group_id, source_start_id)
        target_classes = get_target_classes(cursor, target_group_id, target_start_id)

        if not source_urls:
            print(f"No se encontraron URLs de video en el grupo de origen {source_group_id} a partir del ID {source_start_id}.")
            return
        if not target_classes:
            print(f"No se encontraron clases en el grupo de destino {target_group_id} a partir del ID {target_start_id}.")
            return

        print(f"✓ Encontradas {len(source_urls)} URLs en el grupo de origen.")
        print(f"✓ Encontradas {len(target_classes)} clases en el grupo de destino.")

        # 2. Preparar y verificar los cambios (Dry Run)
        num_changes = min(len(source_urls), len(target_classes))
        if len(source_urls) != len(target_classes):
            print("\nADVERTENCIA: El número de clases de origen y destino no coincide.")
            print(f"Se copiarán únicamente las primeras {num_changes} URLs.")

        print("\n--- VISTA PREVIA DE CAMBIOS ---")
        print(f"{'#':<4} {'ID Clase Destino':<18} {'URL Actual':<30} -> {'Nueva URL':<30}")
        print("-" * 90)

        updates_to_perform = []
        for i, (target_class_info, new_url) in enumerate(zip(target_classes, source_urls)):
            target_id, current_url = target_class_info
            print(f"{i+1:<4} {target_id:<18} {str(current_url or 'NULL')[:28]:<30} -> {new_url[:28]:<30}")
            updates_to_perform.append((new_url, target_id, target_group_id))

        print("-" * 90)

        # 3. Confirmación del usuario
        confirm = input(f"\n¿Deseas aplicar estos {num_changes} cambios? (s/n): ").lower()
        if confirm != 's':
            print("Operación cancelada por el usuario.")
            return

        # 4. Ejecutar la actualización
        print("\nAplicando cambios...")
        update_query = "UPDATE clase SET url_video = %s WHERE id = %s AND grupo = %s"
        cursor.executemany(update_query, updates_to_perform)
        conn.commit()
        print(f"✓ ¡Éxito! Se han actualizado {cursor.rowcount} filas en la base de datos.")

    except Error as e:
        print(f"Ha ocurrido un error con la base de datos: {e}")
        conn.rollback()
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()
            print("\nConexión a la base de datos cerrada.")

if __name__ == "__main__":
    main()