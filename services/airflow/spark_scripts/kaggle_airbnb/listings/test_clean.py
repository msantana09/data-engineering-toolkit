import pytest
from clean import convert_boolean_columns, drop_unneeded_columns, find_price_columns, identify_bool_columns, standardize_prices
from pyspark.sql.types import DoubleType, BooleanType
from pyspark.sql import SparkSession

@pytest.fixture(scope="module")
def spark():
    return SparkSession.builder.master("local[1]").appName("Test Session").getOrCreate()


def test_drop_unneeded_columns(spark):
    data = [("John Doe", 30, "jdoe@example.com"), ("Jane Doe", 25, "jane@example.com")]
    df = spark.createDataFrame(data, ["name", "age", "email"])
    result = drop_unneeded_columns(df, ["name"])
    assert "name" not in result.columns

def test_identify_bool_columns(spark):
    data = [("t", "yes"), ("f", "no")]
    df = spark.createDataFrame(data, ["bool_col", "str_col"])
    result = identify_bool_columns(df)
    assert result == ["bool_col"]


def test_convert_boolean_columns(spark):
    data = [("t",), ("f",)]
    df = spark.createDataFrame(data, ["bool_col"])
    result = convert_boolean_columns(df)
    assert result.schema["bool_col"].dataType == BooleanType()

def test_find_price_columns(spark):
    data = [("$100", "100"), ("$200", "200")]
    df = spark.createDataFrame(data, ["price_col", "num_col"])
    result = find_price_columns(df)
    assert result == ["price_col"]


def test_standardize_prices(spark):
    data = [("$100",), ("$200",)]
    df = spark.createDataFrame(data, ["price_col"])
    result = standardize_prices(df)
    assert result.collect() == [(100.0,), (200.0,)]
