FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY wsgi.py run.py ./
COPY app ./app
COPY migrations ./migrations
COPY docker/entrypoint.sh ./docker/entrypoint.sh
RUN chmod +x docker/entrypoint.sh

ENV FLASK_APP=run.py \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production

EXPOSE 5052

ENTRYPOINT ["sh", "docker/entrypoint.sh"]
