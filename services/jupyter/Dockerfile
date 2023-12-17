FROM custom-spark-python as jupyter_base

USER root

ENV IJAVA_CLASSPATH=/opt/spark/jars/*
# Install python deps
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Add the PySpark classes to the Python path:
ENV PYSPARK_PYTHON python3
ENV PYTHONPATH=$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH

# Setup Spark related environment variables
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"

FROM jupyter_base as jupyter
# Add a notebook command
RUN echo '#! /bin/sh' >> /bin/notebook \
 && echo 'export PYSPARK_DRIVER_PYTHON=jupyter' >> /bin/notebook \
 && echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"lab --notebook-dir=/opt/spark/notebooks \
    --ip='0.0.0.0' \
    --NotebookApp.token='' \
    --port=8888 \
    --no-browser \
    --allow-root \ 
    --FileContentsManager.delete_to_trash=false\"" >> /bin/notebook \
 && echo '$SPARK_HOME/bin/pyspark ' >> /bin/notebook \
 && chmod u+x /bin/notebook 
 
RUN mkdir -p /opt/spark/localwarehouse  /opt/spark/warehouse /opt/spark/spark-events    /opt/spark/notebooks

WORKDIR   /opt/spark/notebooks
CMD ["notebook"]