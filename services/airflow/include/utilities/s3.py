import os
import logging
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def list_files_in_directory(local_directory:str):
    """List all files in a given directory."""
    return [f for f in os.listdir(local_directory) if os.path.isfile(os.path.join(local_directory, f))]

def upload_file_to_s3(bucket_name:str, local_path:str, s3_key:str, aws_conn_id:str=None, s3_hook: S3Hook = None):
    """Upload a single file to an S3 bucket."""
    if s3_hook is None:
        s3_hook = S3Hook(aws_conn_id=aws_conn_id)
    s3_hook.load_file(filename=local_path, bucket_name=bucket_name, replace=True, key=s3_key)
    logger.info(f"Uploaded {os.path.basename(local_path)} to s3://{bucket_name}/{s3_key}")

def upload_directory_to_s3(bucket_name:str, local_directory:str, s3_prefix:str, aws_conn_id:str=None, s3_hook: S3Hook = None):
    """
    Uploads all files from a local directory to an S3 bucket.
    :param bucket_name: Name of the S3 bucket.
    :param local_directory: Path to the local directory to upload.
    :param s3_prefix: S3 prefix where files will be stored.
    :param aws_conn_id: Airflow connection ID for AWS.
    :param s3_hook: S3Hook instance.
    """
    if s3_hook is None:
        s3_hook = S3Hook(aws_conn_id=aws_conn_id)
        
    for filename in list_files_in_directory(local_directory):
        local_path = os.path.join(local_directory, filename)
        s3_key = f'{s3_prefix}/{filename}'
        upload_file_to_s3(bucket_name, local_path, s3_key, aws_conn_id, s3_hook)
