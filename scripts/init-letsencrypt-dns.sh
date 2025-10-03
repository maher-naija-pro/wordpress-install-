#!/bin/bash
# Initialize Let's Encrypt SSL certificates using DNS-01 challenge
# This works with CDN environments that block HTTP-01 challenges

set -e

DOMAIN_NAME="${DOMAIN_NAME:-biyadin.com}"
EMAIL="${LETSENCRYPT_EMAIL:-admin@biyadin.com}"
DNS_PROVIDER="${DNS_PROVIDER:-manual}"  # Options: cloudflare, digitalocean, route53, manual

echo "Initializing Let's Encrypt with DNS-01 challenge for domain: $DOMAIN_NAME"
echo "DNS Provider: $DNS_PROVIDER"

# Check if required environment variables are set
if [ "$DNS_PROVIDER" = "manual" ]; then
    echo "Manual DNS challenge mode selected."
    echo "You will need to manually add TXT records when prompted."
elif [ -z "$DNS_API_TOKEN" ]; then
    echo "Error: DNS_API_TOKEN environment variable is required for automated DNS challenges."
    echo "Please set your DNS provider API token in the .env file."
    exit 1
fi

# Start nginx without SSL first
echo "Starting nginx container..."
docker-compose up -d nginx

# Wait for nginx to be ready
echo "Waiting for nginx to be ready..."
sleep 10

# Get SSL certificate using DNS-01 challenge
echo "Requesting SSL certificate using DNS-01 challenge..."

if [ "$DNS_PROVIDER" = "manual" ]; then
    # Manual DNS challenge - user will add TXT records manually
    docker-compose run --rm certbot certonly \
        --manual \
        --preferred-challenges dns \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --manual-public-ip-logging-ok \
        -d "$DOMAIN_NAME" \
        -d "www.$DOMAIN_NAME"
else
    # Automated DNS challenge using DNS provider plugin
    case $DNS_PROVIDER in
        "cloudflare")
            docker-compose run --rm certbot certonly \
                --dns-cloudflare \
                --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                -d "$DOMAIN_NAME" \
                -d "www.$DOMAIN_NAME"
            ;;
        "digitalocean")
            docker-compose run --rm certbot certonly \
                --dns-digitalocean \
                --dns-digitalocean-credentials /etc/letsencrypt/digitalocean.ini \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                -d "$DOMAIN_NAME" \
                -d "www.$DOMAIN_NAME"
            ;;
        "route53")
            docker-compose run --rm certbot certonly \
                --dns-route53 \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                -d "$DOMAIN_NAME" \
                -d "www.$DOMAIN_NAME"
            ;;
        *)
            echo "Unsupported DNS provider: $DNS_PROVIDER"
            echo "Supported providers: cloudflare, digitalocean, route53, manual"
            exit 1
            ;;
    esac
fi

# Update nginx configuration with SSL
echo "Updating nginx configuration with SSL certificates..."
if [ -f "nginx/ssl.conf" ]; then
    # Replace placeholder domain with actual domain
    sed -i "s/biyadin.com/$DOMAIN_NAME/g" nginx/ssl.conf
    
    # Update SSL certificate paths to use Let's Encrypt certificates
    sed -i "s|/etc/nginx/certs/fullchain.pem|/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem|g" nginx/ssl.conf
    sed -i "s|/etc/nginx/certs/privkey.pem|/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem|g" nginx/ssl.conf
fi

# Restart nginx with SSL
echo "Restarting nginx with SSL configuration..."
docker-compose restart nginx

echo "SSL certificate initialization completed successfully!"
echo "Your site should now be accessible at https://$DOMAIN_NAME"
