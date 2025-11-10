from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

# DAG básico de prueba
with DAG(
    dag_id="test_dag",
    description="DAG de prueba para verificar configuración de Airflow",
    start_date=datetime(2025, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    default_args={
        "owner": "airflow",
        "retries": 1,
        "retry_delay": timedelta(minutes=1),
    },
) as dag:

    tarea_1 = BashOperator(
        task_id="mostrar_fecha",
        bash_command="echo '✅ DAG de prueba funcionando! Fecha actual: $(date)'"
    )

    tarea_1
