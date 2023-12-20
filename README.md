# Data Platform Project
![Platform Overview](images/data_platform_overview.png)

## Introduction

The goal of this project is to provide a local development environment for Data Engineers & Scientists to easily experiement with new tools and use cases. This is made possible because the tools in the project are pre-configured to work with each other, minimizing the effort needed to get started. 

### The use case
We'll ingest a small dataset from Kaggle and process it with our platform:
- Use custom Airflow operators and hooks to ingest CSVs to a raw bucket in Minio
- Run Spark jobs to clean some of the columns, and write the output using the Apache Iceberg table format
- Since the Kaggle data set did not come with column descriptions, we'll share some details about the data set with GPT 3.5 and ask it to generate initial column descriptions for us 
- Run a Datahub CLI pipeline task which utilizes Trino to profile our tables, and publish results to a Kafka topic where it's consumed by the Datahub metadata service
- #TODO Language detection and sentiment analysis


This version makes uses a *mostly* open stack comprised of:

Tool  | Description 
--- | --- 
[MinIO](https://min.io/) | An object storage solution that provides an S3-like experience, but with your data staying local.
[Apache Airflow ](https://airflow.apache.org/) | An orchestrator for our data pipelines
[Python](https://www.python.org/)| Primary lanaguage used in data pipelines
[Apache Spark](https://spark.apache.org/) | Used to process ingested data (e.g. clean/transform tasks), and to analyze with SparkSQL
[Apache Hive Metastore](https://cwiki.apache.org/confluence/display/hive/design)| Hive acts as a central repository for metadata about our data lake. Our Spark jobs and Trino rely on Hive when querying or modifying tables.
[Apache Iceberg](https://iceberg.apache.org/)| A table format utilized by our Spark jobs to enable data stored in S3 (Minio) to be querable through engines like Trino or SparkSQL.
[OpenAI GPT 3.5](https://openai.com/) | Used to generate descriptions for ingested columns. Selected for ease of use, but an OSS model like Mistral works just as well (you'll just need the hardware)
[Datahub](https://datahubproject.io/)| Serves as our metadata repository. GPT generated column descriptions, along wither technical metadata, would be visible in Datahub users interested in understanding their data and how it relates to other parts of their organization.
[JupyterHub](https://jupyter.org/hub) | Easy to use notebooks to test out ideas
[Superset](https://superset.apache.org/) | A visualization tool to create dashboards, graphics.  Not really used in this use case, but I included it since I already had it's yaml file downloaded.  Be aware those, it uses a lot of memory


## Prerequisites

Before you start, ensure your host system (MacOS) has the following software installed:

- **Docker**: A platform for developing, shipping, and running applications inside isolated environments called containers.
- **Kind (Kubernetes in Docker)**: A tool for running local Kubernetes clusters using Docker container nodes.
- **Helm**: A package manager for Kubernetes, allowing you to define, install, and upgrade complex Kubernetes applications.
- **Python 3.8 or higher**: A powerful programming language, essential for running scripts and additional tools in this project.
- **Pip**: A package installer for Python, used to install Python packages.

### Install Commands for MacOS

1. **Install Docker:**

   ```bash
   brew cask install docker
   ```
2. **Install kubectl**
   ```bash
   brew install kubectl
   ```
2. **Install Kind:**

   ```bash
   brew install kind
   ```

3. **Install Helm:**

   ```bash
   brew install helm
   ```

4. **Install Python 3.8+:**

   ```bash
   brew install python@3.8
   ```

   Or setup a virtual environment for this project

5. **Install Pip:**

   Pip is included with Python 3.4 and later. You can ensure it's up to date with:

   ```bash
   python3 -m pip install --upgrade pip
   ```

## Quick Start

1. **Clone the Repository**
   
   ```bash
   git clone https://github.com/msantana09/data_platform.git
   cd data-platform
   ```

2. **Initialize .env files**

   The project comes with several template files (e.g. .env-template) containing the default credentials and configurations for for the various services.  The command below copies the default template files to .env files, which are ignored by git. You can then modify the .env files as needed.

   ````bash
   ./platform.sh init
   ````
3. **Install project dependencies (Optional)**

   If you plan on doing any development you'll want to install these project dependencies.
   ```
   pip install -r requirements-dev.txt
   ```

4. **Configure use case credentials (Optional)**

   If you're planning on running the sample use case you'll need to configure your Kaggle and OpenAI credentials

   - **Kaggle**: Update `AIRFLOW_CONN_KAGGLE_DEFAULT` in file `services/airflow/.env` with your [Kaggle](https://www.kaggle.com/) username and key
   - **OpenAI**: Update `OPENAI_API_KEY` in file `services/models/.env` with your [OpenAI](https://openai.com/)  key


4. **Launch the Platform**

   This command will start MinIO, Hive, Trino, and Airflow
   ````bash
   (.venv) ➜  data_platform git:(main) ✗ ./platform.sh -h
   Usage: ./platform.sh <action> [-c|--cluster <cluster_name>] [-d|--delete-data] [sub_scripts...]

   Options:
   <action>                      The action to perform (init|start|shutdown|recreate)
   -c, --cluster <cluster_name>  Set the cluster name (default: platform)
   -d, --delete-data             Delete data flag (default: false)
   -h, --help                    Display this help message
   [sub_scripts...]              Additional scripts to run (default: core). 
                                 Valid names include: 
                                    airflow, datahub, hive, jupyter, minio, models, trino, spark, superset,
                                    lakehouse (minio, hive, trino ),
                                    core (lakehouse + airflow + spark + kafka)
   ````


## Launching the Platform

Provide a step-by-step guide to launch the platform, including starting Docker containers, deploying services with Kind and Helm, and verifying the setup.

## Architecture

Describe the architecture of the data platform, including an overview of components, data flow diagrams, and integration points.

## Contributing

Guidelines for contributing to the project, including how to submit issues, the pull request process, and coding standards.

## License

Include details about the license under which the project is released.

---

This README serves as a placeholder and should be customized to fit the specifics of the data platform project and its components.