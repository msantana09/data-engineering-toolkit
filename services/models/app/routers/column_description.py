from fastapi import APIRouter, Depends, HTTPException
from models import DescribeColumnsRequest
from dependencies import get_openai_client
from utilities.openai import num_tokens_from_string
import prompts

router = APIRouter()

MODEL = "gpt-3.5-turbo-16k"
 

@router.post("/describe_columns")
async def describe_columns(data: DescribeColumnsRequest, openai_client = Depends(get_openai_client)):

    message = f"""
    context: {data.context}
    table: {data.tables[0].name}
    column_csv: 
    {data.tables[0].column_csv} 
    """

    try:
        messages = [
            {
                "content": prompts.describe_columns_csv,
                "role": "system"
            },
            {
                "content" :message,
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

@router.post("/describe_columns/tokens")
async def describe_columns_tokens(data: DescribeColumnsRequest):

    message = f"""
    context: {data.context}
    table: {data.tables[0].name}
    column_csv: 
    {data.tables[0].column_csv} 
    """

    return {"num_tokens":num_tokens_from_string(message, "cl100k_base")}
    