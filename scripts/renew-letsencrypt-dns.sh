#!/bin/bash
# Renew Let's Encrypt SSL certificates using DNS-01 challenge
# This script should be run via cron for automatic renewal

set -e

DOMAIN_NAME="${DOMAIN_NAME:-biyadin.com}"
DNS_PROVIDER="${DNS_PROVIDER:-manual}"

echo "Renewing Let's Encrypt certificates for domain: $DOMAIN_NAME"
echo "DNS Provider: $DNS_PROVIDER"

# Check if certificates exist
if [ ! -d "/etc/letsencrypt/live/$DOMAIN_NAME" ]; then
    echo "No existing certificates found for $DOMAIN_NAME"
    echo "Please run init-letsencrypt-dns.sh first"
    exit 1
fi

# Check if renewal is needed (certificates expire in 30 days)
if ! docker-compose run --rm certbot certificates | grep -q "VALID: 30 days"; then
    echo "Certificates are still valid, no renewal needed"
    exit 0
fi

echo "Certificates are approaching expiration, renewing..."

# Renew certificates using DNS-01 challenge
if [ "$DNS_PROVIDER" = "manual" ]; then
    # Manual DNS challenge
    docker-compose run --rm certbot renew \
        --manual \
        --preferred-challenges dns \
        --manual-public-ip-logging-ok
else
    # Automated DNS challenge
    case $DNS_PROVIDER in
        "cloudflare")
            docker-compose run --rm certbot renew \
                --dns-cloudflare \
                --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini
            ;;
        "digitalocean")
            docker-compose run --rm certbot renew \
                --dns-digitalocean \
                --dns-digitalocean-credentials /etc/letsencrypt/digitalocean.ini
            ;;
        "route53")
            docker-compose run --rm certbot renew \
                --dns-route53
            ;;
        *)
            echo "Unsupported DNS provider: $DNS_PROVIDER"
            exit 1
            ;;
    esac
fi

# Reload nginx to use new certificates
echo "Reloading nginx with renewed certificates..."
docker-compose exec nginx nginx -s reload

echo "Certificate renewal completed successfully!"
