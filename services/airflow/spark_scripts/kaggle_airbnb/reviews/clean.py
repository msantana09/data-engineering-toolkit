
import sys
from pyspark.sql import SparkSession,  DataFrame, functions as F


def drop_null_comments(df: DataFrame ) -> DataFrame:
    with_comments=df.filter(df.comments.isNotNull())
    return with_comments

    
def run(source, type,  s3_source_path: str, s3_target_path: str):
    spark = SparkSession.builder\
      .appName(f"{source}_{type}_clean")\
      .getOrCreate()

    df = spark.read\
            .option("sep",",")\
            .option("inferSchema", "true")\
            .option("header", "true")\
            .option("multiline","true")\
            .option("quote", '"')\
            .option("escape", "\\")\
            .option("escape", '"')\
            .option("encoding", "UTF-8")\
            .option("ignoreLeadingWhiteSpace", "true")\
            .option("ignoreTrailingWhiteSpace", "true")\
            .csv(f"{s3_source_path}/reviews.csv")
       
    df_clean = df.transform(drop_null_comments)
    df_clean.cache()

    df_clean.write.parquet(
        path=s3_target_path
        ,mode='overwrite'
    )
    
    spark.stop()


if __name__ == "__main__":
  try:
    # Get passed arguments
    args = sys.argv[1:]
    source = args[0]
    type = args[1]

    s3_source_path = args[2]
    s3_target_path = args[3]

    run(source, type,  s3_source_path, s3_target_path)

  except Exception as e:
    print(f'An error occurred: {e}')
    raise e
