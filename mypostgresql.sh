#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INIT_SQL="${SCRIPT_DIR}/docker/init.sql"
DB_NAME="${POSTGRES_DB:-pediatric_clinic}"
DB_USER="${POSTGRES_USER:-pediatric_clinic_user}"
DB_PASSWORD="${POSTGRES_PASSWORD:-1234}"
DB_HOST="${POSTGRES_HOST:-localhost}"
DB_PORT="${POSTGRES_PORT:-5432}"

export PGPASSWORD="$DB_PASSWORD"

usage() {
    echo "Usage: $0 {start|init|stop|status}"
    echo ""
    echo "  start   Start PostgreSQL container and initialize schema"
    echo "  init    Initialize database and apply docker/init.sql"
    echo "  stop    Stop PostgreSQL container"
    echo "  status  Check PostgreSQL connection status"
    exit 1
}

db_container_running() {
    docker compose ps db --status running -q 2>/dev/null | grep -q .
}

run_psql() {
    if db_container_running; then
        docker compose exec -T db psql -U "$DB_USER" "$@"
    else
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$@"
    fi
}

wait_for_postgres() {
    echo "Waiting for PostgreSQL..."
    for _ in $(seq 1 30); do
        if db_container_running; then
            if docker compose exec -T db pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
                echo "PostgreSQL is ready."
                return 0
            fi
        elif command -v pg_isready > /dev/null 2>&1; then
            if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; then
                echo "PostgreSQL is ready."
                return 0
            fi
        fi
        sleep 2
    done
    echo "PostgreSQL did not become ready in time."
    exit 1
}

create_database() {
    local exists
    exists=$(run_psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" postgres)

    if [ "$exists" != "1" ]; then
        echo "Creating database '${DB_NAME}'..."
        run_psql -c "CREATE DATABASE ${DB_NAME};" postgres
    else
        echo "Database '${DB_NAME}' already exists."
    fi
}

apply_schema() {
    echo "Applying schema from docker/init.sql..."
    if db_container_running; then
        docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" < "$INIT_SQL"
    else
        run_psql -d "$DB_NAME" -f "$INIT_SQL"
    fi
    echo "Schema applied successfully."
}

start_db() {
    echo "Starting PostgreSQL container..."
    docker compose up -d db
    wait_for_postgres
    create_database
    apply_schema
}

init_db() {
    wait_for_postgres
    create_database
    apply_schema
}

stop_db() {
    echo "Stopping PostgreSQL container..."
    docker compose stop db
}

check_status() {
    wait_for_postgres
    echo "Connected to database '${DB_NAME}'."
    run_psql -d "$DB_NAME" -c "\dt"
}

case "${1:-}" in
    start) start_db ;;
    init) init_db ;;
    stop) stop_db ;;
    status) check_status ;;
    *) usage ;;
esac
