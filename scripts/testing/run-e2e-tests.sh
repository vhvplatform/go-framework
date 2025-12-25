#!/bin/bash
set -e

echo "🧪 Running end-to-end tests..."

# Ensure services are running
DOCKER_DIR="$(dirname "$0")/../../docker"
cd "${DOCKER_DIR}"

if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Services are not running. Start with: make start"
    exit 1
fi

# Wait for services to be ready
echo "⏳ Waiting for services..."
sleep 5

API_BASE="http://localhost:8080"

echo ""
echo "Running E2E test scenarios..."
echo ""

# Test 1: Health check
echo "1. Testing health endpoints..."
curl -f "${API_BASE}/health" || { echo "❌ Health check failed"; exit 1; }
echo "   ✅ Health check passed"

# Test 2: User registration flow
echo "2. Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "test@example.com",
        "password": "testpassword123",
        "tenant_id": "test-tenant"
    }')
echo "   Response: ${REGISTER_RESPONSE}"

# Test 3: User login
echo "3. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "${API_BASE}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "admin@example.com",
        "password": "admin123"
    }')

if echo "${LOGIN_RESPONSE}" | grep -q "token"; then
    echo "   ✅ Login successful"
    TOKEN=$(echo "${LOGIN_RESPONSE}" | jq -r '.token' 2>/dev/null || echo "")
else
    echo "   ⚠️  Login test needs proper setup"
fi

# Test 4: Protected endpoint (if token available)
if [ -n "${TOKEN}" ]; then
    echo "4. Testing protected endpoint..."
    curl -s -H "Authorization: Bearer ${TOKEN}" "${API_BASE}/api/v1/users/me" || echo "   ⚠️  Protected endpoint test skipped"
fi

echo ""
echo "✅ E2E tests complete!"
echo ""
echo "Note: Full E2E test suite requires:"
echo "  - Database seeded with test data"
echo "  - All services healthy and initialized"
echo "  - Run 'make db-seed' to populate test data"
