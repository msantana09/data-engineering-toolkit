FROM apache/airflow:2.7.3

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY dags/ /opt/airflow/dags
COPY include/ /opt/airflow/include
COPY plugins/ /opt/airflow/plugins

ENV PYTHONPATH="${PYTHONPATH}:/opt/airflow/include"

USER airflow
