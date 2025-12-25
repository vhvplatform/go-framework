#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    echo "Example: $0 auth-service"
    exit 1
fi

SERVICE=$1

echo "🔄 Restarting ${SERVICE}..."
cd "$(dirname "$0")/../../docker"

docker-compose restart "${SERVICE}"

echo "✅ ${SERVICE} restarted!"
echo ""
echo "View logs with: docker-compose logs -f ${SERVICE}"
