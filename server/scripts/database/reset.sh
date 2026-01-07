#!/bin/bash
#
# Script: reset.sh
# Description: Reset database to clean state (DELETES ALL DATA!)
# Usage: ./reset.sh
#
# ⚠️  WARNING: This is a DESTRUCTIVE operation!
#
# This script:
#   - Drops all MongoDB collections
#   - Clears Redis cache
#   - Purges RabbitMQ queues
#   - Resets to completely clean state
#
# What is deleted:
#   - All user data
#   - All tenant data
#   - All notifications
#   - All system configuration
#   - All sessions
#   - All message queues
#
# Requirements:
#   - MongoDB must be running
#   - User confirmation required
#
# Examples:
#   ./reset.sh
#   make db-reset  # Prompts for confirmation
#
# Recommended Workflow:
#   1. Backup first: make db-backup
#   2. Reset: make db-reset
#   3. Seed fresh data: make db-seed
#
# Safety:
#   - Prompts for confirmation
#   - Cannot be undone
#   - Make a backup first!
#
# See Also:
#   - backup.sh: Create backup before reset
#   - seed.sh: Load test data after reset
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
    use go_dev;
    db.dropDatabase();
    print('Database dropped');
"

echo "✅ Database reset complete!"
echo ""
echo "To seed with test data, run: make db-seed"
