# 🚀 SOLUCIÓN AL PROBLEMA: No da conexión con MariaDB

## Lo que se ha creado

Se han creado **herramientas especializadas** para solucionar tu problema de conexión a MariaDB (`jdbc:mariadb://localhost:3306/erp`).

---

## 🎯 COMIENZA AQUÍ (3 comandos)

### 1️⃣ Instalar (`1 minuto`)

```bash
cd "c:\Users\Brayan Diaz\Documents\PersonalRepos\DB_ALMA_V2\Mig_DB"
pip install mysql-connector-python
```

### 2️⃣ Probar conexión (`1 minuto`)

```bash
python test_mariadb.py
```

**Si ves ✓ (éxito):** Salta al paso 3  
**Si ves ✗ (error):** Lee la solución específica

### 3️⃣ Migrar datos (`5-30 minutos según volumen`)

```bash
python migration_mariadb.py
```

---

## 📊 Nuevas herramientas creadas

| Herramienta | Propósito | Usar si... |
|---|---|---|
| **test_mariadb.py** | Test rápido automático | No sabes si MariaDB funciona |
| **diagnostic_tool_mejorado.py** | Diagnóstico profesional | test_mariadb.py falla |
| **migration_mariadb.py** | Migración especializada | Conexión funciona |
| **SOLUCION_MARIADB.md** | Guía de troubleshooting | test_mariadb.py falla |
| **INICIO_MARIADB.md** | Guía rápida 3 pasos | Quieres empezar rápido |

---

## 📋 Selecciona tu situación

### Situación A: "No sé si MariaDB está corriendo"

```bash
# Ejecuta esto primero
python test_mariadb.py
```

Ver resultados esperados abajo ⬇️

### Situación B: "Tengo error de conexión"

```bash
# Obtén diagnóstico detallado
python diagnostic_tool_mejorado.py
```

Luego revisa [SOLUCION_MARIADB.md](SOLUCION_MARIADB.md) para el error específico

### Situación C: "La conexión funciona, migrar datos"

```bash
# Ejecutar migración
python migration_mariadb.py
```

---

## 📍 Resultados esperados

### ✅ Si es ÉXITO en test_mariadb.py:

```
✓ ¡ÉXITO! Conectado correctamente
  Versión: 10.6.x-MariaDB
  Base de datos actual: erp
  Tablas: 85
  Primera tabla: roles
═══════════════════════════
CONFIGURACIÓN EXITOSA:
═══════════════════════════
Config para migration_mariadb.py:

    MARIADB_HOST = "localhost"
    MARIADB_PORT = 3306
    MARIADB_USER = "root"
    MARIADB_PASSWORD = "..."
    MARIADB_DATABASE = "erp"
```

**Acción siguiente:** Ejecuta `python migration_mariadb.py`

---

### ❌ Si es ERROR en test_mariadb.py:

```
Intento: MariaDB Local (puerto 3306)
  → Conectando a localhost:3306...
  ✗ Error #2003: Can't connect to MySQL server on 'localhost'
    → No se puede conectar (¿MariaDB está corriendo?)
```

**Acciones:**
1. Abrir **Services** (`Win+R` → `services.msc`)
2. Buscar **MariaDB MySQL** → Verificar que esté **Running**
3. Si no está running: Click derecho → **Start**
4. Reintentar: `python test_mariadb.py`

---

### ⚠️ Si es ERROR 1045 (Access denied):

```
✗ Error #1045: Access denied for user 'root'
  → Acceso denegado (usuario/contraseña)
```

**Acciones:**
1. Probar conexión desde CMD:
   ```bash
   mysql -h localhost -u root -p
   # Presiona Enter cuando pida contraseña
   ```

2. Si aún falla: Ver sección "Resetear contraseña" en [SOLUCION_MARIADB.md](SOLUCION_MARIADB.md)

---

## 🚨 Errores comunes y soluciones

| Error | Causa | Solución |
|-------|-------|---------|
| **#2003** | MariaDB no está corriendo | Abre Services y verifica MariaDB |
| **#1045** | Usuario/Contraseña incorrecta | Usa contraseña correcta o resetea |
| **#1049** | Base de datos no existe | Crear con `CREATE DATABASE erp;` |

---

## 📚 Documentación completa

- 📖 **INICIO_MARIADB.md** - Guía de 3 pasos rápidos
- 📖 **SOLUCION_MARIADB.md** - Troubleshooting completo por error
- 📖 **HERRAMIENTAS_MARIADB.md** - Descripción de todas las herramientas

---

## 🔧 Si nada funciona

### Opción nuclear 1: Reinstalar MariaDB
```bash
# Desinstalar completamente y reinstalar desde
https://mariadb.org/download/
```

### Opción nuclear 2: Usar Docker
```bash
docker run --name mariadb -e MYSQL_ROOT_PASSWORD=root -p 3306:3306 -d mariadb:latest
```

---

## ✅ Checklist final

- [ ] Ejecuté `python test_mariadb.py` ✓
- [ ] Vi "¡ÉXITO!" en la salida
- [ ] Ejecuté `python migration_mariadb.py`
- [ ] Migración completada sin errores

---

## 💬 Resumen

**Antes:** No sabías conectar a MariaDB  
**Ahora:** Tienes herramientas para diagnosticar y migrar

**Próximo paso:** Ejecuta `python test_mariadb.py`

---

**¿Problemas?** Consulta [SOLUCION_MARIADB.md](SOLUCION_MARIADB.md)

---

*Archivos nuevos en el directorio Mig_DB:*
- ✨ test_mariadb.py
- ✨ diagnostic_tool_mejorado.py
- ✨ migration_mariadb.py
- ✨ INICIO_MARIADB.md
- ✨ SOLUCION_MARIADB.md
- ✨ HERRAMIENTAS_MARIADB.md
