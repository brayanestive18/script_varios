#!/usr/bin/env python3
"""
Convierte un archivo SQL de MySQL a PostgreSQL
Maneja conversión de sintaxis, tipos de datos, y collations
"""
import re
import sys
import hashlib

def extract_enums(content):
    """Extrae todos los ENUMs únicos del contenido SQL"""
    enum_pattern = r"enum\('([^']*(?:','[^']*)*)'\)"
    matches = re.findall(enum_pattern, content, re.IGNORECASE)

    enum_map = {}  # Mapea la definición del enum a un nombre de tipo
    enum_counter = 1

    for match in matches:
        # Normalizar: mantener el orden original pero crear un identificador único
        values_str = match

        # Si ya hemos visto este enum exacto, reutilizar el nombre
        if values_str not in enum_map:
            # Generar un nombre basado en los primeros valores
            values_list = [v.strip() for v in match.split("','")]
            # Crear un hash corto para identificar el enum
            hash_obj = hashlib.md5(values_str.encode())
            hash_short = hash_obj.hexdigest()[:8]
            type_name = f'enum_type_{hash_short}'
            enum_map[values_str] = (type_name, values_list)

    return enum_map

def create_enum_types(enum_map):
    """Crea las sentencias CREATE TYPE para PostgreSQL"""
    type_definitions = []

    for values_str, (type_name, values_list) in enum_map.items():
        values_formatted = ', '.join([f"'{v}'" for v in values_list])
        # Usar DROP TYPE IF EXISTS para evitar errores si el tipo ya existe
        drop_stmt = f"DROP TYPE IF EXISTS {type_name} CASCADE;"
        create_stmt = f"CREATE TYPE {type_name} AS ENUM ({values_formatted});"
        type_definitions.append(drop_stmt)
        type_definitions.append(create_stmt)

    return type_definitions

def convert_line(line):
    """Convierte una línea de MySQL a PostgreSQL"""

    # Remover backticks
    line = line.replace('`', '')

    # Convertir escapes de MySQL a PostgreSQL (standard_conforming_strings = on)
    # Orden: primero \\ -> placeholder, luego \' -> '', luego placeholder -> \
    line = line.replace('\\\\', '\x00BSLASH\x00')
    line = line.replace("\\'", "''")
    line = line.replace('\x00BSLASH\x00', '\\')

    # Convertir fechas inválidas de MySQL a NULL (PostgreSQL no acepta 0000-00-00)
    line = line.replace("'0000-00-00 00:00:00'", "NULL")
    line = line.replace("'0000-00-00'", "NULL")

    # Comentar comandos condicionales específicos de MySQL (/*!...*/)
    line = re.sub(r'/\*!\d+\s+(.*?)\s*\*/', r'-- \1', line, flags=re.IGNORECASE)

    # Convertir comandos SET de MySQL a PostgreSQL
    line = re.sub(r'\bSET\s+time_zone\s*=', 'SET timezone =', line, flags=re.IGNORECASE)
    line = re.sub(r'\bSET\s+sql_mode\s*=', '-- SET sql_mode =', line, flags=re.IGNORECASE)
    line = re.sub(r'\bSET\s+FOREIGN_KEY_CHECKS\s*=', '-- SET FOREIGN_KEY_CHECKS =', line, flags=re.IGNORECASE)
    line = re.sub(r'\bSET\s+UNIQUE_CHECKS\s*=', '-- SET UNIQUE_CHECKS =', line, flags=re.IGNORECASE)
    line = re.sub(r'\bSET\s+AUTOCOMMIT\s*=', '-- SET AUTOCOMMIT =', line, flags=re.IGNORECASE)
    line = re.sub(r'\bSET\s+@@', '-- SET @@', line, flags=re.IGNORECASE)
    line = re.sub(r'\bSET\s+@', '-- SET @', line, flags=re.IGNORECASE)

    # Eliminar COLLATE utf8mb4_unicode_ci y COLLATE utf8mb3_spanish_ci
    line = re.sub(r'\s+COLLATE\s+utf8mb4_unicode_ci', '', line, flags=re.IGNORECASE)
    line = re.sub(r'\s+COLLATE\s+utf8mb3_spanish_ci', '', line, flags=re.IGNORECASE)
    line = re.sub(r'\s+COLLATE\s+utf8mb3_general_ci', '', line, flags=re.IGNORECASE)
    line = re.sub(r'\s+COLLATE\s+[\w_]+', '', line, flags=re.IGNORECASE)

    # Eliminar CHARACTER SET
    line = re.sub(r'\s+CHARACTER\s+SET\s+utf8mb4', '', line, flags=re.IGNORECASE)
    line = re.sub(r'\s+CHARACTER\s+SET\s+utf8mb3', '', line, flags=re.IGNORECASE)
    line = re.sub(r'\s+CHARACTER\s+SET\s+utf8', '', line, flags=re.IGNORECASE)
    line = re.sub(r'\s+CHARACTER\s+SET\s+[\w_]+', '', line, flags=re.IGNORECASE)

    # Eliminar ENGINE=InnoDB y DEFAULT CHARSET al final de CREATE TABLE
    # IMPORTANTE: Mantener el paréntesis de cierre )
    # Con COMMENT
    line = re.sub(r'\)\s+ENGINE\s*=\s*InnoDB\s+DEFAULT\s+CHARSET\s*=\s*\w+(\s+COLLATE\s*=\s*\w+)?(\s+ROW_FORMAT\s*=\s*\w+)?(\s+COMMENT\s*=\s*\'[^\']*\')?;', lambda m: ')' + (m.group(3) if m.group(3) else '') + ';', line, flags=re.IGNORECASE)
    line = re.sub(r'\)\s+ENGINE\s*=\s*MyISAM\s+DEFAULT\s+CHARSET\s*=\s*\w+(\s+COLLATE\s*=\s*\w+)?(\s+ROW_FORMAT\s*=\s*\w+)?(\s+COMMENT\s*=\s*\'[^\']*\')?;', lambda m: ')' + (m.group(3) if m.group(3) else '') + ';', line, flags=re.IGNORECASE)
    # Sin DEFAULT CHARSET pero con ENGINE
    line = re.sub(r'\)\s+ENGINE\s*=\s*InnoDB(\s+ROW_FORMAT\s*=\s*\w+)?(\s+COMMENT\s*=\s*\'[^\']*\')?;', lambda m: ')' + (m.group(2) if m.group(2) else '') + ';', line, flags=re.IGNORECASE)
    line = re.sub(r'\)\s+ENGINE\s*=\s*MyISAM(\s+ROW_FORMAT\s*=\s*\w+)?(\s+COMMENT\s*=\s*\'[^\']*\')?;', lambda m: ')' + (m.group(2) if m.group(2) else '') + ';', line, flags=re.IGNORECASE)
    # Solo DEFAULT CHARSET
    line = re.sub(r'\)\s+DEFAULT\s+CHARSET\s*=\s*\w+(\s+COLLATE\s*=\s*\w+)?(\s+COMMENT\s*=\s*\'[^\']*\')?;', lambda m: ')' + (m.group(2) if m.group(2) else '') + ';', line, flags=re.IGNORECASE)

    # Limpiar casos donde el COMMENT quedó pero necesita espacio
    line = re.sub(r'\)\s*COMMENT\s*=', ') -- COMMENT:', line, flags=re.IGNORECASE)

    # Eliminar COMMENT 'texto' en definiciones de columnas (PostgreSQL no soporta inline COMMENT)
    line = re.sub(r"\s+COMMENT\s+'[^']*'", '', line, flags=re.IGNORECASE)

    # Convertir tipos de datos
    # tinyint(1) -> BOOLEAN (debe ser ANTES de la conversión general de tinyint)
    line = re.sub(r'\btinyint\(1\)', 'BOOLEAN', line, flags=re.IGNORECASE)

    # Convertir DEFAULT '0' y DEFAULT '1' a DEFAULT false/true para BOOLEAN
    # Esto debe hacerse DESPUÉS de convertir tinyint(1) a BOOLEAN
    if 'BOOLEAN' in line:
        line = re.sub(r"BOOLEAN\s+(NOT\s+NULL\s+)?DEFAULT\s+'0'", r"BOOLEAN \1DEFAULT false", line, flags=re.IGNORECASE)
        line = re.sub(r"BOOLEAN\s+(NOT\s+NULL\s+)?DEFAULT\s+'1'", r"BOOLEAN \1DEFAULT true", line, flags=re.IGNORECASE)
        line = re.sub(r'BOOLEAN\s+(NOT\s+NULL\s+)?DEFAULT\s+"0"', r"BOOLEAN \1DEFAULT false", line, flags=re.IGNORECASE)
        line = re.sub(r'BOOLEAN\s+(NOT\s+NULL\s+)?DEFAULT\s+"1"', r"BOOLEAN \1DEFAULT true", line, flags=re.IGNORECASE)

    # tinyint UNSIGNED -> SMALLINT
    line = re.sub(r'\btinyint\s+UNSIGNED\b', 'SMALLINT', line, flags=re.IGNORECASE)

    # tinyint -> SMALLINT
    line = re.sub(r'\btinyint(?:\(\d+\))?\b', 'SMALLINT', line, flags=re.IGNORECASE)

    # Remover parámetros de tamaño de SMALLINT (PostgreSQL no los acepta)
    line = re.sub(r'\bSMALLINT\(\d+\)\b', 'SMALLINT', line, flags=re.IGNORECASE)

    # Remover parámetros de tamaño de INTEGER
    line = re.sub(r'\bINTEGER\(\d+\)\b', 'INTEGER', line, flags=re.IGNORECASE)
    line = re.sub(r'\bint\(\d+\)\b', 'INTEGER', line, flags=re.IGNORECASE)

    # smallint UNSIGNED -> INTEGER
    line = re.sub(r'\bsmallint\s+UNSIGNED\b', 'INTEGER', line, flags=re.IGNORECASE)

    # mediumint UNSIGNED -> INTEGER
    line = re.sub(r'\bmediumint\s+UNSIGNED\b', 'INTEGER', line, flags=re.IGNORECASE)

    # mediumint -> INTEGER
    line = re.sub(r'\bmediumint(?:\(\d+\))?\b', 'INTEGER', line, flags=re.IGNORECASE)

    # int UNSIGNED -> BIGINT
    line = re.sub(r'\bint\s+UNSIGNED\b', 'BIGINT', line, flags=re.IGNORECASE)

    # bigint UNSIGNED -> BIGINT (PostgreSQL no tiene UNSIGNED, pero BIGINT es suficientemente grande)
    line = re.sub(r'\bbigint\s+UNSIGNED\b', 'BIGINT', line, flags=re.IGNORECASE)

    # decimal/numeric UNSIGNED -> decimal/numeric (PostgreSQL no tiene UNSIGNED)
    line = re.sub(r'\bdecimal\(([^)]+)\)\s+UNSIGNED\b', r'DECIMAL(\1)', line, flags=re.IGNORECASE)
    line = re.sub(r'\bnumeric\(([^)]+)\)\s+UNSIGNED\b', r'NUMERIC(\1)', line, flags=re.IGNORECASE)
    line = re.sub(r'\bfloat\s+UNSIGNED\b', 'FLOAT', line, flags=re.IGNORECASE)
    line = re.sub(r'\bdouble\s+PRECISION\s+UNSIGNED\b', 'DOUBLE PRECISION', line, flags=re.IGNORECASE)

    # datetime -> TIMESTAMP
    line = re.sub(r'\bdatetime\b', 'TIMESTAMP', line, flags=re.IGNORECASE)

    # timestamp NULL DEFAULT NULL -> TIMESTAMPTZ DEFAULT NULL
    line = re.sub(r'\btimestamp\s+NULL\s+DEFAULT\s+NULL\b', 'TIMESTAMPTZ DEFAULT NULL', line, flags=re.IGNORECASE)
    line = re.sub(r'\btimestamp\b', 'TIMESTAMPTZ', line, flags=re.IGNORECASE)

    # varchar sin tamaño específico -> TEXT
    # Pero mantener varchar con tamaño

    # blob -> BYTEA
    line = re.sub(r'\bblob\b', 'BYTEA', line, flags=re.IGNORECASE)
    line = re.sub(r'\btinyblob\b', 'BYTEA', line, flags=re.IGNORECASE)
    line = re.sub(r'\bmediumblob\b', 'BYTEA', line, flags=re.IGNORECASE)
    line = re.sub(r'\blongblob\b', 'BYTEA', line, flags=re.IGNORECASE)

    # text types -> TEXT
    line = re.sub(r'\btinytext\b', 'TEXT', line, flags=re.IGNORECASE)
    line = re.sub(r'\bmediumtext\b', 'TEXT', line, flags=re.IGNORECASE)
    line = re.sub(r'\blongtext\b', 'TEXT', line, flags=re.IGNORECASE)

    # double -> DOUBLE PRECISION
    line = re.sub(r'\bdouble\b', 'DOUBLE PRECISION', line, flags=re.IGNORECASE)

    # AUTO_INCREMENT -> (se maneja con SERIAL o IDENTITY, pero necesita más contexto)
    # Por ahora lo removemos y dejamos que se maneje con sequences
    line = re.sub(r'\s+AUTO_INCREMENT\b', '', line, flags=re.IGNORECASE)

    # Remover ON UPDATE CURRENT_TIMESTAMP (no soportado directamente en PostgreSQL)
    line = re.sub(r'\s+ON\s+UPDATE\s+CURRENT_TIMESTAMP\b', '', line, flags=re.IGNORECASE)

    # Convertir NOW() a CURRENT_TIMESTAMP en defaults
    # line = re.sub(r'\bNOW\(\)', 'CURRENT_TIMESTAMP', line, flags=re.IGNORECASE)

    # Remover comentarios de índices únicos de MySQL (UNIQUE KEY `nombre`)
    # Esto es complicado porque PostgreSQL usa sintaxis diferente
    # Por ahora lo dejamos, pero se puede mejorar

    # ROW_FORMAT=COMPACT y similares
    line = re.sub(r'\s+ROW_FORMAT\s*=\s*\w+', '', line, flags=re.IGNORECASE)

    # Eliminar USING BTREE/HASH en definiciones de claves (PostgreSQL no lo usa así)
    line = re.sub(r'\s+USING\s+BTREE\b', '', line, flags=re.IGNORECASE)
    line = re.sub(r'\s+USING\s+HASH\b', '', line, flags=re.IGNORECASE)

    # Comentar ADD KEY (no ADD PRIMARY KEY ni ADD UNIQUE KEY) porque PostgreSQL usa CREATE INDEX
    # Solo comentar si la línea contiene "ADD KEY" pero NO "ADD PRIMARY KEY" ni "ADD UNIQUE KEY"
    if re.search(r'\bADD\s+KEY\s+\w+', line, re.IGNORECASE):
        if not re.search(r'\bADD\s+(PRIMARY|UNIQUE)\s+KEY', line, re.IGNORECASE):
            # Comentar esta línea
            line = '-- ' + line

    return line


def split_sql_values(s):
    """Split comma-separated SQL values, respecting quoted strings."""
    values = []
    current = []
    in_string = False
    string_char = None
    i = 0

    while i < len(s):
        ch = s[i]
        if in_string:
            current.append(ch)
            if ch == '\\':
                if i + 1 < len(s):
                    i += 1
                    current.append(s[i])
            elif ch == string_char:
                if i + 1 < len(s) and s[i + 1] == string_char:
                    i += 1
                    current.append(s[i])
                else:
                    in_string = False
        elif ch in ("'", '"'):
            in_string = True
            string_char = ch
            current.append(ch)
        elif ch == ',':
            values.append(''.join(current))
            current = []
        else:
            current.append(ch)
        i += 1

    if current:
        values.append(''.join(current))
    return values


def find_closing_paren(s, start):
    """Find the closing ) matching the ( at position start, respecting strings."""
    depth = 0
    in_string = False
    string_char = None
    i = start

    while i < len(s):
        ch = s[i]
        if in_string:
            if ch == '\\':
                i += 1
            elif ch == string_char:
                if i + 1 < len(s) and s[i + 1] == string_char:
                    i += 1
                else:
                    in_string = False
        elif ch in ("'", '"'):
            in_string = True
            string_char = ch
        elif ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def fix_value_tuples_in_line(line, bool_indices):
    """Fix value tuples in a line, converting 0/1 to FALSE/TRUE at boolean positions."""
    result = []
    i = 0

    while i < len(line):
        paren_start = line.find('(', i)
        if paren_start == -1:
            result.append(line[i:])
            break

        result.append(line[i:paren_start])
        paren_end = find_closing_paren(line, paren_start)
        if paren_end == -1:
            result.append(line[paren_start:])
            break

        inner = line[paren_start + 1:paren_end]
        values = split_sql_values(inner)

        for j in bool_indices:
            if j < len(values):
                val = values[j].strip()
                if val == '0':
                    values[j] = values[j].replace('0', 'FALSE', 1)
                elif val == '1':
                    values[j] = values[j].replace('1', 'TRUE', 1)

        result.append('(')
        result.append(','.join(values))
        result.append(')')
        i = paren_end + 1

    return ''.join(result)


def extract_boolean_columns(lines):
    """Scan converted lines to find which columns are BOOLEAN per table."""
    boolean_cols = {}
    current_table = None

    for line in lines:
        stripped = line.strip()

        match = re.match(r'^CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\S+)', stripped, re.IGNORECASE)
        if match:
            current_table = match.group(1).rstrip('(').strip()
            boolean_cols[current_table] = set()
            continue

        if current_table is None:
            continue

        if stripped.startswith(')'):
            if not boolean_cols.get(current_table):
                boolean_cols.pop(current_table, None)
            current_table = None
            continue

        if re.match(r'^(PRIMARY\s+KEY|UNIQUE\s+KEY|UNIQUE\s*\(|KEY\s|CONSTRAINT\s|INDEX\s|FOREIGN\s+KEY)', stripped, re.IGNORECASE):
            continue

        if stripped.startswith('--') or not stripped:
            continue

        col_match = re.match(r'^(\w+)\s+BOOLEAN\b', stripped, re.IGNORECASE)
        if col_match:
            boolean_cols[current_table].add(col_match.group(1).lower())

    return boolean_cols


def fix_insert_boolean_values(lines, boolean_cols):
    """Fix INSERT statements to use TRUE/FALSE instead of 0/1 for boolean columns."""
    if not boolean_cols:
        return

    current_bool_indices = []
    in_insert = False

    for i in range(len(lines)):
        line = lines[i]
        stripped = line.strip()

        insert_match = re.match(
            r'^INSERT\s+INTO\s+(\S+)\s*\(([^)]+)\)\s*VALUES',
            stripped, re.IGNORECASE
        )
        if insert_match:
            table_name = insert_match.group(1).strip()
            in_insert = False
            current_bool_indices = []

            if table_name in boolean_cols:
                columns = [c.strip().lower() for c in insert_match.group(2).split(',')]
                current_bool_indices = [j for j, col in enumerate(columns) if col in boolean_cols[table_name]]
                if current_bool_indices:
                    in_insert = True
                    # Check if value tuples start on this same line (after VALUES)
                    values_match = re.search(r'\bVALUES\b', line, re.IGNORECASE)
                    if values_match:
                        after_pos = values_match.end()
                        if line[after_pos:].strip().startswith('('):
                            prefix = line[:after_pos]
                            suffix = line[after_pos:]
                            lines[i] = prefix + fix_value_tuples_in_line(suffix, current_bool_indices)
            continue

        if in_insert and current_bool_indices:
            if stripped.startswith('('):
                lines[i] = fix_value_tuples_in_line(line, current_bool_indices)
            if stripped.endswith(';'):
                in_insert = False
                current_bool_indices = []


def extract_enum_columns(lines):
    """Scan converted lines to find which columns use an enum type per table."""
    enum_cols = {}
    current_table = None

    for line in lines:
        stripped = line.strip()

        match = re.match(r'^CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\S+)', stripped, re.IGNORECASE)
        if match:
            current_table = match.group(1).rstrip('(').strip()
            enum_cols[current_table] = set()
            continue

        if current_table is None:
            continue

        if stripped.startswith(')'):
            if not enum_cols.get(current_table):
                enum_cols.pop(current_table, None)
            current_table = None
            continue

        if re.match(r'^(PRIMARY\s+KEY|UNIQUE\s+KEY|UNIQUE\s*\(|KEY\s|CONSTRAINT\s|INDEX\s|FOREIGN\s+KEY)', stripped, re.IGNORECASE):
            continue

        if stripped.startswith('--') or not stripped:
            continue

        col_match = re.match(r'^(\w+)\s+enum_type_\w+', stripped, re.IGNORECASE)
        if col_match:
            enum_cols[current_table].add(col_match.group(1).lower())

    return enum_cols


def fix_insert_enum_values(lines, enum_cols):
    """Fix INSERT statements to convert empty strings to NULL for enum columns."""
    if not enum_cols:
        return

    current_enum_indices = []
    in_insert = False

    for i in range(len(lines)):
        line = lines[i]
        stripped = line.strip()

        insert_match = re.match(
            r'^INSERT\s+INTO\s+(\S+)\s*\(([^)]+)\)\s*VALUES',
            stripped, re.IGNORECASE
        )
        if insert_match:
            table_name = insert_match.group(1).strip()
            in_insert = False
            current_enum_indices = []

            if table_name in enum_cols:
                columns = [c.strip().lower() for c in insert_match.group(2).split(',')]
                current_enum_indices = [j for j, col in enumerate(columns) if col in enum_cols[table_name]]
                if current_enum_indices:
                    in_insert = True
                    values_match = re.search(r'\bVALUES\b', line, re.IGNORECASE)
                    if values_match:
                        after_pos = values_match.end()
                        if line[after_pos:].strip().startswith('('):
                            prefix = line[:after_pos]
                            suffix = line[after_pos:]
                            lines[i] = prefix + fix_enum_tuples_in_line(suffix, current_enum_indices)
            continue

        if in_insert and current_enum_indices:
            if stripped.startswith('('):
                lines[i] = fix_enum_tuples_in_line(line, current_enum_indices)
            if stripped.endswith(';'):
                in_insert = False
                current_enum_indices = []


def fix_enum_tuples_in_line(line, enum_indices):
    """Fix value tuples in a line, converting empty strings to NULL at enum positions."""
    result = []
    i = 0

    while i < len(line):
        paren_start = line.find('(', i)
        if paren_start == -1:
            result.append(line[i:])
            break

        result.append(line[i:paren_start])
        paren_end = find_closing_paren(line, paren_start)
        if paren_end == -1:
            result.append(line[paren_start:])
            break

        inner = line[paren_start + 1:paren_end]
        values = split_sql_values(inner)

        for j in enum_indices:
            if j < len(values):
                val = values[j].strip()
                if val == "''" or val == '""':
                    values[j] = ' NULL'

        result.append('(')
        result.append(','.join(values))
        result.append(')')
        i = paren_end + 1

    return ''.join(result)


def convert_file(input_file, output_file):
    """Convierte el archivo completo"""
    print(f"Convirtiendo {input_file} a {output_file}...")

    # Leer el contenido completo primero para extraer ENUMs
    with open(input_file, 'r', encoding='utf-8', errors='replace') as infile:
        original_content = infile.read()

    print("Extrayendo definiciones de ENUM...")
    enum_map = extract_enums(original_content)
    print(f"Encontrados {len(enum_map)} tipos ENUM únicos")

    # Crear las definiciones de tipos ENUM
    enum_definitions = create_enum_types(enum_map)

    line_count = 0
    lines = []

    # Primera pasada: convertir todas las líneas
    print("Convirtiendo líneas...")
    with open(input_file, 'r', encoding='utf-8', errors='replace') as infile:
        for line in infile:
            converted_line = convert_line(line)

            # Insertar DROP TABLE IF EXISTS antes de cada CREATE TABLE
            match = re.match(r'^CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\S+)', converted_line, re.IGNORECASE)
            if match:
                table_name = match.group(1).rstrip('(').strip()
                lines.append(f'DROP TABLE IF EXISTS {table_name} CASCADE;\n')

            lines.append(converted_line)
            line_count += 1

            if line_count % 100000 == 0:
                print(f"Procesadas {line_count:,} líneas...")

    print(f"Líneas convertidas, ahora reemplazando ENUMs...")

    # Segunda pasada: reemplazar definiciones de ENUM con nombres de tipos
    for i in range(len(lines)):
        line = lines[i]
        # Buscar y reemplazar definiciones de enum inline
        for values_str, (type_name, _) in enum_map.items():
            pattern = f"enum('{values_str}')"
            if pattern.lower() in line.lower():
                # Reemplazar manteniendo mayúsculas/minúsculas
                lines[i] = re.sub(r"enum\('[^']*(?:','[^']*)*'\)", type_name, line, flags=re.IGNORECASE)
                break

    print(f"ENUMs reemplazados, ahora corrigiendo comas...")

    # Tercera pasada: corregir comas antes de líneas comentadas con ADD KEY
    for i in range(len(lines) - 1):
        current_line = lines[i].rstrip()

        # Si la línea actual termina con coma y contiene ADD (PRIMARY KEY, UNIQUE KEY, CONSTRAINT, etc.)
        if current_line.endswith(',') and 'ADD' in current_line and not current_line.strip().startswith('--'):
            # Buscar la siguiente línea no vacía
            next_idx = i + 1
            while next_idx < len(lines) and lines[next_idx].strip() == '':
                next_idx += 1

            if next_idx < len(lines):
                next_line = lines[next_idx].strip()

                # Si la siguiente línea es un ADD KEY comentado, o es un comentario de sección, o es el inicio de otra tabla
                if (next_line.startswith('--') and 'ADD KEY' in next_line) or \
                   (next_line.startswith('--') and 'ADD KEY' not in next_line and 'ADD CONSTRAINT' not in next_line):
                    # Reemplazar la coma final por punto y coma
                    lines[i] = current_line[:-1] + ';\n'

    # Cuarta pasada: corregir valores booleanos en INSERT (0/1 -> FALSE/TRUE)
    print("Extrayendo columnas BOOLEAN de CREATE TABLE...")
    boolean_cols = extract_boolean_columns(lines)
    print(f"Tablas con columnas BOOLEAN: {len(boolean_cols)}")
    print("Corrigiendo valores booleanos en INSERT...")
    fix_insert_boolean_values(lines, boolean_cols)

    # Quinta pasada: corregir valores vacíos en columnas ENUM ('' -> NULL)
    print("Extrayendo columnas ENUM de CREATE TABLE...")
    enum_cols = extract_enum_columns(lines)
    print(f"Tablas con columnas ENUM: {len(enum_cols)}")
    print("Corrigiendo valores vacíos en INSERT para columnas ENUM...")
    fix_insert_enum_values(lines, enum_cols)

    print("Insertando definiciones de tipos ENUM...")

    # Insertar las definiciones de ENUM después de "SET timezone"
    insert_index = -1
    for i, line in enumerate(lines):
        if 'SET timezone' in line:
            insert_index = i + 1
            # Saltar líneas vacías
            while insert_index < len(lines) and lines[insert_index].strip() == '':
                insert_index += 1
            break

    if insert_index > 0 and enum_definitions:
        # Insertar comentario y definiciones
        enum_block = ['\n', '--\n', '-- Definiciones de tipos ENUM para PostgreSQL\n', '--\n', '\n']
        for enum_def in enum_definitions:
            enum_block.append(enum_def + '\n')
        enum_block.append('\n')

        lines[insert_index:insert_index] = enum_block

    # Insertar preámbulo de PostgreSQL al inicio del archivo (sin transacción para que cada statement haga commit independiente)
    preamble = [
        '-- Preámbulo para importación segura en PostgreSQL\n',
        'SET client_encoding = \'UTF8\';\n',
        'SET session_replication_role = \'replica\';\n',
        '\n',
    ]
    lines[0:0] = preamble

    # Agregar restauración al final
    epilogue = [
        '\n',
        '-- Restaurar configuración\n',
        'SET session_replication_role = \'origin\';\n',
    ]
    lines.extend(epilogue)

    # Escribir el archivo final
    with open(output_file, 'w', encoding='utf-8') as outfile:
        outfile.writelines(lines)

    print(f"Conversión completada! Total de líneas: {len(lines):,}")
    print(f"Archivo guardado en: {output_file}")

if __name__ == "__main__":
    input_file = r"C:\Users\Brayan Diaz\Documents\PersonalRepos\DB_ALMA_V2\ALMA_19022026.sql"
    output_file = r"C:\Users\Brayan Diaz\Documents\PersonalRepos\DB_ALMA_V2\ALMA_19022026_postgres.sql"

    convert_file(input_file, output_file)
    print("\n¡Conversión exitosa!")
    print("\nNotas importantes:")
    print("- Se han eliminado todas las referencias a COLLATE de MySQL")
    print("- Se han convertido los tipos de datos a equivalentes de PostgreSQL")
    print("- Se han eliminado ENGINE y DEFAULT CHARSET")
    print("- Los ENUMs se mantienen (PostgreSQL soporta ENUM)")
    print("- Revisa las claves foráneas y restricciones si es necesario")
    print("- Puede que necesites crear los tipos ENUM antes de ejecutar el script")
