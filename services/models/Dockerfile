FROM python:3.8-slim

WORKDIR /app

# Copy the current directory contents into the container at /app
COPY app.py .

COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir


# Make port 8000 available to the world outside this container
EXPOSE 8000

# Define environment variable
ENV MODEL_NAME=nlptown/bert-base-multilingual-uncased-sentiment

# Run app.py when the container launches
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]

# docker run -p 8000:8000 --cpus=0.5 -m 2g -t sentiment_api 