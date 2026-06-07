#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_PORT="${APP_PORT:-5052}"
COMPOSE_FILES=(-f docker-compose.yml)
PROD_MODE=0

if [ "${1:-}" = "prod" ]; then
    PROD_MODE=1
    COMPOSE_FILES=(-f docker-compose.yml -f docker-compose.prod.yml)
    export COMPOSE_FILE="docker-compose.yml:docker-compose.prod.yml"
    shift
fi

log() {
    echo "[deploy] $*"
}

ensure_env() {
    if [ ! -f .env ]; then
        log "Creating .env from .env.example"
        cp .env.example .env
    fi

    # shellcheck disable=SC1091
    set -a
    source .env
    set +a
}

check_dependencies() {
    command -v docker > /dev/null 2>&1 || {
        echo "Docker is required but not installed."
        exit 1
    }
    command -v docker compose > /dev/null 2>&1 || {
        echo "Docker Compose is required but not installed."
        exit 1
    }
}

deploy() {
    ensure_env
    check_dependencies

    chmod +x postgresql.sh

    log "Starting PostgreSQL..."
    docker compose "${COMPOSE_FILES[@]}" up -d db
    ./postgresql.sh start

    log "Building application image..."
    docker compose "${COMPOSE_FILES[@]}" build web

    log "Starting application..."
    docker compose "${COMPOSE_FILES[@]}" up -d web

    local health_url="http://localhost:${APP_PORT}/healthz"
    if [ "$PROD_MODE" -eq 1 ]; then
        health_url="http://127.0.0.1:${APP_PORT}/healthz"
    fi

    log "Waiting for web service..."
    for _ in $(seq 1 30); do
        if curl -fsS "$health_url" > /dev/null 2>&1; then
            log "Deployment complete."
            if [ "$PROD_MODE" -eq 1 ]; then
                log "Application (local): http://127.0.0.1:${APP_PORT}"
                log "Configure Nginx with deploy/nginx.conf for public access."
            else
                log "Application: http://localhost:${APP_PORT}"
            fi
            return 0
        fi
        sleep 2
    done

    log "Application container started, but health check timed out."
    log "Check logs with: docker compose ${COMPOSE_FILES[*]} logs -f web"
    exit 1
}

stop() {
    log "Stopping all services..."
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

usage() {
    echo "Usage: $0 [prod] {deploy|stop|restart|logs}"
    echo ""
    echo "  prod    Use production VPS settings (DB not public, app on 127.0.0.1)"
    exit 1
}

case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs
        ;;
    *)
        usage
        ;;
esac
