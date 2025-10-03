#!/bin/bash

# Renew Let's Encrypt certificates
# This script should be run via cron job for automatic renewal

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values if not provided
DOMAIN_NAME=${DOMAIN_NAME:-biyadin.com}

echo "Renewing Let's Encrypt certificates for domain: $DOMAIN_NAME"

# Renew certificates
echo "Attempting to renew certificates..."
docker-compose run --rm certbot renew

# Check if renewal was successful
if [ $? -eq 0 ]; then
    echo "Certificate renewal successful!"
    
    # Reload nginx to use new certificates
    echo "Reloading nginx configuration..."
    docker-compose exec nginx nginx -s reload
    
    echo "Certificate renewal complete!"
else
    echo "Certificate renewal failed!"
    echo "Please check the logs for more information."
    exit 1
fi
