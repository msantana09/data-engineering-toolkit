import os
import logging
import json
from airflow.models.baseoperator import chain
from airflow.decorators import task, task_group
from pendulum import datetime
from include.operators.kaggle import KaggleDatasetToS3
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from include.spark.config import config as spark_config
from airflow.providers.trino.hooks.trino import TrinoHook
from airflow.exceptions import AirflowSkipException
from airflow import DAG
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from include.utilities.requests import post_json_request
from include.helper_functions import kaggle_airbnb as helper_functions

logger = logging.getLogger(__name__)

# connections
AWS_CONN_ID = "minio_default"
KAGGLE_CONN_ID = "kaggle_default"
SPARK_CONN_ID = "spark_local"
TRINO_CONN_ID = "trino_default"

# constants (defined here for now, but should be moved to AWS Secrets Manager or similar to avoid hardcoding)
S3_BUCKET = "datalake"
SOURCE = "kaggle_airbnb"
DATABASE_NAME = "kaggle_airbnb"
MODEL_SERVICE_BASE_URL = "http://model-api-svc.models.svc.cluster.local:8000/api/v1/models"

doc = """
# Kaggle Airbnb Data Pipeline

This DAG downloads the [Kaggle Airbnb dataset](https://www.kaggle.com/airbnb/seattle) and ingests it our lakehouse (MinIO, Apache Iceberg, Hive). 
It also generates column descriptions for the dataset using the **/describe_columns** Models service utilizing ChatGPT, and imports metadata into DataHub.

## Tasks

1. Download dataset from Kaggle
2. Clean and load data into staging layer (listing and reviews tables done in parallel)
3. Generate column descriptions for columns in each table
4. Run Datahub pipeline to ingest metadata into Datahub

## Connections

The DAG uses several connections, including MinIO (S3-like storage), Kaggle, Spark, and Trino.  

"""

with DAG(
    dag_id="kaggle_airbnb",
    start_date=datetime(2023, 1, 1),
    max_active_runs=1,
    schedule=None,
    catchup=False,
    doc_md=doc,
    tags=["kaggle", "airbnb", "chatgpt", "spark", "trino", "datahub"],
) as dag:
    
    download_dataset_task = KaggleDatasetToS3(
        task_id="download_kaggle_airbnb_dataset",
        conn_id=KAGGLE_CONN_ID,
        dataset="airbnb/seattle",
        bucket=S3_BUCKET,
        path=f"raw/{SOURCE}",
        aws_conn_id=AWS_CONN_ID,
        on_failure_callback=helper_functions.handle_failure,
    )

    @task
    def run_datahub_pipeline(recipe_path):
        helper_functions.run_datahub_pipeline(recipe_path)


    @task_group()
    def listings():
        TYPE = "listings"
        S3_RAW_PATH = f"s3://{S3_BUCKET}/raw/{SOURCE}"
        S3_STAGING_PATH = f"s3://{S3_BUCKET}/staging/{SOURCE}/{TYPE}"
        TABLE_NAME = "listings"


        clean_listings = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/{TYPE}/clean.py",
            name=f"{SOURCE}_{TYPE}_clean",
            task_id="clean_listings",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[
                SOURCE,
                TYPE,
                S3_RAW_PATH,
                S3_STAGING_PATH,
                ";".join(["url", "scrape", "license"]),
            ], 
            on_failure_callback=helper_functions.handle_failure,
        )

        load_listings = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/load.py",
            name=f"{SOURCE}_{TYPE}_load",
            task_id="load_listings",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[SOURCE, TYPE, S3_STAGING_PATH],
            on_failure_callback=helper_functions.handle_failure,
        )

        clean_listings >> load_listings

    @task_group()
    def reviews():
        TYPE = "reviews"
        S3_RAW_PATH = f"s3://{S3_BUCKET}/raw/{SOURCE}"
        S3_STAGING_PATH = f"s3://{S3_BUCKET}/staging/{SOURCE}/{TYPE}"

        clean_reviews = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/{TYPE}/clean.py",
            name=f"{SOURCE}_{TYPE}_clean",
            task_id="clean_reviews",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[
                SOURCE,
                TYPE,
                S3_RAW_PATH,
                S3_STAGING_PATH 
            ],
            on_failure_callback=helper_functions.handle_failure,
        )
 
        load_reviews = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/load.py",
            name=f"{SOURCE}_{TYPE}_load",
            task_id="load_reviews",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[SOURCE, TYPE, S3_STAGING_PATH],
            on_failure_callback=helper_functions.handle_failure,
        )

        clean_reviews >> load_reviews 

    @task_group()
    def generate_column_descriptions(tables:list):

        @task
        def query_llm_for_descriptions(table:str):
            def _get_columns_missing_descriptions(table):
                hook = TrinoHook(trino_conn_id=TRINO_CONN_ID)
                columns = helper_functions.get_columns_missing_comments(
                    hook=hook, database=DATABASE_NAME, table=table
                )
                return helper_functions.create_llm_column_request_batches(
                    columns=columns, batch_size=100
                )
            
            def _generate_descriptions(table, columns):
                payload = helper_functions.build_llm_column_request_payload_csv(
                    dataset_context="AirBnB", table=table, columns=columns
                )

                logger.info("Sending payload to API")
                response = post_json_request(f"{MODEL_SERVICE_BASE_URL}/describe_columns", payload)

                if response.status_code != 200:
                    raise Exception(f"Error from Models service API: {response.text}")

                content = response.json()["content"]
                usage = response.json()["usage"]
                logger.info(f"Usage: {usage}")
                return helper_functions.csv_to_list_of_dicts(content)
            
            def _upload_description_data_to_staging(table, columns):
                output = f"staging/{SOURCE}/{table}_column_descriptions.json"
                logger.info(f"Uploading column descriptions to {output}")
                hook = S3Hook(aws_conn_id=AWS_CONN_ID)
                hook.load_string(
                    string_data=json.dumps(columns),
                    key=output,
                    bucket_name=S3_BUCKET,
                    replace=True,
                )
            
            column_batches = _get_columns_missing_descriptions(table=table)

            if not column_batches or len(column_batches) == 0:
                raise AirflowSkipException("No columns to describe")
            
            responses = []
            for columns in column_batches:
                responses.extend(_generate_descriptions(table, columns) )

            # write column_json to s3
            _upload_description_data_to_staging(table, responses)

        @task
        def apply_column_descriptions(table, **kwargs):
            def _download_description_data(table):
                hook = S3Hook(aws_conn_id=AWS_CONN_ID)

                column_responses_path = hook.download_file(
                    key=f"staging/{SOURCE}/{table}_column_descriptions.json",
                    bucket_name=S3_BUCKET,
                    local_path=f"/tmp/{table}_column_descriptions.json",
                    preserve_file_name=True,
                )

                with open(column_responses_path, "r") as f:
                    column_responses_json = f.read()
                return json.loads(column_responses_json)
            
            column_descriptions = _download_description_data(table)

            TrinoHook(trino_conn_id=TRINO_CONN_ID).run(
                sql=helper_functions.build_comment_ddl(
                    column_descriptions, database=DATABASE_NAME, table=table
                ),
                autocommit=True,
            )

        (
            query_llm_for_descriptions.partial().expand(table=tables)
            >> apply_column_descriptions.partial().expand(table=tables)
        )


    chain(
        download_dataset_task,
        [
            listings(), 
            reviews()
        ],
        generate_column_descriptions(['listings', 'reviews']),
        run_datahub_pipeline(f"{os.environ['AIRFLOW_HOME']}/lib/datahub/recipes/airbnb.yaml")
    ) 