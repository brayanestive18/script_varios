# Configuración de bases de datos para la migración
# Actualiza estos valores con tus credenciales reales

MYSQL_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'tu_password_mysql',  # Cambiar por tu contraseña
    'database': 'ERP_DB_TABLES',
    'raise_on_warnings': True,
    'charset': 'utf8mb4',
}

POSTGRES_CONFIG = {
    'host': 'localhost',
    'user': 'postgres',
    'password': 'tu_password_postgres',  # Cambiar por tu contraseña
    'database': 'ALMA_BE_V2',
    'port': 5432
}

# Configuración de migración
MIGRATION_SETTINGS = {
    'batch_size': 1000,  # Número de registros a procesar por lote
    'skip_validation': False,  # Validar integridad referencial
    'log_level': 'INFO',
    'continue_on_error': True,  # Continuar si hay errores
}

# Mapeos personalizados de tablas (si aplica transformaciones especiales)
CUSTOM_MAPPINGS = {
    # Ejemplo:
    # 'source_table': {
    #     'target_table': 'target_table',
    #     'skip': False,
    # }
}
