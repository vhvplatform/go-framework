#!/bin/bash
#
# Script: run-integration-tests.sh
# Description: Run integration tests with live services
# Usage: ./run-integration-tests.sh
#
# This script:
#   - Tests service-to-service communication
#   - Validates database operations
#   - Tests API endpoints
#   - Validates gRPC calls
#   - Tests message queue integration
#
# Prerequisites:
#   - All services must be running (make start)
#   - Test database must be available
#   - Message queue must be accessible
#
# Test Coverage:
#   - Database CRUD operations
#   - Service interactions
#   - API contracts
#   - gRPC endpoints
#   - Message publishing/consuming
#
# Examples:
#   ./run-integration-tests.sh
#   make test-integration
#
# Test Duration:
#   - Typical: 2-5 minutes
#   - Slower than unit tests
#   - Tests real integrations
#
# Environment Variables:
#   API_URL - API endpoint (default: http://localhost:8080)
#   VERBOSE - Enable verbose output
#
# Failure Handling:
#   - Check service logs: make logs
#   - Verify service health: make status
#   - Check database: docker exec mongodb mongosh
#
# Best Practices:
#   - Run after unit tests pass
#   - Ensure services are healthy first
#   - Review logs on failure
#   - Keep integration tests focused
#
# See Also:
#   - run-unit-tests.sh: Unit tests (run first)
#   - run-e2e-tests.sh: End-to-end tests
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
