FROM apache/hive:4.0.0-beta-1

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base curl && \
    rm -rf /var/lib/apt/lists/*

RUN chown hive:hive /opt/hive/conf/hive-site.xml && \
    chmod 664 /opt/hive/conf/hive-site.xml

# Download Postgres JDBC driver
RUN curl https://jdbc.postgresql.org/download/postgresql-42.7.0.jar\
 -Lo /opt/hive/lib/postgresql-42.7.0.jar

USER hive

# Download AWS dependencies for Hadoop
ARG MAVEN_REPO="https://repo1.maven.org/maven2"
ARG HADOOP_HOME="/opt/hadoop"
ARG AWS_3RD_PARTY_BUNDLE_VERSION="1.12.777"
ARG HADOOP_VERSION="3.3.1"

# Download AWS third party bundle (req for hadoop-aws)
RUN curl ${MAVEN_REPO}/com/amazonaws/aws-java-sdk-bundle/${AWS_3RD_PARTY_BUNDLE_VERSION}/aws-java-sdk-bundle-${AWS_3RD_PARTY_BUNDLE_VERSION}.jar \
        -Lo ${HADOOP_HOME}/share/hadoop/common/aws-java-sdk-bundle-${AWS_3RD_PARTY_BUNDLE_VERSION}.jar  && \
    curl ${MAVEN_REPO}/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar \
        -Lo ${HADOOP_HOME}/share/hadoop/common/hadoop-aws-${HADOOP_VERSION}.jar

# Copy entrypoint script with environment variable replacements for hive-site.xml
COPY entrypoint.sh /opt/hive/entrypoint.sh

ENTRYPOINT ["/opt/hive/entrypoint.sh"]
