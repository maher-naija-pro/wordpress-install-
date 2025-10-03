#!/bin/bash

# Setup automatic SSL certificate renewal via cron
# This script sets up a cron job to automatically renew certificates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Setting up automatic SSL certificate renewal..."

# Make scripts executable
chmod +x "$SCRIPT_DIR/renew-certs.sh"

# Create cron job for certificate renewal (runs twice daily)
CRON_JOB="0 2,14 * * * cd $PROJECT_DIR && $SCRIPT_DIR/renew-certs.sh >> /var/log/letsencrypt-renewal.log 2>&1"

# Add cron job if it doesn't exist
if ! crontab -l 2>/dev/null | grep -q "renew-certs.sh"; then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added successfully!"
    echo "Certificate renewal will run twice daily at 2:00 AM and 2:00 PM"
else
    echo "Cron job already exists for certificate renewal"
fi

# Show current cron jobs
echo "Current cron jobs:"
crontab -l

echo "SSL certificate auto-renewal setup complete!"
