FROM python:3.8-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

COPY /app . 

ENV PYTHONPATH="${PYTHONPATH}:/app"


EXPOSE 8000

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# docker run -p 8000:8000 --cpus=0.5 -m 2g -t sentiment_api 