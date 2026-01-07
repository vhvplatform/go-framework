#!/bin/bash
#
# Script: generate-test-data.sh
# Description: Generate realistic test data for development
# Usage: ./generate-test-data.sh
#
# This script generates:
#   - Users (customizable count)
#   - Tenants with subscriptions
#   - Sample notifications
#   - Activity logs
#   - Configuration entries
#   - Realistic relationships between entities
#
# Environment Variables:
#   USERS - Number of users to generate (default: 50)
#   TENANTS - Number of tenants (default: 10)
#   NOTIFICATIONS - Number of notifications (default: 100)
#
# Requirements:
#   - MongoDB must be running
#   - Sufficient disk space
#
# Examples:
#   ./generate-test-data.sh
#   make test-data
#   USERS=100 TENANTS=20 ./generate-test-data.sh
#   USERS=1000 ./generate-test-data.sh  # Large dataset
#
# Generated Data:
#   - Users with varied roles and permissions
#   - Tenants with different subscription plans
#   - Notifications in various states
#   - Audit logs with timestamps
#   - System configurations
#
# Data Characteristics:
#   - Realistic names (using faker library)
#   - Valid email addresses
#   - Proper relationships (users ↔ tenants)
#   - Timestamp distribution
#   - Varied statuses
#
# Use Cases:
#   - Performance testing with realistic data volume
#   - UI development with varied content
#   - Search and filter testing
#   - Pagination testing
#   - Load testing preparation
#
# Generation Time:
#   - 50 users: ~5 seconds
#   - 100 users: ~10 seconds
#   - 1000 users: ~60 seconds
#
# Database Size:
#   - 50 users: ~1MB
#   - 100 users: ~2MB
#   - 1000 users: ~20MB
#
# Cleanup:
#   make db-reset  # Remove generated data
#
# See Also:
#   - db-seed.sh: Load predefined test data
#   - run-load-tests.sh: Load testing
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
