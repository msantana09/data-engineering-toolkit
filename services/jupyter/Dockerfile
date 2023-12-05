FROM custom-spark-python
USER root
ENV IJAVA_CLASSPATH=/opt/spark/jars/*

RUN mkdir -p /opt/spark/localwarehouse /opt/spark/notebooks /opt/spark/warehouse /opt/spark/spark-events 

WORKDIR /home/spark

# Install python deps
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Add the PySpark classes to the Python path:
SHELL ["/bin/bash", "-c"]

ENV PYSPARK_PYTHON python3
ENV PYTHONPATH=$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH
#RUN export PYTHONPATH=$(ZIPS=("$SPARK_HOME"/python/lib/.zip); IFS=:; echo "${ZIPS[]}"):$PYTHONPATH

# Setup Spark related environment variables
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"

# Add a notebook command
RUN echo '#! /bin/sh' >> /bin/notebook \
 && echo 'export PYSPARK_DRIVER_PYTHON=jupyter' >> /bin/notebook \
 && echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"lab --notebook-dir=/home/spark/notebooks \
    --ip='0.0.0.0' --NotebookApp.token='' --port=8888 --no-browser --allow-root\"" >> /bin/notebook \
 && echo '$SPARK_HOME/bin/pyspark ' >> /bin/notebook \
 && chmod u+x /bin/notebook

CMD ["notebook"]