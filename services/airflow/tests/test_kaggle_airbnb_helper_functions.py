import os
import sys
import unittest
from unittest.mock import Mock

# Get the absolute path of the directory containing the modules
module_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../'))
# Append this directory to sys.path
sys.path.append(module_dir)

from include.helper_functions.kaggle_airbnb import get_columns_missing_comments, create_llm_column_request_batches, build_llm_column_request_payload_csv,list_of_dicts_to_csv,build_comment_ddl,csv_to_dict_array

class TestKaggleAirbnb(unittest.TestCase):
    def setUp(self):
        self.hook = Mock()
        self.hook.get_records.return_value = [('col1', 'int'), ('col2', 'string')]

    def test_get_columns_missing_comments(self):
        result = get_columns_missing_comments(self.hook, 'database', 'table')
        self.assertEqual(result, [('col1', 'int'), ('col2', 'string')])

    def test_create_llm_request_batches(self):
        columns = [('col1', 'int'), ('col2', 'string'), ('col3', 'float'), ('col4', 'int'), ('col5', 'string'), ('col6', 'float')]
        result = create_llm_column_request_batches(columns)
        self.assertEqual(len(result), 2)
        self.assertEqual(len(result[0]), 5)
        self.assertEqual(len(result[1]), 1)

    def test_build_llm_column_request_payload_csv(self):
        columns = [{'name': 'col1', 'type': 'int'}, {'name': 'col2', 'type': 'string'}]
        result = build_llm_column_request_payload_csv('context', 'table', columns)

        self.assertEqual(result['context'], 'context')
        self.assertEqual(result['tables'][0]['name'], 'table')
        self.assertEqual(result['tables'][0]['column_csv'], list_of_dicts_to_csv(columns))

    def test_build_comment_ddl(self):
        database = 'test_db'
        table = 'test_table'
        column_responses = [
            {'name': 'col1', 'description': 'test comment'}, 
            {'name': 'col2', 'description': 'test comment 2'}
            ]
        result = build_comment_ddl(column_responses, database, table)
        expected = [f"COMMENT ON COLUMN {database}.{table}.col1 IS '(ChatGPT generated) test comment'",
                    f"COMMENT ON COLUMN {database}.{table}.col2 IS '(ChatGPT generated) test comment 2'"]
        assert result == expected

    def test_list_of_dicts_to_csv(self):
        test_list = [{'name': 'John', 'age': 30}, {'name': 'Jane', 'age': 25}]
        expected = 'name,age\nJohn,30\nJane,25\n'
        # csv.DictWriter returns \r\n for newlines, so we need to replace \r with empty string
        assert list_of_dicts_to_csv(test_list).replace('\r','') == expected

    def test_csv_to_dict_array(self):
        expected = [{'name': 'John', 'age': '30'}, {'name': 'Jane', 'age': '25'}]
        test_csv = 'name,age\nJohn,30\nJane,25\n' 
        result = csv_to_dict_array(test_csv)
        assert result == expected

if __name__ == '__main__':
    unittest.main()