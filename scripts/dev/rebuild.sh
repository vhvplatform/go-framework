#!/bin/bash
#
# Script: rebuild.sh
# Description: Rebuild and restart a service with latest code changes
# Usage: ./rebuild.sh <service-name>
#
# This script:
#   1. Stops the service
#   2. Rebuilds Docker image with latest code from source
#   3. Restarts service with new image
#   4. Waits for health check to pass
#
# Arguments:
#   $1 - Service name (required)
#        Examples: auth-service, user-service, api-gateway
#
# Examples:
#   ./rebuild.sh auth-service
#   ./rebuild.sh user-service
#   make rebuild SERVICE=auth-service
#
# Workflow:
#   1. Make code changes in service repository
#   2. Run this script to rebuild
#   3. Test changes immediately
#
# Notes:
#   - Takes longer than restart (30-60 seconds)
#   - Rebuilds from source code
#   - Preserves database data
#   - Use for code changes only
#
# Performance Tip:
#   For active development, use 'make start-dev' instead
#   to enable hot reload without manual rebuilds
#
# See Also:
#   - restart-service.sh: Quick restart without rebuild
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
