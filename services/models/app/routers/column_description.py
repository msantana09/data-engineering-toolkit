import os
from fastapi import APIRouter, Depends, HTTPException
from models import DescribeColumnsRequest, DescribeColumnsResponse, DescribeColumnsTokensResponse
from dependencies import get_openai_client, num_tokens_from_string
import prompts

router = APIRouter()

MODEL = os.getenv("OPENAI_MODEL")
TOKENIZER = os.getenv("OPENAI_TOKENIZER")

@router.post("/describe_columns")
async def describe_columns(data: DescribeColumnsRequest, openai_client = Depends(get_openai_client)):
    """ Describe columns of a table

    Args:
        data (DescribeColumnsRequest): 

    Raises:
        HTTPException: If there is an error analyzing the text

    Returns:
        _type_: DescribeColumnsResponse
    """

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
        return DescribeColumnsResponse(content=response.choices[0].message.content, usage=response.usage)

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

    return DescribeColumnsTokensResponse(num_tokens=num_tokens_from_string(message, TOKENIZER))
    