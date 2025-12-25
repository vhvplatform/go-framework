#!/bin/bash
set -e

DOCKER_DIR="$(dirname "$0")/../../docker"
BACKUP_DIR="$(dirname "$0")/../../backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/mongodb_backup_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo "💾 Backing up MongoDB..."

cd "${DOCKER_DIR}"

# Create backup using mongodump
docker-compose exec -T mongodb mongodump \
    --db saas_dev \
    --archive \
    --gzip > "${BACKUP_FILE}"

echo "✅ Backup created: ${BACKUP_FILE}"
echo "   Size: $(du -h "${BACKUP_FILE}" | cut -f1)"
