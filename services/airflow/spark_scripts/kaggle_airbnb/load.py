
import sys
import logging
from pyspark.sql import SparkSession
from pyspark.sql.utils import AnalysisException

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def run(source:str, entity:str, s3_source_path: str):
    # catalog and iceberg settings are defined in the include.spark.config.py file
    spark = SparkSession.builder.appName(f"{source}_{entity}_load").getOrCreate()
    
    try:
      logger.info("Reading Parquet files from %s", s3_source_path)

      df = spark.read.parquet(s3_source_path)
      df.cache()

      # Create database if not exists
      spark.sql(f'CREATE DATABASE IF NOT EXISTS {source}')
      
      # Write data to Iceberg table, creating or replacing it
      target_table = f"{source}.{entity}"
      try:
          df.writeTo(target_table).createOrReplace()
          logger.info("Data successfully written to Iceberg table %s", target_table)
      except AnalysisException as e:
          logger.error("Error writing data to Iceberg table: %s", e)
          raise
        
      df.unpersist()
    except Exception as e:
        logger.error("An error occurred during processing: %s", e)
        raise
    finally:
        spark.stop()

if __name__ == "__main__":
    try:
        # Parse command-line arguments
        if len(sys.argv) < 4:
            raise ValueError("Usage: <source> <entity> <s3_source_path>")

        source = sys.argv[1]
        entity = sys.argv[2]
        s3_source_path = sys.argv[3]

        run(source, entity, s3_source_path)
    except Exception as e:
        logger.critical("Failed to execute the script: %s", e)
        sys.exit(1)