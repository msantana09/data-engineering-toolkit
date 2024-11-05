
import sys
import logging
from pyspark.sql import SparkSession,  DataFrame
from pyspark.sql.utils import AnalysisException

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def drop_null_comments(df: DataFrame) -> DataFrame:
  """Filter out rows where comments are null."""
  return df.filter(df.comments.isNotNull())

    
def run(source:str, entity:str,  s3_source_path: str, s3_target_path: str):
  spark = SparkSession.builder\
      .appName(f"{source}_{entity}_clean")\
      .getOrCreate()
  try:
    logger.info("Reading CSV data from %s", s3_source_path)

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
            .csv(f"{s3_source_path}/{entity}.csv")
       
    # Transform and cache cleaned data
    df_clean = df.transform(drop_null_comments)
    df_clean.cache()
    
    logger.info("Writing cleaned data to %s", s3_target_path)
    df_clean.write.parquet(
        path=s3_target_path
        ,mode='overwrite'
    )
    
    df_clean.unpersist()
  except AnalysisException as e:
      logger.error("Data processing error: %s", e)
      raise
  except Exception as e:
      logger.error("An unexpected error occurred: %s", e)
      raise
  finally:
      spark.stop()

if __name__ == "__main__":
  try:
    # Validate command-line arguments
    if len(sys.argv) < 5:
        raise ValueError("Usage: <source> <entity> <s3_source_path> <s3_target_path>")

    # Get passed arguments
    source = sys.argv[1]
    entity = sys.argv[2]
    s3_source_path = sys.argv[3]
    s3_target_path = sys.argv[4]

    run(source, entity,  s3_source_path, s3_target_path)

  except Exception as e:
      logger.critical("Script execution failed: %s", e)
      sys.exit(1)