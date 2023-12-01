FROM apache/hive:4.0.0-alpha-2

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      gettext-base \
      curl &&\
    apt-get clean  

#COPY conf/hive-site.xml /opt/hive/conf/hive-site.xml
RUN chown hive:hive /opt/hive/conf/hive-site.xml && \
    chmod 664 /opt/hive/conf/hive-site.xml

USER hive

# Download AWS third party bundle
RUN curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.587/aws-java-sdk-bundle-1.12.587.jar\
 -Lo /opt/hadoop/share/hadoop/common/aws-java-sdk-bundle-1.12.587.jar
 
# Download AWS hadoop integration dependency
# hive 4.0.0-alpha-2 uses hadoop 3.3.1
RUN curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.1/hadoop-aws-3.3.1.jar\
 -Lo /opt/hadoop/share/hadoop/common/hadoop-aws-3.3.1.jar
 
# using a custom entrypoint script to add the replace env variables in hive-site.xml
COPY entrypoint.sh /opt/hive/entrypoint.sh

ENTRYPOINT ["/opt/hive/entrypoint.sh"]
