from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
from bs4 import BeautifulSoup
from sqlalchemy import create_engine, text
from io import StringIO
import pandas as pd
import requests
import psycopg2
import os
from pathlib import Path # Necesario para DbtTaskGroup

# --- Importamos las clases de dbt-airflow ---
# Esto funciona gracias a que se instaló dbt-airflow en el Dockerfile como root.
from dbt_airflow.core.config import DbtAirflowConfig
from dbt_airflow.core.config import DbtProfileConfig
from dbt_airflow.core.config import DbtProjectConfig
from dbt_airflow.core.task_group import DbtTaskGroup
from dbt_airflow.operators.execution import ExecutionOperator


# --- CONFIGURACIÓN DE RUTAS ---
# Rutas basadas en tu estructura
DBT_PROJECT_ROOT = '/opt/airflow/dags/transforms' 
DBT_PROFILES_DIR = '/home/airflow/.dbt' 
DBT_MANIFEST_PATH = f'{DBT_PROJECT_ROOT}/target/manifest.json' 


# --- Función de Extracción y Carga (E/L) ---
def scrape_fifa_raw():
    # ... (código de scrape_fifa_raw es el mismo) ...
    wiki_url = 'https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_finals'
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
    }
    response = requests.get(wiki_url, headers=headers)
    soup = BeautifulSoup(response.content, "html.parser")
    soup_table = soup.find_all('table', class_=['wikitable', 'sortable', 'plainrowheaders'])
    df = pd.read_html(StringIO(str(soup_table[1])))[0]

    DB_URL = f"postgresql+psycopg2://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@postgres:5432/{os.getenv('DW_DB_NAME')}"
    
    engine = create_engine(DB_URL)

    with engine.begin() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS staging;"))
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS analytics;"))
    
    df.to_sql(
        name='fifa_raw_finals', 
        con=engine, 
        schema='staging', 
        if_exists='replace', 
        index=False 
    ) 
    engine.dispose() 
# --- Fin de función E/L ---


default_args = {
    'owner': 'airflow', 
    'depends_on_past': False, 
    'retries': 1, 
    'retry_delay': timedelta(minutes=5), 
} 

with DAG(
    dag_id='fifa_world_cup_finals_elt_dbt_poetry', # Nuevo nombre para distinguir
    default_args=default_args, 
    start_date=datetime(2025, 1, 1), 
    schedule_interval='@weekly', 
    catchup=False, 
    tags=['elt', 'dbt', 'poetry']
) as dag: 

    scrape_task = PythonOperator(
        task_id='scrape_fifa_raw_data', 
        python_callable=scrape_fifa_raw, 
    ) 
    
    # --- Generar el manifest.json (CRUCIAL) ---
    # Necesario antes de que DbtTaskGroup lo lea. Confiamos en el PATH de Poetry.
    generate_manifest_task = BashOperator(
        task_id='dbt_generate_manifest', 
        bash_command=f"""
            cd {DBT_PROJECT_ROOT} && \
            dbt parse --profiles-dir {DBT_PROFILES_DIR}
        """,
    ) 

    # --- Tarea de Transformación con DbtTaskGroup ---
    dbt_transform_task_group = DbtTaskGroup(
        group_id='dbt_transformations',
        # Rutas de dbt adaptadas a pathlib.Path
        dbt_project_config=DbtProjectConfig(
            project_path=Path(DBT_PROJECT_ROOT),
            manifest_path=Path(DBT_MANIFEST_PATH),
        ),
        dbt_profile_config=DbtProfileConfig(
            profiles_path=Path(DBT_PROFILES_DIR),
            target='dev', # Ajusta este target si es diferente en tu profiles.yml
        ),
        dbt_airflow_config=DbtAirflowConfig(
            # Usamos BASH para asegurar que se use el entorno de Poetry/PATH
            execution_operator=ExecutionOperator.BASH, 
        ),
        # Ejecutamos solo el modelo de interés
        target_select=['fifa_world_cup_finals'],
        # NO definimos dbt_executable, confiamos en el PATH establecido por Poetry.
    )
    
    # --- Definición de Dependencias ---
    scrape_task >> generate_manifest_task >> dbt_transform_task_group