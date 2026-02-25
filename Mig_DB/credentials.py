# Configuración de migración - ACTUALIZA ESTOS VALORES
# ====================================================

# Credenciales MySQL (ERP_DB_TABLES)
MYSQL_HOST = "localhost"
MYSQL_USER = "root"
MYSQL_PASSWORD = "admin"  # Ingresa tu contraseña
MYSQL_DATABASE = "erp"

# Credenciales PostgreSQL (ALMA_BE_V2)
POSTGRES_HOST = "localhost"
POSTGRES_USER = "postgres"
POSTGRES_PASSWORD = "admin"  # Ingresa tu contraseña
POSTGRES_DATABASE = "almdb"
POSTGRES_PORT = 5432

# Configuración de migración
LOG_LEVEL = "INFO"  # DEBUG, INFO, WARNING, ERROR
BATCH_SIZE = 1000
CONTINUE_ON_ERROR = True
VERIFY_AFTER_MIGRATION = True
