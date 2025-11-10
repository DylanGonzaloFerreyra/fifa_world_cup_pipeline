FROM apache/airflow:2.7.3-python3.8

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev gcc netcat-openbsd libc-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER airflow
WORKDIR /opt/airflow

RUN pip install --no-cache-dir \
    apache-airflow-providers-postgres \
    dbt-core \
    dbt-postgres \
    pandas \
    beautifulsoup4 \
    requests
