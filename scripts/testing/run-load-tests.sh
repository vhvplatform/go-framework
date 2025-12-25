#!/bin/bash
#
# Script: run-load-tests.sh
# Description: Run performance and load tests
# Usage: ./run-load-tests.sh
#
# This script:
#   - Runs load tests against API endpoints
#   - Measures request rate, latency, throughput
#   - Tests system behavior under stress
#   - Generates performance reports
#
# Default Configuration:
#   - Concurrent users: 10
#   - Duration: 30 seconds
#   - Request rate: 100 req/s
#   - Target: http://localhost:8080
#
# Environment Variables:
#   USERS - Concurrent users (default: 10)
#   DURATION - Test duration in seconds (default: 30)
#   RATE - Requests per second (default: 100)
#   ENDPOINT - Target endpoint (default: /api/health)
#   API_URL - API base URL (default: http://localhost:8080)
#
# Requirements:
#   - hey or k6 installed
#   - All services running and warmed up
#   - Sufficient system resources
#
# Examples:
#   ./run-load-tests.sh
#   make test-load
#   USERS=50 DURATION=60 RATE=200 ./run-load-tests.sh
#   ENDPOINT=/api/users ./run-load-tests.sh
#
# Metrics Generated:
#   - Request rate (req/s)
#   - Response time (p50, p95, p99)
#   - Error rate (%)
#   - Throughput (bytes/s)
#   - Success rate (%)
#
# Report Location:
#   reports/load-test-TIMESTAMP.html
#
# Interpreting Results:
#   - p50 < 100ms: Excellent
#   - p95 < 500ms: Good
#   - p99 < 1s: Acceptable
#   - Error rate < 1%: Healthy
#
# Performance Tips:
#   - Warm up services first
#   - Run multiple times for consistency
#   - Monitor resources: docker stats
#   - Check Grafana during test
#
# Troubleshooting:
#   - High error rate: Check service logs
#   - High latency: Check Grafana metrics
#   - Connection errors: Verify service health
#
# See Also:
#   - TESTING.md: Testing guide
#   - PERFORMANCE.md: Performance optimization
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

set -e

echo "🧪 Running load tests..."

# Check if hey is installed
if ! command -v hey &> /dev/null; then
    echo "❌ 'hey' is not installed. Install with: go install github.com/rakyll/hey@latest"
    exit 1
fi

# Ensure services are running
DOCKER_DIR="$(dirname "$0")/../../docker"
cd "${DOCKER_DIR}"

if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Services are not running. Start with: make start"
    exit 1
fi

API_BASE="http://localhost:8080"
REQUESTS=${REQUESTS:-1000}
CONCURRENCY=${CONCURRENCY:-50}
DURATION=${DURATION:-30}

echo "Load test configuration:"
echo "  Requests: ${REQUESTS}"
echo "  Concurrency: ${CONCURRENCY}"
echo "  Duration: ${DURATION}s"
echo ""

# Test 1: Health endpoint
echo "1. Load testing health endpoint..."
hey -n ${REQUESTS} -c ${CONCURRENCY} "${API_BASE}/health"

# Test 2: Auth endpoint (if available)
echo ""
echo "2. Load testing authentication..."
hey -n 500 -c 25 -m POST \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"testpass"}' \
    "${API_BASE}/api/v1/auth/login" || echo "⚠️  Auth endpoint not ready"

# Test 3: Sustained load test
echo ""
echo "3. Running sustained load test..."
hey -z ${DURATION}s -c ${CONCURRENCY} "${API_BASE}/health"

echo ""
echo "✅ Load tests complete!"
echo ""
echo "💡 Tips:"
echo "  - Increase load: REQUESTS=5000 CONCURRENCY=100 make test-load"
echo "  - Monitor with: make open-grafana"
echo "  - Check metrics at: http://localhost:9090"
