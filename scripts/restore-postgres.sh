#!/bin/sh
set -eu

: "${POSTGRES_HOST:?POSTGRES_HOST is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${HBT_RESTORE_FILE:?HBT_RESTORE_FILE is required}"
: "${HBT_RESTORE_CONFIRM:?Set HBT_RESTORE_CONFIRM to the exact database name}"

if [ "$HBT_RESTORE_CONFIRM" != "$POSTGRES_DB" ]; then
  printf '%s\n' "Restore confirmation does not match target database." >&2
  exit 2
fi

test -f "$HBT_RESTORE_FILE"
test -f "$HBT_RESTORE_FILE.sha256"
sha256sum --check "$HBT_RESTORE_FILE.sha256"
pg_restore --list "$HBT_RESTORE_FILE" >/dev/null

pg_restore \
  --host="$POSTGRES_HOST" \
  --port="${POSTGRES_PORT:-5432}" \
  --username="$POSTGRES_USER" \
  --dbname="$POSTGRES_DB" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  "$HBT_RESTORE_FILE"

python manage.py migrate --noinput
python manage.py check
