#!/bin/sh
set -e

echo "=== Runtime check: required files ==="
[ -f compose/docker-compose.yml ] || {
	echo "Missing compose/docker-compose.yml"
	exit 1
}

echo "=== Runtime check: required paths ==="
mkdir -p datasets output config

echo "=== Runtime check: docker available ==="
command -v docker >/dev/null 2>&1 || {
	echo "Docker is not installed or not in PATH"
	exit 1
}

echo "=== Runtime check: docker compose config ==="
docker compose -f compose/docker-compose.yml config >/dev/null

echo "=== Runtime checks passed ==="
