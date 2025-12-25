#!/bin/bash
set -e

echo "📊 Generating test data..."

FIXTURES_DIR="$(dirname "$0")/../../fixtures"
mkdir -p "${FIXTURES_DIR}"

# Generate sample users
cat > "${FIXTURES_DIR}/users.json" << 'EOF'
[
  {
    "id": "user-1",
    "email": "admin@example.com",
    "name": "Admin User",
    "tenant_id": "tenant-1",
    "role": "admin",
    "created_at": "2024-01-01T00:00:00Z"
  },
  {
    "id": "user-2",
    "email": "user@example.com",
    "name": "Regular User",
    "tenant_id": "tenant-1",
    "role": "user",
    "created_at": "2024-01-01T00:00:00Z"
  },
  {
    "id": "user-3",
    "email": "test@example.com",
    "name": "Test User",
    "tenant_id": "tenant-2",
    "role": "user",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
EOF

# Generate sample tenants
cat > "${FIXTURES_DIR}/tenants.json" << 'EOF'
[
  {
    "id": "tenant-1",
    "name": "Acme Corporation",
    "slug": "acme",
    "plan": "enterprise",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z"
  },
  {
    "id": "tenant-2",
    "name": "Test Company",
    "slug": "testco",
    "plan": "pro",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
EOF

# Generate sample roles
cat > "${FIXTURES_DIR}/roles.json" << 'EOF'
[
  {
    "id": "role-1",
    "name": "admin",
    "permissions": ["read", "write", "delete", "admin"],
    "description": "Full system access"
  },
  {
    "id": "role-2",
    "name": "user",
    "permissions": ["read", "write"],
    "description": "Standard user access"
  },
  {
    "id": "role-3",
    "name": "viewer",
    "permissions": ["read"],
    "description": "Read-only access"
  }
]
EOF

echo "✅ Test data generated in ${FIXTURES_DIR}/"
echo ""
echo "Files created:"
echo "  - users.json (3 users)"
echo "  - tenants.json (2 tenants)"
echo "  - roles.json (3 roles)"
echo ""
echo "To load into database: make db-seed"
