FROM apache/airflow:2.7.3 as airflow_base
USER root

# Install OpenJDK-11
RUN apt-get update && \
    apt-get install -y \
        unzip \
        procps \
        rsync \
        openjdk-11-jdk \
        ant \
        build-essential \
        software-properties-common \
        ssh  \
        groff \
        mandoc &&\
    apt-get clean;
# Set JAVA_HOME (*arm64 or *amd64)
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-arm64 
RUN export JAVA_HOME

FROM airflow_base as airflow_spark
########################
# Install Spark
########################

ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
RUN mkdir -p ${SPARK_HOME}
ENV SPARK_VERSION="3.5.0"

# Download and install Spark
RUN curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
 && tar xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Setup Spark related environment variables
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*


# Download iceberg spark runtime
RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.4.2/iceberg-spark-runtime-3.5_2.12-1.4.2.jar \
 -Lo ${SPARK_HOME}/jars/iceberg-spark-runtime-3.5_2.12-1.4.2.jar

# Download Java AWS SDK
RUN curl https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.17.257/bundle-2.17.257.jar \
-Lo ${SPARK_HOME}/jars/bundle-2.17.257.jar

# Download URL connection client required for S3FileIO
RUN curl https://repo1.maven.org/maven2/software/amazon/awssdk/url-connection-client/2.17.257/url-connection-client-2.17.257.jar\
 -Lo ${SPARK_HOME}/jars/url-connection-client-2.17.257.jar

# Download AWS third party bundle
RUN curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.587/aws-java-sdk-bundle-1.12.587.jar\
 -Lo ${SPARK_HOME}/jars/aws-java-sdk-bundle-1.12.587.jar

# Download AWS hadoop integration dependency
RUN curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar\
 -Lo ${SPARK_HOME}/jars/hadoop-aws-3.3.4.jar

FROM airflow_spark as airflow_requirements
USER airflow

COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

FROM airflow_requirements as airflow_dags

COPY dags/ /opt/airflow/dags
COPY include/ /opt/airflow/include
COPY plugin[s]/ /opt/airflow/plugins
COPY spark_scripts /opt/airflow/spark_scripts
COPY lib /opt/airflow/lib

ENV PYTHONPATH="${PYTHONPATH}:/opt/airflow/include"
