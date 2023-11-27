import os
from airflow.models.baseoperator import chain
from airflow.decorators import dag, task,task_group
from pendulum import datetime
from datetime import datetime
import tempfile
from include.hooks.kaggle_hook import KaggleHook
from lib.utilities.s3 import upload_files_to_s3
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from lib.spark.config import config as spark_config

SOURCE = "kaggle_airbnb"
S3_BUCKET = "datalake"

AWS_CONN_ID = "local_minio"
KAGGLE_CONN_ID = "kaggle_default"

SPARK_CONN_ID = "spark_default_local"
          

@dag(
    start_date=datetime(2023, 1, 1), 
    max_active_runs=3, 
    schedule=None, 
    catchup=False
)
def kaggle_airbnb():
    @task
    def download_dataset(date):
        # Initialize hook with preconfigured connection
        kaggle_hook = KaggleHook(conn_id=KAGGLE_CONN_ID)

        # Create temporary directory to store downloaded dataset
        temp_dir = tempfile.TemporaryDirectory()
        
        # Download dataset
        kaggle_hook.download_dataset(dataset="airbnb/seattle", path=temp_dir.name)

        # Upload dataset to S3        
        upload_files_to_s3(S3_BUCKET, temp_dir.name, f"raw/{SOURCE}/{date}", aws_conn_id=AWS_CONN_ID)

        # Delete temporary directory
        temp_dir.cleanup()

    @task_group()
    def listings(date):
        TYPE = "listings"
        S3_RAW_PATH = f"s3://{S3_BUCKET}/raw/{SOURCE}/{date}"
        S3_STAGING_PATH = f"s3://{S3_BUCKET}/staging/{SOURCE}/{TYPE}/{date}"

        clean = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/{TYPE}/clean.py",
            name = f"{SOURCE}_{TYPE}_clean",
            task_id="clean",
            conn_id=SPARK_CONN_ID,
            conf = spark_config,
            application_args=[
                SOURCE,
                TYPE,
                S3_RAW_PATH,
                S3_STAGING_PATH,
                ";".join(['url', 'scrape', 'license' ])
                ],
        )
        load = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/{TYPE}/load.py",
            name = f"{SOURCE}_{TYPE}_load",
            task_id="load",
            conn_id=SPARK_CONN_ID,
            conf = spark_config,
            application_args=[
                SOURCE,
                TYPE,
                S3_STAGING_PATH
                ],
        )

        clean >> load


    @task_group()
    def reviews():
        @task
        def clean():
            pass
        
        @task
        def load():
            pass

        clean() >> load()

    chain(
        download_dataset('{{ ds }}'),
        [
            listings('{{ ds }}'),
            reviews()
        ]
    )


kaggle_airbnb()