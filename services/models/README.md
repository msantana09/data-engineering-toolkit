# API Documentation for Sentiment Analysis, Column Descriptions, and Data Quality Check Generation

This README provides instructions for using the three main functionalities of the project: Sentiment Analysis, Column Descriptions, and Data Quality (DQ) Check Generation. Each of these features is accessible via API endpoints, as shown below.


---

### 1. Sentiment Analysis

This endpoint evaluates the sentiment of a provided text input and returns a sentiment classification (e.g., "Very Negative").

#### Endpoint

```bash
POST /api/v1/models/sentiment
```

#### Request Example

```bash
curl -X 'POST' 'http://localhost:8080/api/v1/models/sentiment' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{"text": "this is awful"}'
```

#### Sample Response

```json
{
  "result": "Very Negative"
}
```

---

### 2. Column Descriptions

This endpoint generates detailed descriptions for columns within a specified context (e.g., an AirBnB dataset).

#### Endpoint

```bash
POST /api/v1/models/describe_columns
```

#### Request Example

```bash
curl -X 'POST'  'http://localhost:8080/api/v1/models/describe_columns' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d ' {"context": "AirBnB", "tables": [{"name": "listings", "column_csv": "name,type\r\nid,integer\r\nname,varchar\r\nsummary,varchar\r\n"}]}'

```
#### Sample Response

```json
{
  "content": "\"name\",\"description\"\n\"id\",\"Unique identifier for each listing. This column contains integers, representing the ID of each listing in the AirBnB database.\"\n\"name\",\"The name/title of the listing entered by the host.\"\n\"summary\",\"A brief summary/description of the listing provided by the host.\"",
  "usage": {
    "completion_tokens": 60,
    "prompt_tokens": 225,
    "total_tokens": 285
  }
}
```

---

### 3. Data Quality (DQ) Check Generation

This endpoint generates code snippets to perform data quality checks on specified columns within a given context (e.g., an AirBnB dataset).

#### Endpoint

```bash
POST /api/v1/models/dq_check
```

#### Request Example

```bash
curl -X 'POST' 'http://localhost:8080/api/v1/models/dq_check' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{"context": "AirBnB", "tables": [{"name": "listings", "column_csv": "name,type\r\nid,integer\r\nname,varchar\r\nsummary,varchar\r\n"}]}'
```

#### Sample Response

```json
{
  "content": "[{\n    \"column_name\":\"id\",\n    \"dq_checks\":[\n        {\n        \"id\":\"id_not_null\",\n        \"code\": \"results = df.filter(df.id.isNull()).count() == 0\"\n        },\n        {\n        \"id\":\"id_positive\",\n        \"code\": \"results = df.filter(df.id < 0).count() == 0\"\n        },\n        {\n        \"id\":\"id_unique\",\n        \"code\": \"results = df.select('id').distinct().count() == df.count()\"\n        }\n    ]\n},\n{\n    \"column_name\":\"name\",\n    \"dq_checks\":[\n        {\n        \"id\":\"name_not_null\",\n        \"code\": \"results = df.filter(df.name.isNull()).count() == 0\"\n        },\n        {\n        \"id\":\"name_length\",\n        \"code\": \"results = df.filter(length(df.name) > 100).count() == 0\"\n        },\n        {\n        \"id\":\"name_unique\",\n        \"code\": \"results = df.select('name').distinct().count() == df.count()\"\n        }\n    ]\n},\n{\n    \"column_name\":\"summary\",\n    \"dq_checks\":[\n        {\n        \"id\":\"summary_not_null\",\n        \"code\": \"results = df.filter(df.summary.isNull()).count() == 0\"\n        },\n        {\n        \"id\":\"summary_length\",\n        \"code\": \"results = df.filter(length(df.summary) > 500).count() == 0\"\n        },\n        {\n        \"id\":\"summary_keyword\",\n        \"code\": \"results = df.filter(lower(df.summary).like('%keyword%')).count() == 0\"\n        }\n    ]\n}]",
  "usage": {
    "completion_tokens": 342,
    "prompt_tokens": 327,
    "total_tokens": 669
  }
}
