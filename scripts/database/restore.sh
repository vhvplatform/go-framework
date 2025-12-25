#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file>"
    echo "Example: $0 backups/mongodb_backup_20240101_120000.tar.gz"
    exit 1
fi

BACKUP_FILE=$1
DOCKER_DIR="$(dirname "$0")/../../docker"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "❌ Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "⚠️  WARNING: This will replace all data in the database!"
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "📥 Restoring MongoDB from ${BACKUP_FILE}..."

cd "${DOCKER_DIR}"

# Restore backup using mongorestore
docker-compose exec -T mongodb mongorestore \
    --archive \
    --gzip \
    --drop < "${BACKUP_FILE}"

echo "✅ Database restored successfully!"
