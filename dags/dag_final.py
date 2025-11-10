from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
from bs4 import BeautifulSoup
from airflow.operators.bash import BashOperator
from sqlalchemy import create_engine, text
from io import StringIO
import pandas as pd
import requests
import psycopg2
import os

def scrape_fifa_raw():
    wiki_url = 'https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_finals'
    table_class = 'sortable plainrowheaders wikitable jquery-tablesorter'
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

default_args = {
    'owner': 'airflow', 
    'depends_on_past': False, 
    'retries': 1, 
    'retry_delay': timedelta(minutes=5), 
} 

with DAG(
    dag_id='fifa_world_cup_finals_etl', 
    default_args=default_args, 
    start_date=datetime(2025, 1, 1), 
    schedule_interval='@weekly', 
    catchup=False, 
) as dag: 

    scrape_task = PythonOperator(
        task_id='scrape_fifa_raw_data', 
        python_callable=scrape_fifa_raw, 
    ) 
    dbt_run_task = BashOperator(
        task_id='dbt_run_fifa_world_cup_finals', 
        bash_command=(
            'export PATH=$PATH:/home/airflow/.local/bin:/usr/local/bin && ' 
            'cd /opt/airflow/dags/transforms && ' 
            'dbt run --select fifa_world_cup_finals' 
        ),
    ) 
    scrape_task >> dbt_run_task