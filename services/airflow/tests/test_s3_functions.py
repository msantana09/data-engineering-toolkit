import os
import sys
import unittest
from unittest import mock

# Get the absolute path of the directory containing the modules
module_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../'))
# Append this directory to sys.path
sys.path.append(module_dir)

import include.utilities.s3 as s3

class TestS3Functions(unittest.TestCase):

    @mock.patch('include.utilities.s3.S3Hook')
    def test_upload_file_to_s3(self, mock_s3hook):
        mock_s3_instance = mock_s3hook.return_value
        mock_s3_instance.load_file.return_value = None

        s3.upload_file_to_s3('test-bucket', 'test_directory/file1.txt', 'test_prefix/file1.txt', mock_s3hook)

        mock_s3_instance.load_file.assert_called_once_with(
            filename='test_directory/file1.txt',
            bucket_name='test-bucket',
            replace=True,
            key='test_prefix/file1.txt'
        )
    @mock.patch('include.utilities.s3.S3Hook')
    @mock.patch('include.utilities.s3.upload_file_to_s3')
    @mock.patch('include.utilities.s3.list_files_in_directory')
    def test_upload_directory_to_s3(self, mock_list_files, mock_upload_file, mock_s3hook):
        mock_s3_instance = mock_s3hook.return_value

        mock_list_files.return_value = ['file1.txt', 'file2.txt']

        s3.upload_directory_to_s3('test-bucket', 'test_directory', 'test_prefix', 'test-aws-conn-id')

        self.assertEqual(mock_list_files.call_count, 1)
        self.assertEqual(mock_upload_file.call_count, 2)
        mock_upload_file.assert_any_call('test-bucket', 'test_directory/file1.txt', 'test_prefix/file1.txt', 'test-aws-conn-id',mock_s3_instance)
        mock_upload_file.assert_any_call('test-bucket', 'test_directory/file2.txt', 'test_prefix/file2.txt', 'test-aws-conn-id', mock_s3_instance)


if __name__ == '__main__':
    unittest.main()
