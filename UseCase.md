# Kaggle Ingestion Use Case

TODO

We'll ingest a small dataset from Kaggle and process it with our platform:
- Use custom Airflow operators and hooks to ingest CSVs to a raw bucket in Minio
- Run Spark jobs to clean some of the columns, and write the output using the Apache Iceberg table format
- Since the Kaggle data set did not come with column descriptions, we'll share some details about the data set with GPT 3.5 and ask it to generate initial column descriptions for us 
- Run a Datahub CLI pipeline task which utilizes Trino to profile our tables, and publish results to a Kafka topic where it's consumed by the Datahub metadata service
- #TODO Language detection and sentiment analysis
