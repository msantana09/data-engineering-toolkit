
from transformers import AutoTokenizer,AutoModelForSequenceClassification

models = [
    "nlptown/bert-base-multilingual-uncased-sentiment",
    "papluca/xlm-roberta-base-language-detection"
]


for model_name in models: 
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_name)
    model.save_pretrained(f"/mnt/llm-shared-volume/{model_name}", from_pt=True) 
    tokenizer.save_pretrained(f"/mnt/llm-shared-volume/{model_name}", from_pt=True) 
