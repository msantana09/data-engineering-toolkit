
import sys
from pyspark.sql import SparkSession,  DataFrame, functions as F
from pyspark.sql.types import DoubleType



def run(source, type, s3_source_path: str):
    spark = SparkSession.builder.appName(f"{source}_{type}_load").getOrCreate()

    df = spark.read.parquet(s3_source_path)
    df.cache()

    spark.sql(F'CREATE DATABASE IF NOT EXISTS {source};')
    df.writeTo(f"{source}.{type}").createOrReplace()

    spark.stop()


if __name__ == "__main__":
  try:
    # Get passed arguments
    args = sys.argv[1:]

    source = args[0]
    type = args[1]
    s3_source_path = args[2]

    run(source, type, s3_source_path)

  except Exception as e:
    print(f'An error occurred: {e}')
    raise e
