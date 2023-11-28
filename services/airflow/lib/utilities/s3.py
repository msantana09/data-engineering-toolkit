import os
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

def upload_files_to_s3(bucket_name, local_directory, s3_prefix, aws_conn_id=None):
    """
    Uploads all files from a local directory to an S3 bucket.
    :param bucket_name: Name of the S3 bucket.
    :param local_directory: Path to the local directory to upload.
    :param s3_prefix: S3 prefix where files will be stored.
    """
    s3_hook = S3Hook(aws_conn_id=aws_conn_id)

    for filename in os.listdir(local_directory):
        local_path = os.path.join(local_directory, filename)
        if os.path.isfile(local_path):
            s3_key = f'{s3_prefix}/{filename}'
            s3_hook.load_file(filename=local_path, bucket_name=bucket_name, replace=True, key=s3_key)
            print(f"Uploaded {filename} to s3://{bucket_name}/{s3_key}")
