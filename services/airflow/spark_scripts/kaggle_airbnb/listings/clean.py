
import sys
from pyspark.sql import SparkSession,  DataFrame, functions as F
from pyspark.sql.types import DoubleType


def drop_unneeded_columns(df: DataFrame, words: list) -> DataFrame:
    columns_to_drop = [col for col in df.columns if any(word in col for word in words)]
    return df.drop(*columns_to_drop)

def transform_columns(df):
    # Convert boolean columns
    boolean_cols = [col_name for col_name in df.columns
                        if df.select(col_name).filter(df[col_name].isin(['t', 'f'])).count()
                        == df.select(col_name).filter(f'NOT {col_name} IS NULL').count()]
    
    for bc in boolean_cols:
        df = df.withColumn(bc, F.when(F.col(bc) == 't', True).otherwise(False))

    # Standardize price fields
    # Find columns with non-null values all starting in $ 
    # and emove non-numeric characters from price (e.g., '$', ',')
    price_cols = [col_name for col_name in df.columns
                  if df.filter((~F.col(col_name).rlike('^\\$')) & (~F.isnull(F.col(col_name)))).count() == 0]
    for pc in price_cols:
        df = df.withColumn(pc, F.regexp_replace(F.col(pc), "[$,]", "").cast(DoubleType()))  

    return df
    
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
