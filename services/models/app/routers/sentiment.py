import os
from fastapi import APIRouter, Depends, HTTPException
from models import TextData, SentimentResponse
import torch
from dependencies import get_classification_model


router = APIRouter()

MODEL = os.getenv("SENTIMENT_MODEL")
tokenizer, model = None, None

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
async def analyze_sentiment(data: TextData):
    """Analyze sentiment of a text string

    Args:
        data (TextData): TextData object containing text to analyze

    Raises:
        HTTPException: If there is an error analyzing the text

    Returns:
        _type_: SentimentResponse
    """
    global tokenizer, model
    if not tokenizer or not model:
        tokenizer, model = get_classification_model(MODEL)

    try:
        tokens = tokenizer.encode(data.text, return_tensors="pt", truncation=True, padding=True)
        result = model(tokens)

        sentiment_score = int(torch.argmax(result.logits)) + 1
        sentiment_summary = sentiment_score_to_summary(sentiment_score)

        return SentimentResponse(result=sentiment_summary)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
