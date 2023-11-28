import os
from typing import Any, Dict, Optional
from py4j.java_gateway import JavaObject
from pyspark import SparkContext
from pyspark.sql import SparkSession

class CustomSparkSession(SparkSession):

    def __init__(self, app_name="CustomApp", master="local[*]", config_dict=None):
        """
        Initialize the custom SparkSession.

        :param app_name: Name of the Spark application.
        :param master: Master URL to connect to.
        :param config_dict: Dictionary of configurations to set.
        """
        builder = SparkSession.builder.appName(app_name).master(master)

        # Apply additional configurations from config_dict if provided
        if config_dict and isinstance(config_dict, dict):
            for key, value in config_dict.items():
                builder = builder.config(key, value)

        # Initialize SparkSession with the configured builder
        self.spark_session = builder.getOrCreate()