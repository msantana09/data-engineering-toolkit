from fastapi import FastAPI, HTTPException
import torch
from openai import OpenAI
from fastapi import FastAPI, HTTPException, Request
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
from model import ColumnAnalysisRequest, TextData
import prompts
import logging
from utilities.openai import num_tokens_from_string

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

openai_client = OpenAI()

VOL_MOUNT="/mnt/llm-shared-volume/downloads"
sentiment_tokenizer = AutoTokenizer.from_pretrained(f"{VOL_MOUNT}/nlptown/bert-base-multilingual-uncased-sentiment")
sentiment_model = AutoModelForSequenceClassification.from_pretrained(f"{VOL_MOUNT}/nlptown/bert-base-multilingual-uncased-sentiment")

language_tokenizer = AutoTokenizer.from_pretrained(f"{VOL_MOUNT}/papluca/xlm-roberta-base-language-detection")
language_model = AutoModelForSequenceClassification.from_pretrained(f"{VOL_MOUNT}/papluca/xlm-roberta-base-language-detection")

app = FastAPI(root_path="/api/v1/models")
 

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
        tokens = sentiment_tokenizer.encode(data.text, return_tensors="pt", truncation=True, padding=True)
        result = sentiment_model(tokens)
        sentiment_score = int(torch.argmax(result.logits)) + 1
        outcome = sentiment_score_to_summary(sentiment_score)
        return {"result": outcome}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/language")
def language_detection(data: TextData):
    try:
        pipe = pipeline("text-classification", model=language_model, tokenizer=language_tokenizer)
        result = pipe(data.text)

        return {"result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    

@app.post("/column_analysis")
def column_analysis(data: ColumnAnalysisRequest):

    model = "gpt-3.5-turbo-16k"
    message = f"""
    context: {data.context}
    table: {data.tables[0].name}
    column_csv: 
    {data.tables[0].column_csv} 
    """

    try:
        messages = [
            {
                "content": prompts.column_analysis_csv,
                "role": "system"
            },
            {
                "content" :message,
                "role": "user"
            }
        ]
        response = openai_client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=1,
            max_tokens=4096
        )

        return {
            "content": response.choices[0].message.content,
            "usage": response.usage
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/column_analysis/tokens")
def column_analysis_tokens(data: ColumnAnalysisRequest): 

    message = f"""
    context: {data.context}
    table: {data.tables[0].name}
    column_csv: 
    {data.tables[0].column_csv} 
    """

    return {"num_tokens":num_tokens_from_string(message, "cl100k_base")}
    
@app.post("/dq_check")
async def dq_check(request: Request): 


    model = "gpt-3.5-turbo-16k"
    import json
 

    data =  await request.json() 

    try:
        messages = [
            {
                "content": prompts.dq_check,
                "role": "system"
            },
            {
                "content" : json.dumps(data),
                "role": "user"
            }
        ]
        response = openai_client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=1,
            max_tokens=4096
        )

        return {
            "content": response.choices[0].message.content,
            "usage": response.usage
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000 )

