#!/bin/bash
#
# Script: restore.sh
# Description: Restore MongoDB database from a backup file
# Usage: ./restore.sh <backup-file>
#
# ⚠️  WARNING: Existing data will be REPLACED!
#
# This script:
#   - Restores MongoDB database from backup archive
#   - Replaces existing data
#   - Restores all collections and indexes
#
# Arguments:
#   $1 - Path to backup file (required)
#        Format: backups/mongodb-backup-YYYY-MM-DD-HHMMSS.tar.gz
#
# Requirements:
#   - MongoDB must be running
#   - Valid backup file must exist
#   - Sufficient disk space
#
# Examples:
#   ./restore.sh backups/mongodb-backup-2024-01-15-120000.tar.gz
#   make db-restore FILE=backups/mongodb-backup-2024-01-15-120000.tar.gz
#
# Workflow:
#   1. List available backups: ls -lh backups/
#   2. Choose backup file
#   3. Run restore command
#   4. Verify data: make status
#
# Safety Tips:
#   - Create new backup before restore: make db-backup
#   - Verify backup file exists and is valid
#   - Test restore on non-production first
#   - Check disk space: df -h
#
# Restoration Time:
#   - Depends on backup size
#   - Typically 30-60 seconds
#   - Larger databases take longer
#
# Troubleshooting:
#   - Ensure MongoDB is running: docker ps | grep mongodb
#   - Check backup file: tar -tzf backup-file.tar.gz
#   - View logs: docker logs mongodb
#
# See Also:
#   - backup.sh: Create backup
#   - reset.sh: Clean database
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
