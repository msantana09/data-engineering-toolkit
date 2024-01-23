
import logging
from fastapi import FastAPI 
from routers.sentiment import router as sentiment_router
from routers.column_description import router as column_description_router
from routers.dq import router as dq_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

VOL_MOUNT="/mnt/llm-shared-volume/downloads"
API_PREFIX="/api/v1/models"
     

if __name__ == "__main__":
    import uvicorn
    app =  FastAPI()
    app.include_router(sentiment_router, prefix=API_PREFIX)
    app.include_router(column_description_router, prefix=API_PREFIX)
    app.include_router(dq_router, prefix=API_PREFIX)


    uvicorn.run(app, host="0.0.0.0", port=8000 )

