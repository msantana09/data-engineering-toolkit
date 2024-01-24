from typing import List
from pydantic import BaseModel
from openai.types.completion_usage import CompletionUsage

class TextData(BaseModel):
    text: str

class Table(BaseModel):
    column_csv: str
    name: str

class DescribeColumnsRequest(BaseModel):
    tables: List[Table]
    context: str 


class DescribeColumnsResponse(BaseModel):
    content: str
    usage: CompletionUsage 

class DescribeColumnsTokensResponse(BaseModel):
    num_tokens: int 



class SentimentResponse(BaseModel):
    result: str
