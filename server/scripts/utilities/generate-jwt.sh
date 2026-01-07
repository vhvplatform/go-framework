#!/bin/bash
set -e

echo "🔑 Generating JWT token for testing..."

# Default values
USER_ID="${USER_ID:-test-user-123}"
EMAIL="${EMAIL:-test@example.com}"
TENANT_ID="${TENANT_ID:-test-tenant}"
SECRET="${JWT_SECRET:-dev-secret-change-in-production}"

# JWT Header
header='{
    "alg": "HS256",
    "typ": "JWT"
}'

# JWT Payload
payload='{
    "user_id": "'${USER_ID}'",
    "email": "'${EMAIL}'",
    "tenant_id": "'${TENANT_ID}'",
    "iat": '$(date +%s)',
    "exp": '$(date -d "+1 hour" +%s 2>/dev/null || date -v +1H +%s)'
}'

# Base64 encode
base64_encode() {
    echo -n "$1" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

header_base64=$(base64_encode "$header")
payload_base64=$(base64_encode "$payload")

# Create signature
header_payload="${header_base64}.${payload_base64}"
signature=$(echo -n "$header_payload" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Generate JWT
jwt="${header_payload}.${signature}"

echo ""
echo "Generated JWT Token:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$jwt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "User Information:"
echo "  User ID:   ${USER_ID}"
echo "  Email:     ${EMAIL}"
echo "  Tenant ID: ${TENANT_ID}"
echo ""
echo "Usage:"
echo "  curl -H \"Authorization: Bearer ${jwt}\" http://localhost:8080/api/v1/users/me"
echo ""
echo "Copy to clipboard (macOS): echo '${jwt}' | pbcopy"
echo "Copy to clipboard (Linux):  echo '${jwt}' | xclip -selection clipboard"
echo ""
