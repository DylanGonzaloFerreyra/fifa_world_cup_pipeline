FROM apache/airflow:2.7.3-python3.8

# --- 1. INSTALACIÓN DE SISTEMA Y PYTHON (COMO USUARIO root) ---
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev gcc netcat-openbsd git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instalación de dependencias de Python (Globalmente para resolver ModuleNotFoundError)
RUN pip install --no-cache-dir \
    apache-airflow-providers-postgres \
    dbt-core \
    dbt-postgres \
    dbt-airflow \
    pandas \
    beautifulsoup4 \
    psycopg2 \
    requests \
    "poetry==1.8.3" # Instalamos Poetry globalmente

# --- 2. CONFIGURACIÓN DE POETRY Y COPIA (Ajustadas a tu proyecto) ---
ENV POETRY_HOME="/opt/poetry" \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=false
ENV PATH="$POETRY_HOME/bin:$PATH"

WORKDIR /opt/airflow

# ¡CORRECCIÓN CRÍTICA DE COPIA!
# Copiamos los archivos de Poetry desde la carpeta 'project_code/' a la raíz de trabajo.
COPY project_code/pyproject.toml project_code/poetry.lock* ./

# Copia de DAGs y transforms
COPY ./dags/ ./dags/
COPY ./dags/transforms/ ./dags/transforms/

# Asumo que profiles.yml está siendo manejado correctamente, si está en el nivel superior, lo copiamos:
# Si tu profiles.yml está siendo montado por docker-compose o copiado de otro lugar, puedes omitir la siguiente línea.
# Si está en la raíz de tu proyecto local:
COPY profiles.yml /home/airflow/.dbt/profiles.yml


# --- 3. INSTALACIÓN DE DEPENDENCIAS DEL PROYECTO (Como airflow) ---
USER airflow
# Esto instala el resto de las dependencias definidas en tu pyproject.toml
RUN poetry install --no-root --only main