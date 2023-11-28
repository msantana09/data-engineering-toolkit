
import os
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType,StructField, StringType, IntegerType
from pprint import pprint

if __name__ == "__main__":
  spark = SparkSession.builder.appName("test_script").getOrCreate()
  data = [("James","","Smith","36636","M",3002),
      ("Michael","Rose","","40288","M",4000),
      ("Robert","","Williams","42114","M",4000),
      ("Maria","Anne","Jones","39192","F",4000),
      ("Jen","Mary","Brown","","F",-1)
    ]

  schema = StructType([ \
      StructField("firstname",StringType(),True), \
      StructField("middlename",StringType(),True), \
      StructField("lastname",StringType(),True), \
      StructField("id", StringType(), True), \
      StructField("gender", StringType(), True), \
      StructField("salary", IntegerType(), True) \
    ])


  df = spark.createDataFrame(data=data, schema=schema)

  spark.sql('CREATE DATABASE IF NOT EXISTS hr;')

  df.writeTo("hr.employees").createOrReplace()

  spark.stop()