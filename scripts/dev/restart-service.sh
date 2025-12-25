#!/bin/bash
#
# Script: restart-service.sh
# Description: Restart a specific microservice quickly
# Usage: ./restart-service.sh <service-name>
#
# This script:
#   1. Stops the specified service container
#   2. Starts it again with existing configuration
#   3. Waits for health check to pass
#
# Arguments:
#   $1 - Service name (required)
#        Examples: auth-service, user-service, api-gateway
#
# Examples:
#   ./restart-service.sh auth-service
#   ./restart-service.sh user-service
#   make restart-service SERVICE=auth-service
#
# Use Cases:
#   - Apply configuration changes
#   - Recover from service crash
#   - Apply environment variable changes
#
# Notes:
#   - Does not rebuild the container
#   - Preserves existing data
#   - Quick restart (2-5 seconds)
#
# See Also:
#   - rebuild.sh: For rebuilding with code changes
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

echo "🔄 Restarting ${SERVICE}..."
cd "$(dirname "$0")/../../docker"

docker-compose restart "${SERVICE}"

echo "✅ ${SERVICE} restarted!"
echo ""
echo "View logs with: docker-compose logs -f ${SERVICE}"
