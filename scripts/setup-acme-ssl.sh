#!/bin/bash

# Complete ACME SSL setup script for WordPress
# This script handles the entire process of setting up Let's Encrypt certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_status "Starting ACME SSL setup for WordPress..."

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from env.example..."
    if [ -f env.example ]; then
        cp env.example .env
        print_warning "Please edit .env file with your domain and email before continuing."
        print_warning "Required variables: DOMAIN_NAME, LETSENCRYPT_EMAIL"
        read -p "Press Enter after updating .env file..."
    else
        print_error "No env.example file found. Please create .env file manually."
        exit 1
    fi
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Validate required variables
if [ -z "$DOMAIN_NAME" ] || [ -z "$LETSENCRYPT_EMAIL" ]; then
    print_error "Required environment variables not set:"
    print_error "DOMAIN_NAME: $DOMAIN_NAME"
    print_error "LETSENCRYPT_EMAIL: $LETSENCRYPT_EMAIL"
    print_error "Please update your .env file with these values."
    exit 1
fi

print_status "Domain: $DOMAIN_NAME"
print_status "Email: $LETSENCRYPT_EMAIL"

# Check if domain is accessible
print_status "Checking domain accessibility..."
if ! curl -s --head "http://$DOMAIN_NAME" > /dev/null; then
    print_warning "Domain $DOMAIN_NAME is not accessible via HTTP."
    print_warning "Make sure:"
    print_warning "1. DNS is pointing to this server"
    print_warning "2. Port 80 is open and accessible"
    print_warning "3. No firewall is blocking the connection"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Stop any existing containers
print_status "Stopping existing containers..."
docker-compose down

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p ./certs
mkdir -p ./nginx/conf.d

# Start nginx without SSL to handle ACME challenges
print_status "Starting nginx without SSL for ACME challenges..."
docker-compose up -d nginx

# Wait for nginx to be ready
print_status "Waiting for nginx to be ready..."
sleep 15

# Check if nginx is running
if ! docker-compose ps nginx | grep -q "Up"; then
    print_error "Nginx failed to start. Check logs with: docker-compose logs nginx"
    exit 1
fi

# Generate initial certificates
print_status "Generating Let's Encrypt certificates..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$LETSENCRYPT_EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN_NAME" \
    -d "www.$DOMAIN_NAME"

# Check if certificates were generated
if [ $? -eq 0 ]; then
    print_success "Certificates generated successfully!"
    
    # Check certificate files
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
        
        # Setup automatic renewal
        print_status "Setting up automatic certificate renewal..."
        chmod +x "$SCRIPT_DIR/setup-ssl-cron.sh"
        "$SCRIPT_DIR/setup-ssl-cron.sh"
        
        print_success "ACME SSL setup complete!"
        print_status "Your WordPress site is now secured with Let's Encrypt certificates."
        print_status "Certificates will automatically renew every 60 days."
        
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
    exit 1
fi

print_success "ACME SSL setup completed successfully!"
