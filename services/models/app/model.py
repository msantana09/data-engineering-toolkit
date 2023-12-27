from typing import List
from pydantic import BaseModel

class TextData(BaseModel):
    text: str

class Table(BaseModel):
    column_csv: str
    name: str

class DescribeColumnsRequest(BaseModel):
    tables: List[Table]
    context: str