#!/bin/bash
# WordPress Files Backup Script

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
WORDPRESS_DIR="/var/www/html"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Starting files backup at $(date)"

# Create files backup with rsync
rsync -av --delete \
    --exclude="wp-content/cache/*" \
    --exclude="wp-content/uploads/cache/*" \
    --exclude="*.log" \
    --exclude=".git/*" \
    "$WORDPRESS_DIR/" "$BACKUP_DIR/files_${TIMESTAMP}/"

# Create compressed archive
cd "$BACKUP_DIR"
tar -czf "files_${TIMESTAMP}.tar.gz" "files_${TIMESTAMP}/"
rm -rf "files_${TIMESTAMP}/"

# Verify backup
if [ -f "$BACKUP_DIR/files_${TIMESTAMP}.tar.gz" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/files_${TIMESTAMP}.tar.gz" | cut -f1)
    echo "Files backup completed successfully: $BACKUP_SIZE"
    
    # Create symlink to latest backup
    ln -sf "files_${TIMESTAMP}.tar.gz" "$BACKUP_DIR/files_latest.tar.gz"
    
    # Clean up old backups (keep last 30 days)
    find "$BACKUP_DIR" -name "files_*.tar.gz" -mtime +30 -delete
    
    echo "Files backup process completed at $(date)"
    exit 0
else
    echo "Files backup failed at $(date)"
    exit 1
fi
