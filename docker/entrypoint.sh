#!/bin/sh
set -e

cd /app

python3 - <<'PY'
from app import create_app
from app.extensions import db

app = create_app()
with app.app_context():
    db.create_all()
print("Database tables ready.")
PY

PORT="${APP_PORT:-5052}"
exec gunicorn --bind "0.0.0.0:${PORT}" --workers 2 --timeout 60 wsgi:app
