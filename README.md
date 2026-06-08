# Pediatric Business Portfolio

Flask clinic app — VPS deployment uses **host PostgreSQL** + **Docker (host network)** + **Nginx**.

## Project structure

```
├── app/                  # Flask application
├── docker/               # entrypoint.sh, nginx template
├── migrations/           # init.sql schema
├── scripts/              # deploy helpers
├── deployment.sh         # App deploy (run on VPS)
├── mypostgresql.sh       # One-time DB + Nginx setup (sudo)
├── docker-compose.yml
├── Dockerfile
├── run.py                # Local dev
└── wsgi.py               # Production
```

## VPS setup (first time)

```bash
cp .env.example .env
nano .env                  # set passwords, DOMAIN

sudo bash mypostgresql.sh
sudo INSTALL_SSL=true bash mypostgresql.sh   # optional HTTPS

bash deployment.sh
```

## VPS redeploy

```bash
bash deployment.sh
```

## If database login fails

```bash
sudo bash scripts/reset_pediatric_db_user.sh
bash deployment.sh
```

## Local development

```bash
pip install -r requirements.txt
python run.py
```

## Useful commands

| Command | Description |
|---------|-------------|
| `bash deployment.sh` | Build & start Docker container |
| `sudo bash mypostgresql.sh` | Install Postgres + Nginx |
| `docker compose logs -f web` | View app logs |
| `curl http://127.0.0.1:5052/healthz` | Health check |
