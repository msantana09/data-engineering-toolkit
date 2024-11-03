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
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

    # gcc libssl-dev librdkafka-dev - dependencies needed for kafka integration https://stackoverflow.com/questions/72163907/unable-to-install-confluent-kafka-fatal-error-librdkafka-rdkafka-h-no-such-f


FROM airflow_base AS airflow_spark
########################
# Install Spark
########################

ENV SPARK_HOME="/opt/spark"
RUN mkdir -p ${SPARK_HOME}
# Define version ARGs
ARG SPARK_VERSION="3.5.3"
ARG ICEBERG_VERSION="1.4.2"
ARG AWS_SDK_VERSION="2.17.257"


# Download and install Spark
RUN curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
 && tar xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Setup Spark related environment variables
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*


# Download iceberg spark runtime
RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/${ICEBERG_VERSION}/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar \
 -Lo ${SPARK_HOME}/jars/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar

# Download Java AWS SDK
RUN curl https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/${AWS_SDK_VERSION}/bundle-${AWS_SDK_VERSION}.jar \
-Lo ${SPARK_HOME}/jars/bundle-${AWS_SDK_VERSION}.jar

# Download URL connection client required for S3FileIO
RUN curl https://repo1.maven.org/maven2/software/amazon/awssdk/url-connection-client/${AWS_SDK_VERSION}/url-connection-client-${AWS_SDK_VERSION}.jar\
 -Lo ${SPARK_HOME}/jars/url-connection-client-${AWS_SDK_VERSION}.jar

# Download AWS third party bundle
RUN curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.587/aws-java-sdk-bundle-1.12.587.jar\
 -Lo ${SPARK_HOME}/jars/aws-java-sdk-bundle-1.12.587.jar

# Download AWS hadoop integration dependency
RUN curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar\
 -Lo ${SPARK_HOME}/jars/hadoop-aws-3.3.4.jar

FROM airflow_spark AS airflow_requirements


USER airflow

COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

FROM airflow_requirements AS airflow_dags

COPY dags /opt/airflow/dags
COPY include /opt/airflow/include
COPY plugin[s] /opt/airflow/plugins
COPY spark_scripts /opt/airflow/spark_scripts
COPY lib /opt/airflow/lib

ENV PYTHONPATH="${PYTHONPATH}:${AIRFLOW_HOME}/include"
