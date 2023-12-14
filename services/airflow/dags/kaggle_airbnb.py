import os
from airflow.models.baseoperator import chain
from airflow.decorators import dag, task,task_group
from pendulum import datetime
from datetime import datetime
import tempfile
from include.hooks.kaggle_hook import KaggleHook
from include.operators.kaggle import KaggleDatasetToS3
from lib.utilities.s3 import upload_files_to_s3
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from lib.spark.config import config as spark_config

SOURCE = "kaggle_airbnb"
S3_BUCKET = "datalake"
AWS_CONN_ID = "minio_default"
KAGGLE_CONN_ID = "kaggle_default"
SPARK_CONN_ID = "spark_local"
          

@dag(
    start_date=datetime(2023, 1, 1), 
    max_active_runs=3, 
    schedule=None, 
    catchup=False
)
def kaggle_airbnb():
    
    download_dataset_task = KaggleDatasetToS3(
        task_id='download_dataset',
        conn_id=KAGGLE_CONN_ID,
        dataset="airbnb/seattle",
        bucket=S3_BUCKET,
        path=f"raw/{SOURCE}",
        aws_conn_id=AWS_CONN_ID 
    )
    

    @task_group()
    def listings():
        TYPE = "listings"
        S3_RAW_PATH = f"s3://{S3_BUCKET}/raw/{SOURCE}"
        S3_STAGING_PATH = f"s3://{S3_BUCKET}/staging/{SOURCE}/{TYPE}"

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
        download_dataset_task,
        [
            listings(),
            reviews()
        ]
    )


kaggle_airbnb()