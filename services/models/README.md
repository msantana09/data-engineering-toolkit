TODO - placeholder

```bash
    
    # sentiment analysis
    ##################
     curl -X 'POST' 'http://localhost:8080/api/v1/models/sentiment' \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{"text": "this is awful"}'
    # result
    # {"result":"Very Negative"}


    # column descriptions
    ##################
    curl -X 'POST'  'http://localhost:8080/api/v1/models/describe_columns' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d ' {"context": "AirBnB", "tables": [{"name": "listings", "column_csv": "name,type\r\nid,integer\r\nname,varchar\r\nsummary,varchar\r\n"}]}'

    #result
    # {"content":"\"name\",\"description\"\n\"id\",\"Unique identifier for each listing. This column contains integers, representing the ID of each listing in the AirBnB database.\"\n\"name\",\"The name/title of the listing entered by the host.\"\n\"summary\",\"A brief summary/description of the listing provided by the host.\"","usage":{"completion_tokens":60,"prompt_tokens":225,"total_tokens":285}}


    # DQ check generation
    ##################
    curl -X 'POST'  'http://localhost:8080/api/v1/models/dq_check' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d ' {"context": "AirBnB", "tables": [{"name": "listings", "column_csv": "name,type\r\nid,integer\r\nname,varchar\r\nsummary,varchar\r\n"}]}'

    # Result
    # {"content":"[{\n    \"column_name\":\"id\",\n    \"dq_checks\":[\n        {\n        \"id\":\"id_not_null\",\n        \"code\": \"results = df.filter(df.id.isNull()).count() == 0\"\n        },\n        {\n        \"id\":\"id_positive\",\n        \"code\": \"results = df.filter(df.id < 0).count() == 0\"\n        },\n        {\n        \"id\":\"id_unique\",\n        \"code\": \"results = df.select('id').distinct().count() == df.count()\"\n        }\n    ]\n},\n{\n    \"column_name\":\"name\",\n    \"dq_checks\":[\n        {\n        \"id\":\"name_not_null\",\n        \"code\": \"results = df.filter(df.name.isNull()).count() == 0\"\n        },\n        {\n        \"id\":\"name_length\",\n        \"code\": \"results = df.filter(length(df.name) > 100).count() == 0\"\n        },\n        {\n        \"id\":\"name_unique\",\n        \"code\": \"results = df.select('name').distinct().count() == df.count()\"\n        }\n    ]\n},\n{\n    \"column_name\":\"summary\",\n    \"dq_checks\":[\n        {\n        \"id\":\"summary_not_null\",\n        \"code\": \"results = df.filter(df.summary.isNull()).count() == 0\"\n        },\n        {\n        \"id\":\"summary_length\",\n        \"code\": \"results = df.filter(length(df.summary) > 500).count() == 0\"\n        },\n        {\n        \"id\":\"summary_keyword\",\n        \"code\": \"results = df.filter(lower(df.summary).like('%keyword%')).count() == 0\"\n        }\n    ]\n}]","usage":{"completion_tokens":342,"prompt_tokens":327,"total_tokens":669}}%            

```