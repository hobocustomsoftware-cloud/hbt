#!/bin/sh
set -eu

: "${POSTGRES_HOST:?POSTGRES_HOST is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${HBT_BACKUP_DIR:?HBT_BACKUP_DIR is required}"

mkdir -p "$HBT_BACKUP_DIR"
umask 077
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
target="$HBT_BACKUP_DIR/hbt-$timestamp.dump"

pg_dump \
  --host="$POSTGRES_HOST" \
  --port="${POSTGRES_PORT:-5432}" \
  --username="$POSTGRES_USER" \
  --dbname="$POSTGRES_DB" \
  --format=custom \
  --compress=9 \
  --file="$target"

sha256sum "$target" > "$target.sha256"
pg_restore --list "$target" >/dev/null
printf '%s\n' "$target"
