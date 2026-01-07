#!/bin/bash

DOCKER_DIR="$(dirname "$0")/../../docker"

if [ -z "$1" ]; then
    echo "📋 Tailing logs from all services..."
    cd "${DOCKER_DIR}"
    docker-compose logs -f
else
    SERVICE=$1
    echo "📋 Tailing logs from ${SERVICE}..."
    cd "${DOCKER_DIR}"
    docker-compose logs -f "${SERVICE}"
fi
