# Data Engineering Toolkit 

## Overview

Welcome to the Data Engineering Toolkit! This project provides a complete local development environment, pre-configured with the essential tools for modern data engineering.

Setting up a development environment with multiple tools can be complex and time-consuming, especially if you're unfamiliar with the ecosystem. After encountering this challenge on several side projects, I decided to gather all my setup scripts and solutions into this toolkit to streamline the process.

The primary goal of this project is to bootstrap innovation by offering a ready-to-use suite of tools that work seamlessly out of the box (OOTB). Additionally, it features an end-to-end use case that showcases a typical data product lifecycle.

Also included are a collection of [Jupyter notebooks](/services/jupyter/notebooks/airbnb/) to help you explore ingested data interactively and run APIs, such as sentiment analysis, available in the toolkit.

## Key Use Cases

### 1. Generate Column Descriptions for a Kaggle Dataset in a Lakehouse
In this example, we'll ingest a Kaggle dataset using custom Airflow hooks and operators, process it with the integrated tools, and generate column descriptions using LLMs. For more details, check the [use case guide](/UseCase.md).
- **Tools involved**: Airflow, MinIO, Spark, Hive, Iceberg, Trino, LLMs, DataHub, and Kafka.



## Architecture

The platform is built using a mostly open-source stack, integrating several powerful data engineering tools:

![Platform Overview](images/data_platform_overview.png)

| Tool | Description | Access Links |
| --- | --- | --- |
| [MinIO](https://min.io/) | Object storage with S3-like API, but keeps data locally. | [UI](http://localhost:9001/) \| [API](http://localhost:9000/) (minio:minio123) |
| [Apache Airflow](https://airflow.apache.org/) | Workflow orchestrator for data pipelines. | [UI](http://localhost:8081/) (airflow:airflow) |
| [Trino](https://trino.io/) | Distributed query engine for querying data in S3/MinIO using SQL. | [API](http://localhost:8082/) \| [UI](http://localhost:8082/ui/) (trino:trino) |
| [JupyterHub](https://jupyter.org/hub) | Web-based notebook environment for running data exploration and analysis. | [UI](http://localhost:8083/) |
| [DataHub](https://datahubproject.io/) | Metadata repository where GPT-generated column descriptions and other technical metadata are stored. | [UI](http://localhost:8084/) (datahub:datahub) |
| [Apache Kafka](https://kafka.apache.org/) | Distributed event streaming platform used for messaging between services. | [Kafka UI](http://localhost:9090/) |
| [Apache Hive](https://cwiki.apache.org/confluence/display/hive/design) | Metadata store for our data lake, relied on by Spark and Trino. | |
| [Apache Iceberg](https://iceberg.apache.org/) | Table format used by Spark jobs, enabling data querying via Trino or SparkSQL. | |
| [Apache Spark](https://spark.apache.org/) | Distributed processing engine used for data transformation and analysis. | |
| [OpenAI GPT-3.5](https://openai.com/) | Used for generating column descriptions, though OSS models like Mistral can be swapped in with proper hardware. | |
| [Python](https://www.python.org/) | Primary programming language for the data pipelines. | |

## Prerequisites

Before you start, ensure your host system (MacOS) has the following software installed:

- **Docker**: A platform for developing, shipping, and running applications inside isolated environments called containers.
- **Kind (Kubernetes in Docker)**: A tool for running local Kubernetes clusters using Docker container nodes.
- **Helm**: A package manager for Kubernetes, allowing you to define, install, and upgrade complex Kubernetes applications.
- **Python 3.11 or higher**: A powerful programming language, essential for running scripts and additional tools in this project.
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

4. **Install Python 3.11+:**

   ```bash
   brew install python@3.11
   ```

   Or setup a virtual environment for this project

5. **Install Pip:**

   Pip is included with Python 3.4 and later. You can ensure it's up to date with:

   ```bash
   python3 -m pip install --upgrade pip
   ```

## Quick Start

Follow these steps to get up and running quickly:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/msantana09/data-engineering-toolkit.git
   cd data-engineering-toolkit
   ```

   > **Note**: To ensure relative file references work correctly (e.g., for `kind-config.yaml`), be sure to run the `platform.sh` script from the root directory of the project.


2. **Initialize .env files**

   The project comes with several template files (e.g. .env-template) containing the default credentials and configurations for the various services.  The command below copies the default template files to .env files, which are then ignored by git. You can then modify the .env files as needed.

   ````bash
   ./platform.sh init
   ````
3. **Install project dependencies**

   These are dependencies needed for local development, and for a few unit tests executed when Airflow is started.
   ```
   pip install -r requirements-dev.txt
   ```

4. **Configure Credentials (Optional)**:
   If you're planning to run the sample [use case](/UseCase.md), you'll need to configure your Kaggle and OpenAI credentials:
   - **Kaggle**: Add your [Kaggle](https://www.kaggle.com/) u credentials to the `AIRFLOW_CONN_KAGGLE_DEFAULT` entry in `services/airflow/.env`.
   - **OpenAI**: Add your [OpenAI](https://openai.com/) API key to the `OPENAI_API_KEY` entry in `services/models/.env`.

5. **Launch the Platform**:
   Run the platform with the desired services:
   ```bash
   ./platform.sh start core models datahub
   ```

   Use the `-h` flag for more options:
   ```bash
   ./platform.sh -h
   ```

   Examples:
   ```bash
   # Start Airflow and MinIO:
   ./platform.sh start airflow minio

   # Start the core services and additional models:
   ./platform.sh start core models datahub

   # Shutdown MinIO and delete persisted data:
   ./platform.sh shutdown minio -d

   # Shutdown the entire cluster:
   ./platform.sh shutdown
   ```
6. **Monitor Services**:
   Once services are running, you can use `kubectl` to monitor activity:
   ```bash
   # List pods in the Airflow namespace
   kubectl get pods -n airflow

   # Tail logs of a specific pod
   kubectl logs -f <pod name> -n <namespace>
   ```
# Additional Resources
- [Running Kafka on kubernetes for local development](https://dev.to/thegroo/running-kafka-on-kubernetes-for-local-development-2a54)
- [How to make a Helm chart in 10 minutes](https://opensource.com/article/20/5/helm-charts)
- [analytical_dp_with_sql](https://github.com/josephmachado/analytical_dp_with_sql/tree/main)