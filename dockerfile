FROM apache/airflow:2.7.3-python3.8

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq-dev gcc netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir \
    apache-airflow-providers-postgres \
    dbt-core \
    dbt-postgres \
    pandas \
    beautifulsoup4 \
    psycopg2 \
    requests

ENV POETRY_VERSION=1.8.3 \
    POETRY_HOME="/opt/poetry" \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=false
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN pip install --upgrade pip && \
    pip install "poetry==$POETRY_VERSION"
COPY pyproject.toml poetry.lock* ./ /opt/airflow/
COPY ./dags/ ./dags/
COPY ./dags/transforms/ ./dags/transforms/



USER airflow
WORKDIR /opt/airflow
RUN poetry install --no-root --only main