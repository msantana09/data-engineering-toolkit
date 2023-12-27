from pendulum import datetime
from airflow.decorators import dag
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from lib.spark.config import config as spark_config
from functools import partial

APPLICATION_PATH="/opt/airflow/spark_scripts/spark_sample.py"
NUM_EXECUTORS=2

def update_spark_config(spark_conf, dag_id, task_id):
    update_spark_config = spark_conf.copy()
    update_spark_config["spark.kubernetes.file.upload.path"]+= f"{dag_id}/{task_id}/"
    return update_spark_config

@dag(
    start_date=datetime(2023, 1, 1), 
    max_active_runs=3, 
    schedule=None, 
    catchup=False,
    tags=["example", "spark", "k8s"],
    doc_md="""
## Example Spark Submit DAG Documentation

### Overview
This Apache Airflow DAG (`example_spark_submit`) is designed as an example to test the `SparkSubmitOperator`. It demonstrates how to submit Spark jobs in two different environments: a Kubernetes cluster and a local setup. The DAG includes two tasks, each using a different Spark connection and configuration.


### Tasks
1. **Spark on Kubernetes (spark_submit_k8_driver)**
   - **Connection ID**: `spark_k8s`
     - The master is set to the Kubernetes (k8s) control plane.
     - Deploy mode is set to `cluster`.
   - **Task ID**: `spark_submit_k8_driver`
   - **Spark Application Path**: `/opt/airflow/spark_scripts/spark_sample.py`
   - **Number of Executors**: 2
   - **Configuration**: Dynamically updates the Spark configuration to include the DAG ID and task ID in the file upload path for Kubernetes.

2. **Spark on Local (spark_submit_local_driver)**
   - **Connection ID**: `spark_local`
     - The master is set to `local[*]`.
     - Deploy mode is set to `client`.
   - **Task ID**: `spark_submit_local_driver`
   - **Spark Application Path**: `/opt/airflow/spark_scripts/spark_sample.py`
   - **Number of Executors**: 2
   - **Configuration**: Uses the standard Spark configuration provided in `lib.spark.config`.
"""
)
def example_spark_submit():
    dynamic_spark_conf = partial(update_spark_config, spark_config)
    
    spark_submit_k8_driver = SparkSubmitOperator(
        conn_id="spark_k8s",
        task_id="spark_submit_k8_driver",
        name="spark_submit_k8_driver",
        application=APPLICATION_PATH, 
        conf=dynamic_spark_conf(dag_id="{{ dag.dag_id }}", task_id="{{ task.task_id }}"),
        num_executors=NUM_EXECUTORS   
    ) 

    spark_submit_local_driver = SparkSubmitOperator(
        conn_id="spark_local",
        task_id="spark_submit_local_driver",
        name="spark_submit_local_driver",
        application=APPLICATION_PATH, 
        conf=spark_config,
        num_executors=NUM_EXECUTORS
    ) 
    spark_submit_local_driver >> spark_submit_k8_driver

example_spark_submit()
