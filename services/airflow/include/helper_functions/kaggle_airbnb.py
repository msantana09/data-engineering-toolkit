from airflow.providers.trino.hooks.trino import TrinoHook

def identify_columns_missing_comments(hook:TrinoHook, database:str, table:str)->list:
    '''
    Returns a list of columns that are missing comments
    '''
    query = f"""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE 
            table_schema = '{database}' 
            AND table_name = '{table}'
            AND comment IS NULL;
        """
    return list(hook.get_records(query) )


def create_llm_request_batches(columns:list, batch_size:int=5):
    '''
    Returns a list of lists of columns to be used in the LLM API request
    '''

    cols_without_comment = [{"name":col[0], "type":col[1]} for col in columns]

    # splitting into chunks of 5 columns to prevent API from timing out or token issues 
    cols_without_comment_batched = [cols_without_comment[i:i + batch_size] for i in range(0, len(cols_without_comment), batch_size)]
    return cols_without_comment_batched

def build_model_api_payload(dataset_context:str, table:str, columns:list) -> dict: 
    '''
    Returns a dictionary that can be used as the payload for the LLM API request
    '''
    payload = {
        "context": dataset_context,
        "tables": [
            {
                "name": table,
                "columns": columns
            } 
        ]
    }
    return payload

def build_comment_sql(column_responses:list, database:str, table:str, prefix:str="(ChatGPT generated) "):
    '''
    Returns a list of SQL statements to be executed to update the column comments
    '''
    
    statements = []
    for column in column_responses:
        # skipping columns with null descriptions
        if not column['description']:
            continue
        name = column['name']
        description = column['description'].replace("'", "''") 
        sql = f"COMMENT ON COLUMN {database}.{table}.{name} IS '{prefix} {description}'"
        statements.append(sql)
    return statements