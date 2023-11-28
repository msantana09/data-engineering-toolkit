from airflow.decorators import dag
import pendulum
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from lib.spark.config import config as spark_config

 

@dag(
    schedule=None,
    start_date=pendulum.datetime(2021, 1, 1, tz="UTC"),
    catchup=False,
)
def test_dag():
    submit_job = SparkSubmitOperator(
        application="/opt/airflow/spark_scripts/test_spark.py", 
        task_id="submit_job",
        conn_id="spark_default_local",
        conf = spark_config
    )
    submit_job
test_dag()