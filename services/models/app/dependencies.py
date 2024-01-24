import os
from openai import OpenAI
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import tiktoken

VOLUME_MOUNT= os.getenv("VOLUME_MOUNT")

def get_classification_model(model:str):
    tokenizer = AutoTokenizer.from_pretrained(f"{VOLUME_MOUNT}/downloads/{model}")
    model = AutoModelForSequenceClassification.from_pretrained(f"{VOLUME_MOUNT}/downloads/{model}")
    return tokenizer, model

def get_openai_client() -> OpenAI: 
    return OpenAI()

def num_tokens_from_string(string: str, encoding_name: str) -> int:
    """Returns the number of tokens in a text string."""
    encoding = tiktoken.get_encoding(encoding_name)
    num_tokens = len(encoding.encode(string))
    return num_tokens