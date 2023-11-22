import tempfile
from airflow.models.baseoperator import chain
from airflow.decorators import dag, task, task_group
from pendulum import datetime
from include.hooks.kaggle_hook import KaggleHook
from include.utilities.s3 import upload_directory_to_s3

SOURCE = "kaggle_airbnb"
S3_BUCKET = "datalake"

AWS_CONN_ID = "minio_default"
KAGGLE_CONN_ID = "kaggle_default"


@dag(start_date=datetime(2023, 1, 1), max_active_runs=3, schedule=None, catchup=False)
def kaggle_airbnb():
    @task
    def ingest_dataset(date):
        # Initialize hook with preconfigured connection
        kaggle_hook = KaggleHook(conn_id=KAGGLE_CONN_ID)

        # Create temporary directory to store downloaded dataset
        temp_dir = tempfile.TemporaryDirectory()

        # Download dataset
        kaggle_hook.download_dataset(dataset="airbnb/seattle", path=temp_dir.name)

        # Upload dataset to S3
        upload_directory_to_s3(
            S3_BUCKET, temp_dir.name, f"raw/{SOURCE}/{date}", aws_conn_id=AWS_CONN_ID
        )

        # Delete temporary directory
        temp_dir.cleanup()

    @task_group()
    def reviews():
        @task
        def clean():
            pass

        @task
        def load():
            pass

        clean() >> load()

    chain(ingest_dataset("{{ ds }}"))


kaggle_airbnb()
