import os
from fastapi import APIRouter, Depends, HTTPException, Request
from dependencies import get_openai_client
import prompts
import json

router = APIRouter()
MODEL = os.getenv("OPENAI_MODEL")


@router.post("/dq_check")
async def  dq_check(request: Request, openai_client = Depends(get_openai_client)): 
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
            model=MODEL,
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