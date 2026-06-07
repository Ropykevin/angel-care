#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COMPOSE_FILES=(-f docker-compose.yml -f docker-compose.prod.yml)
export COMPOSE_FILE="docker-compose.yml:docker-compose.prod.yml"
APP_PORT="${APP_PORT:-5052}"

log() {
    echo "[vps] $*"
}

ensure_env() {
    if [ ! -f .env ]; then
        log "Creating .env from .env.example — edit it before going live."
        cp .env.example .env
    fi

    # shellcheck disable=SC1091
    set -a
    source .env
    set +a

    if [ "${SECRET_KEY:-}" = "your-secret-key-here" ] || [ -z "${SECRET_KEY:-}" ]; then
        log "WARNING: Set a strong SECRET_KEY in .env before production use."
    fi

    if [ "${POSTGRES_PASSWORD:-}" = "pediatric_clinic_password" ]; then
        log "WARNING: Change POSTGRES_PASSWORD in .env before production use."
    fi
}

check_dependencies() {
    command -v docker > /dev/null 2>&1 || {
        echo "Install Docker first: https://docs.docker.com/engine/install/"
        exit 1
    }
    command -v docker compose > /dev/null 2>&1 || {
        echo "Docker Compose plugin is required."
        exit 1
    }
}

deploy() {
    ensure_env
    check_dependencies
    chmod +x postgresql.sh deployment.sh

    log "Starting PostgreSQL (not exposed publicly)..."
    docker compose "${COMPOSE_FILES[@]}" up -d db
    ./postgresql.sh start

    log "Building and starting web service..."
    docker compose "${COMPOSE_FILES[@]}" up -d --build web

    log "Waiting for app on 127.0.0.1:${APP_PORT}..."
    for _ in $(seq 1 30); do
        if curl -fsS "http://127.0.0.1:${APP_PORT}/healthz" > /dev/null 2>&1; then
            log "VPS deployment complete."
            log "App is running locally at http://127.0.0.1:${APP_PORT}"
            log "Next: configure Nginx using deploy/nginx.conf and open ports 80/443."
            return 0
        fi
        sleep 2
    done

    log "Health check timed out. Run: docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f web"
    exit 1
}

stop() {
    docker compose "${COMPOSE_FILES[@]}" down
    log "Services stopped."
}

restart() {
    stop
    deploy
}

logs() {
    docker compose "${COMPOSE_FILES[@]}" logs -f
}

status() {
    docker compose "${COMPOSE_FILES[@]}" ps
}

usage() {
    echo "Usage: $0 {deploy|stop|restart|logs|status}"
    exit 1
}

case "${1:-deploy}" in
    deploy) deploy ;;
    stop) stop ;;
    restart) restart ;;
    logs) logs ;;
    status) status ;;
    *) usage ;;
esac
