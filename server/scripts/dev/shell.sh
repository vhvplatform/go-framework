#!/bin/bash
#
# Script: shell.sh
# Description: Access a shell inside a running service container
# Usage: ./shell.sh <service-name>
#
# This script provides shell access to a running container for:
#   - Inspecting logs and files
#   - Checking environment variables
#   - Running manual commands
#   - Testing connectivity
#   - Debugging issues
#
# Arguments:
#   $1 - Service name (required)
#        Examples: auth-service, user-service, mongodb, redis
#
# Examples:
#   ./shell.sh auth-service
#   make shell SERVICE=auth-service
#
# Inside Container:
#   # Check environment
#   env | grep JWT
#
#   # Check connectivity
#   ping mongodb
#   curl http://user-service:8080/health
#
#   # Check files
#   ls -la /app
#   cat /app/config/app.yaml
#
#   # Check processes
#   ps aux
#   netstat -tuln
#
# Exit:
#   Type 'exit' or press Ctrl+D
#
# Notes:
#   - Container must be running
#   - Uses sh or bash depending on container
#   - Changes are temporary (lost on container restart)
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    echo "Example: $0 auth-service"
    exit 1
fi

SERVICE=$1

echo "🐚 Accessing ${SERVICE} shell..."
cd "$(dirname "$0")/../../docker"

docker-compose exec "${SERVICE}" sh || docker-compose exec "${SERVICE}" bash
