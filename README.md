# Scripts Varios

Colección de scripts de utilidad para gestión de base de datos y otras tareas.

## Opción 1: Configuración Manual del Entorno

Para evitar conflictos entre dependencias de diferentes proyectos, se recomienda utilizar un entorno virtual (**venv**) para cada proyecto. Esto aísla las librerías que instalas aquí del resto de tu sistema.

### Prerrequisitos
- Python 3.8+
- MariaDB instalado localmente.

Abre tu terminal, navega a la carpeta del proyecto y ejecuta:

```bash
python3 -m venv .venv
```

Esto creará una carpeta oculta `.venv` que contiene el entorno aislado.

### 1.2. Activar el entorno

Debes activar el entorno cada vez que vayas a trabajar en el proyecto.

*   **En macOS / Linux:**
    ```bash
    source .venv/bin/activate
    ```

*   **En Windows (CMD / PowerShell):**
    ```bash
    .\.venv\Scripts\activate
    ```

Sabrás que está activo porque verás `(.venv)` al inicio de tu línea de comandos.

### 1.3. Instalar dependencias

Con el entorno activo, instala las librerías necesarias listadas en `requirements.txt`:

```bash
pip install -r requirements.txt
```

### 4. Configuración

Asegúrate de crear un archivo `.env` en la raíz del proyecto con tus credenciales (puedes usar `.env.example` como guía si existiera, o definir las variables `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`).

### 5. Desactivar el entorno

Cuando termines de trabajar, puedes salir del entorno virtual ejecutando:

```bash
deactivate
```
