from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
import torch

VOL_MOUNT="/mnt/llm-shared-volume"
app = FastAPI(root_path="/api/v1/models")

class TextData(BaseModel):
    text: str

def sentiment_score_to_summary(score):
    # Define your mapping of score to sentiment summary
    sentiments = {
        1: 'Very Negative',
        2: 'Negative',
        3: 'Neutral',
        4: 'Positive',
        5: 'Very Positive'
    }
    return sentiments.get(score, "Unknown")

@app.post("/sentiment")
def analyze_sentiment(data: TextData):
    try:
        tokenizer = AutoTokenizer.from_pretrained(f"{VOL_MOUNT}/nlptown/bert-base-multilingual-uncased-sentiment")
        model = AutoModelForSequenceClassification.from_pretrained(f"{VOL_MOUNT}/nlptown/bert-base-multilingual-uncased-sentiment")
        tokens = tokenizer.encode(data.text, return_tensors="pt", truncation=True, padding=True)
        result = model(tokens)
        sentiment_score = int(torch.argmax(result.logits)) + 1
        outcome = sentiment_score_to_summary(sentiment_score)
        return {"result": outcome}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/language")
def language_detection(data: TextData):
    try:
        tokenizer = AutoTokenizer.from_pretrained(f"{VOL_MOUNT}/papluca/xlm-roberta-base-language-detection")
        model = AutoModelForSequenceClassification.from_pretrained(f"{VOL_MOUNT}/papluca/xlm-roberta-base-language-detection")

        pipe = pipeline("text-classification", model=model, tokenizer=tokenizer)
        result = pipe(data.text)

        return {"result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000 )

