FROM apache/spark:3.5.3-python3

USER root
# Install tools required by the OS
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      vim \
      unzip \
      rsync \
      build-essential \
      software-properties-common \
      ssh  \
      groff \
      mandoc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Install AWS CLI
# RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
# specifying version 2.13.33 due to bug https://github.com/aws/aws-cli/issues/8320

RUN curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64-2.13.33.zip -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm awscliv2.zip \
 && rm -rf aws/

RUN mkdir -p /home/spark

ARG spark_uid=185
RUN chown -R "${spark_uid}:0" /home/spark
USER ${spark_uid}
# Copy jars needed for pipelines (e.g. Spark, Iceberg, etc.)
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


# Copy the default configurations into $SPARK_HOME/conf
COPY  conf/spark-defaults.conf  "$SPARK_HOME/conf/spark-defaults.conf"
COPY  conf/log4j.properties  "$SPARK_HOME/conf/log4j.properties"


