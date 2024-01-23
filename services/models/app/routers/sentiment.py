from fastapi import APIRouter, Depends, HTTPException
from models import TextData, SentimentResponse
import torch
from dependencies import get_sentiment_model

router = APIRouter()

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


@router.post("/sentiment")
async def analyze_sentiment(data: TextData, model_deps = Depends(get_sentiment_model)):
    tokenizer, model = model_deps

    try:
        tokens = tokenizer.encode(data.text, return_tensors="pt", truncation=True, padding=True)
        result = model(tokens)

        sentiment_score = int(torch.argmax(result.logits)) + 1
        sentiment_summary = sentiment_score_to_summary(sentiment_score)

        return SentimentResponse(result=sentiment_summary)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
