#!/bin/bash
# Initialize Let's Encrypt SSL certificates

set -e

DOMAIN_NAME="${DOMAIN_NAME:-localhost}"
EMAIL="${LETSENCRYPT_EMAIL:-admin@example.com}"

echo "Initializing Let's Encrypt for domain: $DOMAIN_NAME"

# Start nginx without SSL first
docker-compose up -d nginx

# Wait for nginx to be ready
sleep 10

# Get SSL certificate
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN_NAME"

# Update nginx configuration with SSL
if [ -f "nginx/ssl.conf" ]; then
    # Replace placeholder domain with actual domain
    sed -i "s/yourdomain.com/$DOMAIN_NAME/g" nginx/ssl.conf
fi

# Restart nginx with SSL
docker-compose restart nginx

echo "SSL certificate initialization completed"
