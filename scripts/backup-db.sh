#!/bin/bash
# WordPress Database Backup Script

set -e

# Configuration
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DB_NAME="${POSTGRES_DB:-wordpress}"
DB_USER="${POSTGRES_USER:-wordpress}"
DB_PASSWORD="${POSTGRES_PASSWORD:-wordpress_password}"
DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Set PGPASSWORD for non-interactive backup
export PGPASSWORD="$DB_PASSWORD"

# Create database backup
echo "Starting database backup at $(date)"
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    --verbose --no-password --format=custom --compress=9 \
    --file="$BACKUP_DIR/database_${TIMESTAMP}.sql.gz"

# Verify backup
if [ -f "$BACKUP_DIR/database_${TIMESTAMP}.sql.gz" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/database_${TIMESTAMP}.sql.gz" | cut -f1)
    echo "Database backup completed successfully: $BACKUP_SIZE"
    
    # Create symlink to latest backup
    ln -sf "database_${TIMESTAMP}.sql.gz" "$BACKUP_DIR/database_latest.sql.gz"
    
    # Clean up old backups (keep last 30 days)
    find "$BACKUP_DIR" -name "database_*.sql.gz" -mtime +30 -delete
    
    echo "Database backup process completed at $(date)"
    exit 0
else
    echo "Database backup failed at $(date)"
    exit 1
fi
