FROM apache/airflow:2.10.2-python3.11 AS airflow_base
USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        unzip \
        procps \
        rsync \
        openjdk-17-jdk \
        ant \
        build-essential \
        software-properties-common \
        ssh  \
        groff \
        gcc libssl-dev librdkafka-dev \
        mandoc &&\
    rm -rf /var/lib/apt/lists/*

    # gcc libssl-dev librdkafka-dev - dependencies needed for kafka integration 
    # https://stackoverflow.com/questions/72163907/unable-to-install-confluent-kafka-fatal-error-librdkafka-rdkafka-h-no-such-f

USER airflow

# Install Python dependencies
FROM airflow_base AS dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

# Download additional JARs
ENV SPARK_HOME="/home/airflow/.local/lib/python3.11/site-packages/pyspark"
ENV SPARK_JARS_PATH="${SPARK_HOME}/jars"
ARG MAVEN_REPO="https://repo1.maven.org/maven2"

# Download iceberg spark runtime
ARG ICEBERG_VERSION="1.4.3"
ARG SPARK_SCALA_VERSION="3.5_2.12"
RUN curl ${MAVEN_REPO}/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SCALA_VERSION}/${ICEBERG_VERSION}/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar \
 -Lo ${SPARK_JARS_PATH}/iceberg-spark-runtime-${SPARK_SCALA_VERSION}-${ICEBERG_VERSION}.jar

# Download Java AWS SDK
ARG AWS_SDK_VERSION="2.17.257"
RUN curl ${MAVEN_REPO}/software/amazon/awssdk/bundle/${AWS_SDK_VERSION}/bundle-${AWS_SDK_VERSION}.jar \
 -Lo ${SPARK_JARS_PATH}/bundle-${AWS_SDK_VERSION}.jar

# Download AWS third party bundle (req for hadoop-aws)
ARG AWS_3RD_PARTY_BUNDLE_VERSION="1.12.777"
RUN curl ${MAVEN_REPO}/com/amazonaws/aws-java-sdk-bundle/${AWS_3RD_PARTY_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_3RD_PARTY_BUNDLE_VERSION}.jar\
 -Lo ${SPARK_JARS_PATH}/aws-java-sdk-bundle-${AWS_3RD_PARTY_BUNDLE_VERSION}.jar

# Download AWS hadoop integration dependency 
# use 3.3.4, which is compatible with pyspark airflow provider
ARG HADOOP_VERSION="3.3.4"
RUN curl ${MAVEN_REPO}/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar\
 -Lo ${SPARK_JARS_PATH}/hadoop-aws-${HADOOP_VERSION}.jar

# Copy DAGs and other Airflow resources
FROM dependencies AS airflow_dags

COPY dags /opt/airflow/dags
COPY include /opt/airflow/include
COPY plugin[s] /opt/airflow/plugins
COPY spark_scripts /opt/airflow/spark_scripts
COPY lib /opt/airflow/lib

ENV PYTHONPATH="${PYTHONPATH}:${AIRFLOW_HOME}/include"
