from fastapi import FastAPI, HTTPException
import torch
from openai import OpenAI
from fastapi import FastAPI, HTTPException
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
from model import ColumnAnalysisRequest, TextData
import prompts
import logging
import json

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

openai_client = OpenAI()

VOL_MOUNT="/mnt/llm-shared-volume"
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
    

@app.post("/column_analysis")
def column_analysis(data: ColumnAnalysisRequest):

    try:
        messages = [
            {
                "content": prompts.column_analysis,
                "role": "system"
            },
            {
                "content" :data.model_dump_json(),
                "role": "user"
            }
        ]
        response = openai_client.chat.completions.create(
            model="gpt-4-1106-preview",
            response_format={ "type": "json_object" },
            messages=messages,
            temperature=1,
            max_tokens=4096
        )

        response

        return {
            "result": json.loads(response.choices[0].message.content),
            "usage": response.usage
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000 )

