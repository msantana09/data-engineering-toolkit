
import os
from pyspark import SparkContext
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType,StructField, StringType, IntegerType
from pprint import pprint

if __name__ == "__main__":
  
  pprint(dict(os.environ))
  
  sc = SparkContext.getOrCreate()
  sc.appName = "test_script"
  sc.environment["AWS_REGION"] = os.environ['AWS_REGION']
  sc.environment["AWS_ACCESS_KEY_ID"] = os.environ['AWS_ACCESS_KEY_ID']
  sc.environment["AWS_SECRET_ACCESS_KEY"] = os.environ['AWS_SECRET_ACCESS_KEY']
  sc.environment["AWS_ENDPOINT_URL_S3"] = os.environ['AWS_ENDPOINT_URL_S3']

  spark = SparkSession(sc)

  #spark = SparkSession.builder.appName("test_script").getOrCreate()
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
  
  pprint(dict(os.environ))

  df = spark.createDataFrame(data=data, schema=schema)
  print("XXXX")
  pprint(dict(os.environ))

  spark.sql('CREATE DATABASE IF NOT EXISTS hr;')

  df.writeTo("hr.employees").createOrReplace()

  spark.stop()