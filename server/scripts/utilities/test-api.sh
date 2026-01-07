#!/bin/bash

echo "🧪 Testing API endpoints..."

API_BASE="${API_BASE:-http://localhost:8080}"

echo "API Base URL: ${API_BASE}"
echo ""

# Test 1: Health check
echo "1. Health Check"
echo "   GET ${API_BASE}/health"
response=$(curl -s "${API_BASE}/health")
if [ $? -eq 0 ]; then
    echo "   ✅ Response: ${response}"
else
    echo "   ❌ Failed"
fi
echo ""

# Test 2: API version
echo "2. API Version"
echo "   GET ${API_BASE}/api/v1"
response=$(curl -s "${API_BASE}/api/v1" || echo "Not available")
echo "   Response: ${response}"
echo ""

# Test 3: Register user
echo "3. User Registration"
echo "   POST ${API_BASE}/api/v1/auth/register"
response=$(curl -s -X POST "${API_BASE}/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "test'$(date +%s)'@example.com",
        "password": "testpassword123",
        "name": "Test User",
        "tenant_id": "test-tenant"
    }' || echo "Registration endpoint not available")
echo "   Response: ${response}"
echo ""

# Test 4: Login
echo "4. User Login"
echo "   POST ${API_BASE}/api/v1/auth/login"
response=$(curl -s -X POST "${API_BASE}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "admin@example.com",
        "password": "admin123"
    }' || echo "Login endpoint not available")
echo "   Response: ${response}"

# Extract token if available
if command -v jq &> /dev/null; then
    token=$(echo "${response}" | jq -r '.token // empty' 2>/dev/null)
    if [ -n "${token}" ]; then
        echo ""
        echo "5. Protected Endpoint (with token)"
        echo "   GET ${API_BASE}/api/v1/users/me"
        response=$(curl -s -H "Authorization: Bearer ${token}" "${API_BASE}/api/v1/users/me")
        echo "   Response: ${response}"
    fi
fi

echo ""
echo "✅ API testing complete!"
echo ""
echo "💡 Tip: Install jq for better JSON output"
echo "   brew install jq  # macOS"
echo "   apt-get install jq  # Linux"
