#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    echo "Example: $0 auth-service"
    exit 1
fi

SERVICE=$1

echo "🔨 Rebuilding ${SERVICE}..."
cd "$(dirname "$0")/../../docker"

# Stop the service
echo "⏸️  Stopping ${SERVICE}..."
docker-compose stop "${SERVICE}"

# Rebuild the service
echo "🔨 Building ${SERVICE}..."
docker-compose build "${SERVICE}"

# Start the service
echo "▶️  Starting ${SERVICE}..."
docker-compose up -d "${SERVICE}"

echo "✅ ${SERVICE} rebuilt and restarted!"
echo ""
echo "View logs with: docker-compose logs -f ${SERVICE}"
