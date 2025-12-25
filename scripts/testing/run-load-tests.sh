#!/bin/bash
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
