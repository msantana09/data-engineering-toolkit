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
    rm -rf /var/lib/apt/lists/*


# Install AWS CLI
# RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
# specifying version 2.13.33 due to bug https://github.com/aws/aws-cli/issues/8320

RUN curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64-2.13.33.zip -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm awscliv2.zip \
 && rm -rf aws/

# Set up home directory for spark user
RUN mkdir -p /home/spark

# Set Spark UID and change ownership of the home directory
ARG spark_uid=185
RUN chown -R "${spark_uid}:0" /home/spark

USER ${spark_uid}

# Download necessary JARs in a single layer 
ARG MAVEN_REPO="https://repo1.maven.org/maven2"
ENV JARS_PATH="${SPARK_HOME}/jars"
ARG ICEBERG_VERSION="1.4.3"
ARG SPARK_SCALA_VERSION="3.5_2.12"
ARG AWS_SDK_VERSION="2.17.257"
ARG AWS_3RD_PARTY_BUNDLE_VERSION="1.12.777"
ARG HADOOP_VERSION="3.3.4"
RUN curl -Lo ${JARS_PATH}/iceberg-spark-runtime-${SPARK_SCALA_VERSION}-${ICEBERG_VERSION}.jar \
        ${MAVEN_REPO}/org/apache/iceberg/iceberg-spark-runtime-${SPARK_SCALA_VERSION}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_SCALA_VERSION}-${ICEBERG_VERSION}.jar && \
    curl -Lo ${JARS_PATH}/bundle-${AWS_SDK_VERSION}.jar \
        ${MAVEN_REPO}/software/amazon/awssdk/bundle/${AWS_SDK_VERSION}/bundle-${AWS_SDK_VERSION}.jar && \
    curl -Lo ${JARS_PATH}/aws-java-sdk-bundle-${AWS_3RD_PARTY_BUNDLE_VERSION}.jar \
        ${MAVEN_REPO}/com/amazonaws/aws-java-sdk-bundle/${AWS_3RD_PARTY_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_3RD_PARTY_BUNDLE_VERSION}.jar && \
    curl -Lo ${JARS_PATH}/hadoop-aws-${HADOOP_VERSION}.jar \
        ${MAVEN_REPO}/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar

# Copy configuration files into $SPARK_HOME/conf
COPY conf/spark-defaults.conf "$SPARK_HOME/conf/spark-defaults.conf"
COPY conf/log4j.properties "$SPARK_HOME/conf/log4j.properties"