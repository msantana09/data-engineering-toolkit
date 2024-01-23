from openai import OpenAI
from transformers import AutoTokenizer, AutoModelForSequenceClassification

VOL_MOUNT="/mnt/llm-shared-volume/downloads"

def get_sentiment_model():
    print('get_sentiment_model')
    tokenizer = AutoTokenizer.from_pretrained(f"{VOL_MOUNT}/nlptown/bert-base-multilingual-uncased-sentiment")
    model = AutoModelForSequenceClassification.from_pretrained(f"{VOL_MOUNT}/nlptown/bert-base-multilingual-uncased-sentiment")
    return tokenizer, model

def get_openai_client() -> OpenAI: 
    return OpenAI()