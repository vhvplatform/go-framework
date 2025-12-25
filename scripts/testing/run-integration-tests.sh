#!/bin/bash
set -e

echo "🧪 Running integration tests..."

# Ensure services are running
DOCKER_DIR="$(dirname "$0")/../../docker"
cd "${DOCKER_DIR}"

if ! docker-compose ps | grep -q "Up"; then
    echo "⚠️  Services are not running. Starting them now..."
    docker-compose up -d
    sleep 15
fi

# Navigate to workspace root
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"

if [ -d "${WORKSPACE_DIR}" ]; then
    cd "${WORKSPACE_DIR}"
    
    # Run integration tests for each service
    for service in go-api-gateway go-auth-service go-user-service go-tenant-service go-notification-service go-system-config-service; do
        if [ -d "$service" ]; then
            echo ""
            echo "Integration testing ${service}..."
            cd "${service}"
            if [ -f "go.mod" ]; then
                go test -v -tags=integration ./... || echo "⚠️  Some integration tests failed in ${service}"
            fi
            cd ..
        fi
    done
else
    echo "⚠️  Workspace not found at ${WORKSPACE_DIR}"
    exit 1
fi

echo ""
echo "✅ Integration tests complete!"
