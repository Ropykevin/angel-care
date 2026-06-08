import os

from dotenv import load_dotenv

load_dotenv()


def get_database_uri():
    url = os.environ.get(
        'DATABASE_URL',
        'postgresql://pediatric:password@localhost:5432/pediatric',
    )
    if url.startswith('postgres://'):
        url = url.replace('postgres://', 'postgresql://', 1)
    return url


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'supersecretkey')
    SQLALCHEMY_DATABASE_URI = get_database_uri()
    SQLALCHEMY_TRACK_MODIFICATIONS = False
