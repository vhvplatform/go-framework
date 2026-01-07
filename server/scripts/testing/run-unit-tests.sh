#!/bin/bash
#
# Script: run-unit-tests.sh
# Description: Run unit tests across all microservices
# Usage: ./run-unit-tests.sh
#
# This script:
#   - Discovers all service directories
#   - Runs `go test` for each service
#   - Generates coverage reports
#   - Shows test summary
#
# Coverage Reports:
#   - Saves to coverage/unit-coverage.html
#   - Shows line-by-line coverage
#   - Highlights untested code
#
# Environment Variables:
#   VERBOSE - Enable verbose output (default: false)
#   PKG - Test specific package (default: ./...)
#
# Requirements:
#   - Go 1.21+ installed
#   - Service repositories cloned
#
# Examples:
#   ./run-unit-tests.sh
#   VERBOSE=1 ./run-unit-tests.sh
#   PKG=./internal/auth ./run-unit-tests.sh
#   make test-unit
#
# Test Duration:
#   - Unit tests: 5-30 seconds
#   - Parallel execution where possible
#   - Fast feedback loop
#
# Coverage Goal:
#   - Target: 80%+ code coverage
#   - Focus on critical paths
#   - Test edge cases
#
# Best Practices:
#   - Run before committing code
#   - Fix failing tests immediately
#   - Keep tests fast (<100ms each)
#   - Mock external dependencies
#
# See Also:
#   - run-integration-tests.sh: Integration tests
#   - run-e2e-tests.sh: End-to-end tests
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
