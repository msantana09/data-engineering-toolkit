from airflow.models import BaseOperator
from include.hooks.kaggle_hook import KaggleHook
import tempfile
from include.utilities.s3 import upload_directory_to_s3
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

class KaggleDatasetToS3(BaseOperator):
    def __init__(self, conn_id, dataset, bucket, path, aws_conn_id, *args, **kwargs):
        self.conn_id = conn_id
        self.dataset = dataset
        self.bucket = bucket
        self.path = path
        self.aws_conn_id = aws_conn_id
        super().__init__(*args, **kwargs)


    def execute(self, context):
        self.kaggle_hook = KaggleHook(conn_id=self.conn_id)

        self.s3_hook = S3Hook(aws_conn_id=self.aws_conn_id)

        # Create temporary directory to store downloaded dataset
        temp_dir = tempfile.TemporaryDirectory()
        
        # Download dataset
        file_names=self.kaggle_hook.download_dataset(dataset=self.dataset, path=temp_dir.name)

        # Upload dataset to S3        
        upload_directory_to_s3(self.bucket, temp_dir.name, self.path, s3_hook=self.s3_hook)

        # Delete temporary directory
        temp_dir.cleanup()

        # return file names
        return file_names