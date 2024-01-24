from openai import OpenAI
from transformers import AutoTokenizer, AutoModelForSequenceClassification

VOL_MOUNT = "/mnt/llm-shared-volume/downloads"

def get_classification_model(model:str):
    tokenizer = AutoTokenizer.from_pretrained(f"{VOL_MOUNT}/{model}")
    model = AutoModelForSequenceClassification.from_pretrained(f"{VOL_MOUNT}/{model}")
    return tokenizer, model

def get_openai_client() -> OpenAI: 
    return OpenAI()