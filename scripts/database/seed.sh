#!/bin/bash
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
        --db saas_dev \
        --collection users \
        --file /dev/stdin \
        --jsonArray < "${FIXTURES_DIR}/users.json" || true
fi

# Import tenants
if [ -f "${FIXTURES_DIR}/tenants.json" ]; then
    echo "  Loading tenants..."
    docker-compose exec -T mongodb mongoimport \
        --db saas_dev \
        --collection tenants \
        --file /dev/stdin \
        --jsonArray < "${FIXTURES_DIR}/tenants.json" || true
fi

# Import roles
if [ -f "${FIXTURES_DIR}/roles.json" ]; then
    echo "  Loading roles..."
    docker-compose exec -T mongodb mongoimport \
        --db saas_dev \
        --collection roles \
        --file /dev/stdin \
        --jsonArray < "${FIXTURES_DIR}/roles.json" || true
fi

echo "✅ Database seeded successfully!"
