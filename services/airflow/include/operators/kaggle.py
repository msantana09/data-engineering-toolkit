from airflow.models import BaseOperator
from include.hooks.kaggle_hook import KaggleHook
import tempfile
from include.utilities.s3 import upload_directory_to_s3

class KaggleDatasetToS3(BaseOperator):
    def __init__(self, conn_id, dataset, bucket, path, aws_conn_id, kaggle_hook=None, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.conn_id = conn_id
        self.dataset = dataset
        self.bucket = bucket
        self.path = path
        self.aws_conn_id = aws_conn_id
        self.kaggle_hook = kaggle_hook
        if not self.kaggle_hook:
            self.kaggle_hook = KaggleHook(conn_id=self.conn_id)

    def execute(self, context):

        # Create temporary directory to store downloaded dataset
        temp_dir = tempfile.TemporaryDirectory()
        
        # Download dataset
        file_names=self.kaggle_hook.download_dataset(dataset=self.dataset, path=temp_dir.name)

        # Upload dataset to S3        
        upload_directory_to_s3(self.bucket, temp_dir.name, self.path, aws_conn_id=self.aws_conn_id)

        # Delete temporary directory
        temp_dir.cleanup()

        # return file names
        return file_names