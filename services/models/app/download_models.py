import os
from transformers import AutoTokenizer,AutoModelForSequenceClassification

VOLUME_MOUNT= os.getenv("VOLUME_MOUNT")

models = [
    os.getenv("SENTIMENT_MODEL")
]


for model_name in models: 
    # check if model is already downloaded
    try:
        AutoTokenizer.from_pretrained(f"{VOLUME_MOUNT}/downloads/{model_name}")
        print(f"Model {model_name} already exists")
        continue
    except:
        pass
    
    print(f"Downloading model {model_name}")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_name)
    model.save_pretrained(f"{VOLUME_MOUNT}/downloads/{model_name}", from_pt=True) 
    tokenizer.save_pretrained(f"{VOLUME_MOUNT}/downloads/{model_name}", from_pt=True) 
