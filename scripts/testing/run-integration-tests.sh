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
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/saas-platform}"

if [ -d "${WORKSPACE_DIR}" ]; then
    cd "${WORKSPACE_DIR}"
    
    # Run integration tests for each service
    for service in saas-api-gateway saas-auth-service saas-user-service saas-tenant-service saas-notification-service saas-system-config-service; do
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
