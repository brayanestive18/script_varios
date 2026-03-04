# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Environment Setup

```bash
python -m venv .venv
source .venv/bin/activate          # macOS/Linux
# .\.venv\Scripts\activate         # Windows
pip install -r requirements.txt
cp .env.example .env               # then fill in credentials
```

## Running Scripts

```bash
# Interactive URL copy between class groups
python copiar_urls_clase.py

# MySQL → PostgreSQL schema converter (edit hardcoded paths inside before running)
python convert_mysql_to_postgres.py

# DB migration menu (MariaDB → PostgreSQL)
cd Mig_DB && python main.py
```

## Docker (MySQL local DB)

```bash
docker-compose up -d       # starts MySQL 8.0 on port 3306, inits with clcerp_190226.sql
docker-compose down
```

The `.env` file supplies credentials to both the Docker container and the Python scripts.

## Architecture

### Root-level scripts
- **copiar_urls_clase.py** — connects via `.env`, interactively copies `url_video` values between class groups with dry-run preview and rollback on failure.
- **convert_mysql_to_postgres.py** — standalone converter; input/output paths are hardcoded Windows absolute paths near the bottom of the file, change them before running.
- **report_dir_documento.py** — reads a CSV of student document IDs (first column), queries DIR attendance, and exports a formatted Excel table. Students not enrolled in any DIR group appear with `'No matriculado en DIR'`. Requires `openpyxl`.

```bash
python report_dir_documento.py alumnos.csv
# optionally pass the output name as second arg:
python report_dir_documento.py alumnos.csv "NombreReporte"
# output: NombreReporte_Report_Dir_YYYYMMDDHHMM.xlsx
```

### Mig_DB/
Full MariaDB → PostgreSQL migration subsystem:
- `credentials.py` — hard-coded DB credentials for source (MariaDB) and target (PostgreSQL).
- `config.py` — migration settings (batch size, log level, continue-on-error).
- `migration_mariadb.py` — the migration engine; handles tables `roles`, `users`, `user_roles`, `profiles`, and related; uses deterministic UUIDs (`det_uuid()`) and several ID-mapping dicts for cross-DB FK resolution.
- `main.py` — interactive menu that delegates to the other scripts.

### SQL reports (root level)
CTE-heavy queries against an ERP schema for an educational institution:
- **DIR groups** — defined by `materia IN (34, 48, 55, 65, 68, 69, 74)`, excluding group IDs `(1174, 294, 516, 519/647)`.
- **Report_DIR_Documento.sql** — attendance % per student in DIR groups; student list hardcoded in `WHERE m.id_alumno IN (...)`. The Python equivalent is `report_dir_documento.py`.
- **Report_ILC_DIR.sql** — cross-report joining each student's ILC group (non-DIR active group) with their DIR attendance. Uses CTEs: `grupos_dir → tc → ac → ilc → dir_mat → per_alumno_grupo`. Students without a DIR group show `'No matriculado en DIR'` in both `grupo_DIR` and `materia_DIR`.

### Database
Schema name: `erp` (Docker) / `ERP_DB_TABLES` (migration source). Key tables referenced in reports: `grupo`, `materia`, `clase`, `asistencia_clase`, `matricula_materia`, `alumno`, `usuario`.
