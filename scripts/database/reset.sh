#!/bin/bash
set -e

echo "⚠️  WARNING: This will delete all data in the database!"
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

DOCKER_DIR="$(dirname "$0")/../../docker"
cd "${DOCKER_DIR}"

echo "🗑️  Resetting database..."

# Drop the database
docker-compose exec mongodb mongosh --eval "
    use saas_dev;
    db.dropDatabase();
    print('Database dropped');
"

echo "✅ Database reset complete!"
echo ""
echo "To seed with test data, run: make db-seed"
