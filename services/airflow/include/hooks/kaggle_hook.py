import os
import logging
from airflow.hooks.base import BaseHook

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class KaggleHook(BaseHook):
    """
    Interact with the Kaggle API.

    :conn_id: Connection ID to retrieve Kaggle credentials.
    """
    default_conn_name = "kaggle_default"
    conn_type = "generic"
    hook_name = "Kaggle"

    def __init__(
        self, conn_id: str = default_conn_name, *args, **kwargs
    ) -> None:
        super().__init__(*args, **kwargs)
        self.conn_id = conn_id


    def download_dataset(self, dataset, path):
        connection = self.get_connection(self.conn_id)

        os.environ['KAGGLE_USERNAME'] = connection.login
        os.environ['KAGGLE_KEY']= connection.password
        '''
        Import Kaggle API here to avoid import errors since the package 
        immediately checks for the existence of the KAGGLE_USERNAME and 
        KAGGLE_KEY environment variables or a local credentials file
        '''
        from kaggle import KaggleApi
        self.client = KaggleApi()
        self.client.authenticate()

        """
        Download a dataset from Kaggle.

        :param dataset: The dataset to download (e.g., `username/dataset`).
        :param path: The local path where to save the dataset.
        """
        self.client.dataset_download_files(dataset, path=path, unzip=True)

        # get names of downloaded files
        file_names = os.listdir(path)

        logger.info(f"Downloaded dataset to {path}")   

        return file_names

