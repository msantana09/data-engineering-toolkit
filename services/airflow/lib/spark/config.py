import os
config = {
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

    "spark.executor.instances": "2",
    "spark.kubernetes.namespace": "airflow",
    "spark.kubernetes.container.image":"custom-spark-python:latest",
    "spark.kubernetes.authenticate.driver.serviceAccountName": "airflow-service-account",
    "spark.jars": f"{os.environ['SPARK_HOME']}/jars/iceberg-spark-runtime-3.5_2.12-1.4.2.jar,\
        {os.environ['SPARK_HOME']}/jars/aws-java-sdk-bundle-1.12.587.jar,\
        {os.environ['SPARK_HOME']}/jars/bundle-2.17.257.jar"
}
 
# when running through cluster
# localhost:5001/custom-spark-python:latest