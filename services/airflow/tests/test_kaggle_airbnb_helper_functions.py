import os
import sys
import unittest
from unittest.mock import Mock

# Get the absolute path of the directory containing the modules
module_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../'))
# Append this directory to sys.path
sys.path.append(module_dir)

from include.helper_functions.kaggle_airbnb import identify_columns_missing_comments, create_llm_request_batches, build_model_api_payload_csv,list_of_dicts_to_csv

class TestKaggleAirbnb(unittest.TestCase):
    def setUp(self):
        self.hook = Mock()
        self.hook.get_records.return_value = [('col1', 'int'), ('col2', 'string')]

    def test_identify_columns_missing_comments(self):
        result = identify_columns_missing_comments(self.hook, 'database', 'table')
        self.assertEqual(result, [('col1', 'int'), ('col2', 'string')])

    def test_create_llm_request_batches(self):
        columns = [('col1', 'int'), ('col2', 'string'), ('col3', 'float'), ('col4', 'int'), ('col5', 'string'), ('col6', 'float')]
        result = create_llm_request_batches(columns)
        self.assertEqual(len(result), 2)
        self.assertEqual(len(result[0]), 5)
        self.assertEqual(len(result[1]), 1)

    def test_build_model_api_payload(self):
        columns = [{'name': 'col1', 'type': 'int'}, {'name': 'col2', 'type': 'string'}]
        result = build_model_api_payload_csv('context', 'table', columns)


        self.assertEqual(result['context'], 'context')
        self.assertEqual(result['tables'][0]['name'], 'table')
        self.assertEqual(result['tables'][0]['column_csv'], list_of_dicts_to_csv(columns))

if __name__ == '__main__':
    unittest.main()