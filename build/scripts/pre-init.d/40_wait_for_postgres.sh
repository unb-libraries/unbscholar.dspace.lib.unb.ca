#!/usr/bin/env sh
# Block until postgres accepts TCP connections. Also used by cron-entrypoint.sh.
set -e

if [ -z "$POSTGRES_DB_HOST" ] || [ -z "$POSTGRES_DB_PORT" ]; then
  echo 'POSTGRES_DB_HOST and POSTGRES_DB_PORT must be set.' >&2
  exit 1
fi

until nc -zw5 "$POSTGRES_DB_HOST" "$POSTGRES_DB_PORT"; do
  printf '\t Waiting for postgres on %s:%s...\n' "$POSTGRES_DB_HOST" "$POSTGRES_DB_PORT"
  sleep 5
done
