# Kaggle Ingestion Use Case

## Overview
We'll ingest a dataset from Kaggle and process it with our platform:
- Use custom Airflow operators and hooks to ingest CSVs to a raw bucket in Minio
- Run Spark jobs to clean some of the columns, and write the output using the Apache Iceberg table format
- Since the Kaggle data set did not come with column descriptions, we'll share some details about the data set with GPT 3.5 and ask it to generate initial column descriptions for us 
- Run a Datahub CLI pipeline task to profile our tables utilizing Trino, and publish results to a Kafka topic
- Datahub's metadata service will consume messages from the Kafka topic, and present the profiling results in the Datahub UI

### Resource Requirements
- it's recommended to allocate (at least) **4 cores and 16GB memory** to Docker in order for all services in the use case to run successfully.
- To run with lower specs (min 8GB memory needed), you can run the use case in two steps:
    1. the Airflow DAG will complete successfully with just the `core` and `models` services running. 
    2. You can then shutdown `core` and `models` services, and start just `kafka` and `datahub` services. Since Kafka utilizes a persistent volume, messages will still be available for Datahub to consume once Datahub is fully started. 


## Steps
1. Configure use case credentials

    You'll need to update the .env files with valid credentials before starting. If you don't see an .env file, please see the initialiation step in the [quick start](/README.md#quick-start)

   - **Kaggle**: Update `AIRFLOW_CONN_KAGGLE_DEFAULT` in file `services/airflow/.env` with your [Kaggle](https://www.kaggle.com/) username and key
   - **OpenAI**: Update `OPENAI_API_KEY` in file `services/models/.env` with your [OpenAI](https://openai.com/)  key

2. Start the needed services
    ````bash
        # start all the services for the use case (it'll take ~10mins for all services to start up) :
        # core ( lakehouse ( minio, hive, trino ) + airflow + spark + kafka )
        # models
        # datahub
        ./platform.sh start core models datahub
    ````

3. Go to [Airflow](http://localhost:8081/) and start the  [kaggle_airbnb](http://localhost:8081/dags/kaggle_airbnb/grid) pipeline.  It'll take 3-4 mins to complete
    ![Airflow graph](images/kaggle_airbnb_dag_graph.png)


4. Verify tables have been created and the data is queryable by connecting to Trino using a SQL client. Here's an example of SQLTools client in VS Code:

    #### SQLTools connection settings
    ![SQLTools connection settings](images/SQLTools_connection.png)

    #### SQLTools Browser Tree
    ![SQLTools Browser Tree](images/SQLTools_browser.png)

5. Go to [Datahub](http://localhost:8084/) , and search for 'kaggle_airbnb'.  You see a few results, including this `listings` table with ingested metadata showing the GPT3.5 generate column descriptions

    #### Datahub Dataset
    ![datahub](images/datahub_listings.png)