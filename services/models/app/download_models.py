
from transformers import AutoTokenizer,AutoModelForSequenceClassification

VOL_MOUNT="/mnt/llm-shared-volume"

models = [
    "nlptown/bert-base-multilingual-uncased-sentiment",
    "papluca/xlm-roberta-base-language-detection"
]


for model_name in models: 
    # check if model is already downloaded
    try:
        AutoTokenizer.from_pretrained(f"{VOL_MOUNT}/downloads/{model_name}")
        print(f"Model {model_name} already exists")
        continue
    except:
        pass
    
    print(f"Downloading model {model_name}")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_name)
    model.save_pretrained(f"/mnt/llm-shared-volume/downloads/{model_name}", from_pt=True) 
    tokenizer.save_pretrained(f"/mnt/llm-shared-volume/downloads/{model_name}", from_pt=True) 
