# Pediatric Business Portfolio

Flask clinic management app with PostgreSQL, SQLAlchemy, and Docker deployment.

## Project structure

```
├── app/                  # Application package
│   ├── routes.py         # URL routes
│   ├── models.py         # SQLAlchemy models
│   ├── config.py         # Configuration
│   ├── templates/        # HTML templates
│   └── static/           # CSS and assets
├── docker/               # Docker and VPS configs
│   ├── init.sql          # Database schema
│   ├── nginx.conf        # Nginx reverse proxy
│   └── docker-compose.prod.yml
├── migrations/           # SQL migrations
├── scripts/              # Helper scripts
├── tests/                # Test suite
├── deployment.sh         # Deploy with Docker
├── mypostgresql.sh       # PostgreSQL setup
├── docker-compose.yml
├── Dockerfile
├── run.py                # Local dev entry point
└── wsgi.py               # Production entry point
```

## Local development

```bash
cp .env.example .env
pip install -r requirements.txt
python run.py
```

## Docker deployment

```bash
cp .env.example .env
chmod +x deployment.sh mypostgresql.sh
./deployment.sh deploy
```

## VPS deployment

```bash
./deployment.sh prod deploy
```

Then configure Nginx using `docker/nginx.conf`.

## Commands

| Command | Description |
|---------|-------------|
| `python run.py` | Run locally |
| `./deployment.sh deploy` | Docker deploy |
| `./deployment.sh prod deploy` | VPS production deploy |
| `./mypostgresql.sh status` | Check database |
| `./deployment.sh logs` | View container logs |
