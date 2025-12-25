#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    echo "Example: $0 auth-service"
    exit 1
fi

SERVICE=$1

echo "🐚 Accessing ${SERVICE} shell..."
cd "$(dirname "$0")/../../docker"

docker-compose exec "${SERVICE}" sh || docker-compose exec "${SERVICE}" bash
