#!/bin/sh
set -eu

if [ "${HBT_RUN_BOOTSTRAP:-false}" = "true" ]; then
  python manage.py migrate --noinput
  python manage.py collectstatic --noinput
fi
exec "$@"
