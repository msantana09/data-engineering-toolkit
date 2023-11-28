
import time
import pendulum
from airflow.decorators import dag, task
from airflow.providers.amazon.aws.operators.s3 import S3CreateBucketOperator, S3DeleteBucketOperator

BUCKET_NAME = "test-bucket"
AWS_CONN_ID = "minio_default"

@dag(
    schedule=None,
    start_date=pendulum.datetime(2021, 1, 1, tz="UTC"),
    catchup=False,
    tags=["example"],
    description="Sample DAG to test MinIO connection"
)
def test_minio_connection():
    create_bucket = S3CreateBucketOperator(
        task_id="create_bucket",
        aws_conn_id=AWS_CONN_ID,
        bucket_name=BUCKET_NAME,
    )
    @task
    def pause():
        # Wait for 30 seconds
        # This is just to give the user time to check the MinIO UI
        time.sleep(30)

    delete_bucket = S3DeleteBucketOperator(
        task_id="delete_bucket",
        aws_conn_id=AWS_CONN_ID,
        bucket_name=BUCKET_NAME,
    )

    create_bucket >> pause() >> delete_bucket

test_minio_connection()