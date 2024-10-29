
import sys
from pyspark.sql import SparkSession,  DataFrame, functions as F
from pyspark.sql.types import DoubleType


def drop_unneeded_columns(df: DataFrame, words: list) -> DataFrame:
    columns_to_drop = [col for col in df.columns if any(word in col for word in words)]
    return df.drop(*columns_to_drop)

def transform_columns(df):
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

    # Return transformed DataFrame
    return df.select(*transformed_cols)
    
def run(source, type,  s3_source_path: str, s3_target_path: str, column_keywords_to_exclude: list):
    spark = SparkSession.builder.appName(f"{source}_{type}_clean").getOrCreate()

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
            .csv(f"{s3_source_path}/listings.csv")
       
    df_clean = df.transform(drop_unneeded_columns, column_keywords_to_exclude)\
        .transform(transform_columns)

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
    column_keywords_to_exclude = args[4].split(';')

    run(source, type,  s3_source_path, s3_target_path, column_keywords_to_exclude)

  except Exception as e:
    print(f'An error occurred: {e}')
    raise e
