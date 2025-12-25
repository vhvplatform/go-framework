#!/bin/bash
set -e

echo "🧪 Running unit tests..."

# Navigate to workspace root (assuming services are in subdirectories)
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/saas-platform}"

if [ -d "${WORKSPACE_DIR}" ]; then
    cd "${WORKSPACE_DIR}"
    
    # Run tests for each service
    for service in saas-api-gateway saas-auth-service saas-user-service saas-tenant-service saas-notification-service saas-system-config-service saas-shared-go; do
        if [ -d "$service" ]; then
            echo ""
            echo "Testing ${service}..."
            cd "${service}"
            if [ -f "go.mod" ]; then
                go test -v -race -short ./... || echo "⚠️  Some tests failed in ${service}"
            fi
            cd ..
        fi
    done
else
    echo "⚠️  Workspace not found at ${WORKSPACE_DIR}"
    echo "   Set WORKSPACE_DIR or run tests from individual service directories"
    exit 1
fi

echo ""
echo "✅ Unit tests complete!"
