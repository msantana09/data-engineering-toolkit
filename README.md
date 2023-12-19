# Data Platform Project
![Platform Overview](images/data_platform_overview.png)

## Introduction

Goal is to create a dev data platform running on your local machine.  Something that:

- runs on kubernetes in docker, and has persistent volumes so your data is not loss
- has tools for ingesting, transforming, storing, querying, exploring, cataloging, and visualizing data.  All fully configured to work with each other
- and includes a sample data ingestion use case utilizing LLMs 


Cool, I got you! This project is meant to be a local playground for Data Engineers. It's designed to be fairly modular to allow users to configured based on their needs.



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

3. **Configure use case credentials (Optional)**

   If you're planning on running the sample use case you'll need to configure your Kaggle and OpenAI credentials

   - **Kaggle**: Update `AIRFLOW_CONN_KAGGLE_DEFAULT` in file `services/airflow/.env` with your [Kaggle](https://www.kaggle.com/) username and key
   - **OpenAI**: Update `OPENAI_API_KEY` in file `services/models/.env` with your [OpenAI](https://openai.com/)  key


4. **Launch the Platform**

   This command will start MinIO, Hive, Trino, and Airflow
   ````bash
   ./platform.sh start core
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