from typing import List
from pydantic import BaseModel

class TextData(BaseModel):
    text: str
    
class Column(BaseModel):
    datatype: str
    name: str

class Table(BaseModel):
    columns: List[Column]
    name: str

class ColumnAnalysisRequest(BaseModel):
    tables: List[Table]
    context: str