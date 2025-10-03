#!/bin/bash
# Complete backup with monitoring

set -e

echo "Starting complete backup process at $(date)"

# Run database backup
echo "Running database backup..."
if ./scripts/backup-db.sh; then
    echo "Database backup successful"
else
    echo "Database backup failed"
    exit 1
fi

# Run files backup
echo "Running files backup..."
if ./scripts/backup-files.sh; then
    echo "Files backup successful"
else
    echo "Files backup failed"
    exit 1
fi

echo "Complete backup process finished at $(date)"
