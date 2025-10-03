#!/bin/bash

# Generate new Let's Encrypt certificate with proper domain
# This script handles certificate generation for the correct domain

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values
DOMAIN_NAME=${DOMAIN_NAME:-biyadin.com}
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-admin@biyadin.com}

print_status "Generating new Let's Encrypt certificate..."
print_status "Domain: $DOMAIN_NAME"
print_status "Email: $LETSENCRYPT_EMAIL"

# Check if domain is accessible
print_status "Checking domain accessibility..."
if ! curl -s --head "http://$DOMAIN_NAME" > /dev/null; then
    print_warning "Domain $DOMAIN_NAME is not accessible via HTTP."
    print_warning "Make sure:"
    print_warning "1. DNS is pointing to this server (IP: $(curl -s ifconfig.me))"
    print_warning "2. Port 80 is open and accessible"
    print_warning "3. No firewall is blocking the connection"
    echo
    print_status "Current server IP: $(curl -s ifconfig.me)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start nginx without SSL first
print_status "Starting nginx without SSL for ACME challenges..."
docker-compose up -d nginx

# Wait for nginx to be ready
print_status "Waiting for nginx to be ready..."
sleep 10

# Check if nginx is running
if ! docker-compose ps nginx | grep -q "Up"; then
    print_error "Nginx failed to start. Check logs with: docker-compose logs nginx"
    exit 1
fi

# Generate certificates using the correct domain
print_status "Generating Let's Encrypt certificates for $DOMAIN_NAME..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$LETSENCRYPT_EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN_NAME" \
    -d "www.$DOMAIN_NAME"

# Check if certificates were generated successfully
if [ $? -eq 0 ]; then
    print_success "Certificates generated successfully!"
    
    # Check if certificate files exist in the container
    if docker-compose exec nginx test -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"; then
        print_success "Certificate files found in container"
        
        # Restart nginx with SSL
        print_status "Restarting nginx with SSL configuration..."
        docker-compose restart nginx
        
        # Wait for nginx to restart
        sleep 10
        
        # Test HTTPS
        print_status "Testing HTTPS connection..."
        if curl -s --head "https://$DOMAIN_NAME" > /dev/null; then
            print_success "HTTPS is working! Your site is now accessible via https://$DOMAIN_NAME"
        else
            print_warning "HTTPS test failed, but certificates are installed. Check nginx logs."
        fi
        
        print_success "Certificate generation complete!"
        print_status "Your WordPress site is now secured with Let's Encrypt certificates."
        
    else
        print_error "Certificate files not found after generation."
        print_error "Check certbot logs: docker-compose logs certbot"
        exit 1
    fi
else
    print_error "Certificate generation failed!"
    print_error "Check certbot logs: docker-compose logs certbot"
    print_error "Common issues:"
    print_error "1. Domain not accessible"
    print_error "2. Port 80 blocked"
    print_error "3. Rate limiting from Let's Encrypt"
    print_error "4. DNS not pointing to this server"
    exit 1
fi

print_success "New certificate generated successfully!"
