#!/bin/sh
# wait-for-it.sh — wait until MySQL is reachable, then start the app

HOST="$DB_HOST"
PORT="$DB_PORT"

echo "Waiting for $HOST:$PORT to be ready..."

while ! nc -z "$HOST" "$PORT" 2>/dev/null; do
  echo "  ...still waiting for $HOST:$PORT"
  sleep 2
done

echo "$HOST:$PORT is ready — starting application"
exec "$@"
