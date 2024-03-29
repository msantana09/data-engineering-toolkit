from airflow.providers.trino.hooks.trino import TrinoHook
import csv
import io
import logging
from airflow.exceptions import AirflowException

logger = logging.getLogger(__name__)

def handle_failure(context):
    # Log the error
    error = context.get('exception')
    task_instance = context.get('task_instance')
    logger.error(f"Task {task_instance.task_id} failed with error: {error}")
    
    #  This would be a good place to send an email notification
    #  or a Slack alert, but we'll leave that for another day
    #  See https://airflow.apache.org/docs/apache-airflow/stable/_modules/airflow/utils/email.html
    #  and https://airflow.apache.org/docs/apache-airflow/stable/_modules/airflow/providers/slack/operators/slack.html

    raise AirflowException(error)
    
def get_columns_missing_comments(hook:TrinoHook, database:str, table:str)->list:
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

def create_llm_column_request_batches(columns:list, batch_size:int=5)->list:
    '''
    Returns a list of lists of columns to be used in the LLM API request
    '''

    cols_without_comment = [{"name":col[0], "type":col[1]} for col in columns]

    # splitting into batches to prevent API from timing out or token issues 
    cols_without_comment_batched = [cols_without_comment[i:i + batch_size] for i in range(0, len(cols_without_comment), batch_size)]
    return cols_without_comment_batched

def build_llm_column_request_payload_csv(dataset_context:str, table:str, columns:list) -> dict: 
    '''
    Returns a dictionary that can be used as the payload for the LLM API request
    '''
    payload = {
        "context": dataset_context,
        "tables": [
            {
                "name": table,
                "column_csv": list_of_dicts_to_csv(columns)
            } 
        ]
    }
    return payload

def build_comment_ddl(column_responses:list, database:str, table:str, prefix:str="(ChatGPT generated)")->list:
    '''
    Returns a list of SQL statements to be executed to update the column comments
    '''
    
    statements = []
    print(column_responses)
    for column in column_responses:
        # skipping columns with null descriptions
        if not column['description']:
            continue
        name = column['name']
        description = column['description'].replace("'", "''") 
        sql = f"COMMENT ON COLUMN {database}.{table}.{name} IS '{prefix} {description}'"
        statements.append(sql)
    return statements

def list_of_dicts_to_csv(data:list)->str:
    output = io.StringIO()
    keys = data[0].keys()
    dict_writer = csv.DictWriter(output, keys)
    dict_writer.writeheader()
    dict_writer.writerows(data)
    return output.getvalue()

def csv_to_list_of_dicts(csv_string:str)->list:
    csv_reader = csv.reader(csv_string.splitlines())
    field_names = next(csv_reader)
    values = []
    for row in csv_reader:
        values.append(dict(zip(field_names, row)))
    return values

def run_datahub_pipeline(recipe_path:str):
    from datahub.configuration.config_loader import load_config_file
    from datahub.ingestion.run.pipeline import Pipeline
    # Note that this will also resolve environment variables in the recipe.
    config = load_config_file(recipe_path)

    pipeline = Pipeline.create(config)
    pipeline.run()
    pipeline.raise_from_status()