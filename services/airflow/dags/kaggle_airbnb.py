import os
from airflow.models.baseoperator import chain
from airflow.decorators import task, task_group
from pendulum import datetime
from include.operators.kaggle import KaggleDatasetToS3
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from lib.spark.config import config as spark_config
from airflow.providers.trino.hooks.trino import TrinoHook
from airflow.exceptions import AirflowSkipException
from airflow import DAG
import logging
from include.utilities.requests import post_json_request
from include.helper_functions import kaggle_airbnb as helper_functions

logger = logging.getLogger(__name__)

SOURCE = "kaggle_airbnb"
S3_BUCKET = "datalake"
AWS_CONN_ID = "minio_default"
KAGGLE_CONN_ID = "kaggle_default"
SPARK_CONN_ID = "spark_local"
CONN_ID = "trino_default"
DATABASE_NAME = "kaggle_airbnb"
TABLE_NAME = "listings"
MODEL_SERVICE_BASE_URL = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80/api/v1/models"


with DAG(
    dag_id="kaggle_airbnb",
    start_date=datetime(2023, 1, 1),
    max_active_runs=3,
    schedule=None,
    catchup=False,
) as dag:
    download_dataset_task = KaggleDatasetToS3(
        task_id="download_kaggle_airbnb_dataset",
        conn_id=KAGGLE_CONN_ID,
        dataset="airbnb/seattle",
        bucket=S3_BUCKET,
        path=f"raw/{SOURCE}",
        aws_conn_id=AWS_CONN_ID,
    )
    @task
    def run_datahub_pipeline(recipe_path):
        helper_functions.run_datahub_pipeline(recipe_path)


    @task_group()
    def listings():
        TYPE = "listings"
        S3_RAW_PATH = f"s3://{S3_BUCKET}/raw/{SOURCE}"
        S3_STAGING_PATH = f"s3://{S3_BUCKET}/staging/{SOURCE}/{TYPE}"

        clean = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/{TYPE}/clean.py",
            name=f"{SOURCE}_{TYPE}_clean",
            task_id="clean",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[
                SOURCE,
                TYPE,
                S3_RAW_PATH,
                S3_STAGING_PATH,
                ";".join(["url", "scrape", "license"]),
            ],
        )

        load = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/load.py",
            name=f"{SOURCE}_{TYPE}_load",
            task_id="load",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[SOURCE, TYPE, S3_STAGING_PATH],
        )

        @task_group()
        def generate_column_descriptions():
            @task()
            def get_columns_missing_descriptions(**kwargs):
                hook = TrinoHook(trino_conn_id=CONN_ID)
                columns = helper_functions.identify_columns_missing_comments(
                    hook=hook, database=DATABASE_NAME, table=TABLE_NAME
                )
                return helper_functions.create_llm_column_request_batches(
                    columns=columns, batch_size=100
                )

            @task
            def query_llm_for_descriptions(columns: list):
                if not columns:
                    AirflowSkipException("No columns to describe")

                payload = helper_functions.build_model_api_payload_csv(
                    dataset_context="AirBnB", table=TABLE_NAME, columns=columns
                )

                logger.info("Sending payload to API")
                response = post_json_request(f"{MODEL_SERVICE_BASE_URL}/describe_columns", payload)

                if response.status_code != 200:
                    raise Exception(f"Error from Models service API: {response.text}")

                content = response.json()["content"]
                usage = response.json()["usage"]
                logger.info(f"Usage: {usage}")
                logger.debug(f"Result: {content}")

                return helper_functions.csv_to_json_array(content)

            @task
            def apply_column_descriptions(**kwargs):
                column_batched_responses = kwargs["ti"].xcom_pull(
                    task_ids="listings.generate_column_descriptions.query_llm_for_descriptions",
                    key="return_value",
                )
                # flattening resulting list of lists into a single list
                column_responses = [
                    item for sublist in column_batched_responses for item in sublist
                ]

                TrinoHook(trino_conn_id=CONN_ID).run(
                    sql=helper_functions.build_comment_sql(
                        column_responses, database=DATABASE_NAME, table=TABLE_NAME
                    ),
                    autocommit=True,
                )

            (
                query_llm_for_descriptions.partial().expand(columns=get_columns_missing_descriptions())
                >> apply_column_descriptions()
            )


        (
            clean
            >> load
            >> generate_column_descriptions()
        )

    @task_group()
    def reviews():
        # TODO
        TYPE = "reviews"
        S3_RAW_PATH = f"s3://{S3_BUCKET}/raw/{SOURCE}"
        S3_STAGING_PATH = f"s3://{S3_BUCKET}/staging/{SOURCE}/{TYPE}"

        clean = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/{TYPE}/clean.py",
            name=f"{SOURCE}_{TYPE}_clean",
            task_id="clean",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[
                SOURCE,
                TYPE,
                S3_RAW_PATH,
                S3_STAGING_PATH 
            ],
        )
 
        load = SparkSubmitOperator(
            application=f"{os.environ['AIRFLOW_HOME']}/spark_scripts/{SOURCE}/load.py",
            name=f"{SOURCE}_{TYPE}_load",
            task_id="load",
            conn_id=SPARK_CONN_ID,
            conf=spark_config,
            application_args=[SOURCE, TYPE, S3_STAGING_PATH],
        )  

        @task_group()
        def perform_sentiment_analysis():
            @task()
            def get_reviews(**kwargs):
                return ["placeholder"]

            @task
            def query_llm_for_sentiments(columns: list):
                pass

            @task
            def load_sentiment_results(**kwargs):
                pass

            (
                query_llm_for_sentiments.partial().expand(columns=get_reviews())
                >> load_sentiment_results()
            )

        clean >> load >> perform_sentiment_analysis()

    chain(
        download_dataset_task,
        [
            listings(), 
            reviews()
        ],
        run_datahub_pipeline("/opt/airflow/lib/datahub/recipes/airbnb.yaml")
        )
