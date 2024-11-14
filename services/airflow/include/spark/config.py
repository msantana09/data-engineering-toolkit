import os

SPARK_JAR_PATH = f"{os.environ['SPARK_HOME']}/jars/"
SPARK_JARS = []


config = {
    "spark.jars": ",".join([SPARK_JAR_PATH + jar for jar in SPARK_JARS]),

    "spark.sql.defaultCatalog": "lakehouse",
    "spark.sql.catalogImplementation": "hive",
    
    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    "spark.sql.catalog.spark_catalog": "org.apache.iceberg.spark.SparkSessionCatalog",
    "spark.sql.catalog.spark_catalog.type": "hive",
    "spark.sql.catalog.lakehouse": "org.apache.iceberg.spark.SparkCatalog",
    "spark.sql.catalog.lakehouse.type": "hive",
    "spark.sql.catalog.lakehouse.uri": os.environ['HIVE_ENDPOINT_URL'],
    "spark.sql.catalog.lakehouse.warehouse":  os.environ['AWS_S3_LAKEHOUSE'],
    "spark.sql.catalog.lakehouse.io-impl": "org.apache.iceberg.aws.s3.S3FileIO",
    "spark.sql.catalog.lakehouse.s3.endpoint":  os.environ['AWS_ENDPOINT_URL_S3'],
    
    "spark.hadoop.fs.s3.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
    "spark.hadoop.fs.s3a.path.style.access": "true",
    "spark.hadoop.fs.s3a.access.key": os.environ['AWS_ACCESS_KEY_ID'],
    "spark.hadoop.fs.s3a.secret.key": os.environ['AWS_SECRET_ACCESS_KEY'],
    "spark.hadoop.fs.s3a.endpoint": os.environ['AWS_ENDPOINT_URL_S3'],

    "spark.kubernetes.namespace": "airflow",
    "spark.kubernetes.container.image":"kind-registry:5000/custom-spark-python:latest",
    "spark.kubernetes.authenticate.driver.serviceAccountName": "airflow-service-account",
    "spark.kubernetes.file.upload.path": "s3://platform/spark_k8s_uploads/",
    # Passing env vars to spark driver and executors to prevent
    # hardcoding credentials in the spark scripts/Dockerfile
    "spark.kubernetes.driverEnv.AWS_REGION": os.environ['AWS_REGION'],
    "spark.kubernetes.driverEnv.AWS_ACCESS_KEY_ID": os.environ['AWS_ACCESS_KEY_ID'],
    "spark.kubernetes.driverEnv.AWS_SECRET_ACCESS_KEY": os.environ['AWS_SECRET_ACCESS_KEY'],
    "spark.kubernetes.driverEnv.AWS_ENDPOINT_URL_S3": os.environ['AWS_ENDPOINT_URL_S3'],
    "spark.executorEnv.AWS_REGION": os.environ['AWS_REGION'],
    "spark.executorEnv.AWS_ACCESS_KEY_ID": os.environ['AWS_ACCESS_KEY_ID'],
    "spark.executorEnv.AWS_SECRET_ACCESS_KEY": os.environ['AWS_SECRET_ACCESS_KEY'],
    "spark.executorEnv.AWS_ENDPOINT_URL_S3": os.environ['AWS_ENDPOINT_URL_S3']
}
