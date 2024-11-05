
import sys
import logging
from pyspark.sql import SparkSession, DataFrame, functions as F
from pyspark.sql.types import DoubleType

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def drop_unneeded_columns(df: DataFrame, words: list) -> DataFrame:
    """Drop columns that contain any of the specified keywords."""
    columns_to_drop = [col for col in df.columns if any(word in col for word in words)]
    return df.drop(*columns_to_drop)

def transform_columns(df: DataFrame) -> DataFrame:
    """Transform columns by converting boolean and price columns to appropriate types."""

    # Identify boolean columns
    boolean_cols = [
        col_name for col_name in df.columns 
        if df.filter(~(F.col(col_name).isin('t', 'f') | F.col(col_name).isNull())).count() == 0
    ]

    # Identify price columns 
    price_cols = [
        col_name for col_name in df.columns 
        if df.filter(~F.col(col_name).rlike('^\\$')).filter(F.col(col_name).isNotNull()).count() == 0
    ]     

    # Transform columns 
    transformed_cols = [
        F.when(F.col(col_name) == 't', True).otherwise(False).alias(col_name) if col_name in boolean_cols else
        F.regexp_replace(F.col(col_name), "[$,]", "").cast(DoubleType()).alias(col_name) if col_name in price_cols else
        F.col(col_name)  # Default to original column
        for col_name in df.columns
    ]

    return df.select(*transformed_cols)
    
def run(source: str, entity: str, s3_source_path: str, s3_target_path: str, column_keywords_to_exclude: list):
    spark = SparkSession.builder.appName(f"{source}_{entity}_clean").getOrCreate()
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
       
        # Apply transformations
        df_clean = df.transform(drop_unneeded_columns, column_keywords_to_exclude).transform(transform_columns)
        df_clean.cache()

        logger.info("Writing cleaned data to %s", s3_target_path)
        df_clean.write.parquet(
            path=s3_target_path
            ,mode='overwrite'
        )
        df_clean.unpersist()
    except Exception as e:
        logger.error("An error occurred during processing: %s", e)
        raise
    finally:
        spark.stop()


if __name__ == "__main__":
  try:
    # Validate command-line arguments
    if len(sys.argv) < 5:
        raise ValueError("Usage: <source> <entity> <s3_source_path> <s3_target_path> <column_keywords_to_exclude>")
    source = sys.argv[1]
    entity = sys.argv[2]
    s3_source_path = sys.argv[3]
    s3_target_path = sys.argv[4]
    column_keywords_to_exclude = sys.argv[5].split(';')


    run(source, entity,  s3_source_path, s3_target_path, column_keywords_to_exclude)

  except Exception as e:
    logger.critical("Script execution failed: %s", e)
    sys.exit(1)
