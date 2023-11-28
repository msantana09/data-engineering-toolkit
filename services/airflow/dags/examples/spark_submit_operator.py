from pendulum import datetime
from airflow.decorators import dag
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from lib.spark.config import config as spark_config


def update_spark_config(dag_id, task_id):
    update_spark_config = spark_config.copy()
    update_spark_config["spark.kubernetes.file.upload.path"]+= f"{dag_id}/{task_id}/"
    return update_spark_config

@dag(
    start_date=datetime(2023, 1, 1), 
    max_active_runs=3, 
    schedule=None, 
    catchup=False,
    tags=["example", "spark", "k8s"],
)
def example_spark_submit():

    spark_submit_k8_driver = SparkSubmitOperator(
        conn_id="spark_k8",
        task_id="spark_submit_k8_driver",
        name="spark_submit_k8_driver",
        application="/opt/airflow/spark_scripts/spark_sample.py", 
        conf=update_spark_config(dag_id="{{ dag.dag_id }}", task_id="{{ task.task_id  }}"),
        num_executors=5,        
    ) 
    spark_submit_local_driver = SparkSubmitOperator(
        conn_id="spark_local",
        task_id="spark_submit_local_driver",
        name="spark_submit_local_driver",
        application="/opt/airflow/spark_scripts/spark_sample.py", 
        conf=spark_config,
        num_executors=5
    ) 
    spark_submit_k8_driver >> spark_submit_local_driver

example_spark_submit()