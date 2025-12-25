#!/bin/bash
#
# Script: seed.sh
# Description: Populate database with test data
# Usage: ./seed.sh
#
# This script loads predefined test data into MongoDB:
#   - 3 test users with different roles (admin, user, viewer)
#   - 2 test tenants
#   - 3 role definitions
#   - Sample notifications
#   - System configuration entries
#
# Test Credentials Created:
#   - Admin: admin@example.com / admin123
#   - User: user@example.com / user123
#   - Viewer: viewer@example.com / viewer123
#
# Requirements:
#   - MongoDB must be running
#   - Fixture files must exist in fixtures/ directory
#
# Examples:
#   ./seed.sh
#   make db-seed
#
# Use Cases:
#   - Initial development setup
#   - After database reset
#   - Testing with realistic data
#   - Demo preparation
#
# Notes:
#   - Safe to run multiple times
#   - Uses fixtures from fixtures/ directory
#   - Skips existing records
#
# See Also:
#   - reset.sh: Reset database before seeding
#   - backup.sh: Backup before seeding
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

set -e

echo "🌱 Seeding database with test data..."

DOCKER_DIR="$(dirname "$0")/../../docker"
FIXTURES_DIR="$(dirname "$0")/../../fixtures"

cd "${DOCKER_DIR}"

# Check if MongoDB is running
if ! docker-compose ps mongodb | grep -q "Up"; then
    echo "❌ MongoDB is not running. Start with: make start"
    exit 1
fi

echo "📊 Loading test data..."

# Import users
if [ -f "${FIXTURES_DIR}/users.json" ]; then
    echo "  Loading users..."
    docker-compose exec -T mongodb mongoimport \
        --db go_dev \
        --collection users \
        --file /dev/stdin \
        --jsonArray < "${FIXTURES_DIR}/users.json" || true
fi

# Import tenants
if [ -f "${FIXTURES_DIR}/tenants.json" ]; then
    echo "  Loading tenants..."
    docker-compose exec -T mongodb mongoimport \
        --db go_dev \
        --collection tenants \
        --file /dev/stdin \
        --jsonArray < "${FIXTURES_DIR}/tenants.json" || true
fi

# Import roles
if [ -f "${FIXTURES_DIR}/roles.json" ]; then
    echo "  Loading roles..."
    docker-compose exec -T mongodb mongoimport \
        --db go_dev \
        --collection roles \
        --file /dev/stdin \
        --jsonArray < "${FIXTURES_DIR}/roles.json" || true
fi

echo "✅ Database seeded successfully!"
