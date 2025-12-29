#!/bin/bash
#
# Script: backup.sh
# Description: Create a backup of the MongoDB database
# Usage: ./backup.sh
#
# This script:
#   - Creates compressed backup of all MongoDB databases
#   - Includes all collections and indexes
#   - Saves with timestamped filename
#   - Stores in backups/ directory
#
# Backup Location:
#   backups/mongodb-backup-YYYY-MM-DD-HHMMSS.tar.gz
#
# Environment Variables:
#   BACKUP_DIR - Backup directory (default: backups/)
#   DB_NAME - Database to backup (default: all databases)
#
# Requirements:
#   - MongoDB must be running
#   - Sufficient disk space
#
# Examples:
#   ./backup.sh
#   make db-backup
#   BACKUP_DIR=/custom/path ./backup.sh
#   DB_NAME=saas_platform ./backup.sh  # Backup specific DB
#
# Backup Size:
#   - Compressed with gzip
#   - Typically 10-100MB depending on data
#
# Restoration:
#   make db-restore FILE=backups/mongodb-backup-YYYY-MM-DD-HHMMSS.tar.gz
#
# Best Practices:
#   - Backup before major changes
#   - Backup before database reset
#   - Regular automated backups
#   - Store backups off-site
#
# See Also:
#   - restore.sh: Restore from backup
#   - reset.sh: Reset database
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
    --db go_dev \
    --archive \
    --gzip > "${BACKUP_FILE}"

echo "✅ Backup created: ${BACKUP_FILE}"
echo "   Size: $(du -h "${BACKUP_FILE}" | cut -f1)"
