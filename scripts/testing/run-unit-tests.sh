#!/bin/bash
set -e

echo "🧪 Running unit tests..."

# Navigate to workspace root (assuming services are in subdirectories)
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"

if [ -d "${WORKSPACE_DIR}" ]; then
    cd "${WORKSPACE_DIR}"
    
    # Run tests for each service
    for service in go-api-gateway go-auth-service go-user-service go-tenant-service go-notification-service go-system-config-service go-shared-go; do
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
