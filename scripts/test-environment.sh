#!/bin/bash
# Test script for WordPress Docker environment

set -e

echo "Testing WordPress Docker Environment"
echo "===================================="

# Test 1: Check if Docker is running
echo "1. Checking Docker..."
if docker --version > /dev/null 2>&1; then
    echo "   ✓ Docker is installed"
else
    echo "   ✗ Docker is not installed or not running"
    exit 1
fi

# Test 2: Check if Docker Compose is available
echo "2. Checking Docker Compose..."
if docker-compose --version > /dev/null 2>&1; then
    echo "   ✓ Docker Compose is available"
else
    echo "   ✗ Docker Compose is not available"
    exit 1
fi

# Test 3: Check environment file
echo "3. Checking environment configuration..."
if [ -f ".env" ]; then
    echo "   ✓ .env file exists"
else
    echo "   ⚠ .env file not found, copying from example..."
    cp env.example .env
    echo "   ✓ Created .env file from template"
fi

# Test 4: Validate Docker Compose configuration
echo "4. Validating Docker Compose configuration..."
if docker-compose config > /dev/null 2>&1; then
    echo "   ✓ Docker Compose configuration is valid"
else
    echo "   ✗ Docker Compose configuration has errors"
    exit 1
fi

# Test 5: Check if services can start
echo "5. Testing service startup..."
echo "   Starting services in background..."
docker-compose up -d

# Wait for services to start
echo "   Waiting for services to initialize..."
sleep 30

# Test 6: Check service health
echo "6. Checking service health..."
SERVICES=("wordpress_postgres" "wordpress_app" "wordpress_nginx" "wordpress_prometheus" "wordpress_grafana")

for service in "${SERVICES[@]}"; do
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$service.*Up"; then
        echo "   ✓ $service is running"
    else
        echo "   ✗ $service is not running"
    fi
done

# Test 7: Check WordPress accessibility
echo "7. Testing WordPress accessibility..."
if curl -f http://109.232.234.153 > /dev/null 2>&1; then
    echo "   ✓ WordPress is accessible on port 80"
else
    echo "   ⚠ WordPress not accessible on port 80 (may need SSL setup)"
fi

# Test 8: Check monitoring services
echo "8. Testing monitoring services..."
if curl -f http://109.232.234.153:3000 > /dev/null 2>&1; then
    echo "   ✓ Grafana is accessible on port 3000"
else
    echo "   ✗ Grafana is not accessible"
fi

if curl -f http://109.232.234.153:9090 > /dev/null 2>&1; then
    echo "   ✓ Prometheus is accessible on port 9090"
else
    echo "   ✗ Prometheus is not accessible"
fi

# Test 9: Check database connectivity
echo "9. Testing database connectivity..."
if docker-compose exec -T postgres pg_isready -U wordpress > /dev/null 2>&1; then
    echo "   ✓ PostgreSQL is ready"
else
    echo "   ✗ PostgreSQL is not ready"
fi

# Test 10: Check backup scripts
echo "10. Testing backup scripts..."
if [ -x "scripts/backup-db.sh" ]; then
    echo "   ✓ Database backup script is executable"
else
    echo "   ✗ Database backup script is not executable"
fi

if [ -x "scripts/backup-files.sh" ]; then
    echo "   ✓ Files backup script is executable"
else
    echo "   ✗ Files backup script is not executable"
fi

echo ""
echo "Test Summary"
echo "============"
echo "Environment test completed!"
echo ""
echo "Access URLs:"
echo "- WordPress: http://109.232.234.153"
echo "- Grafana: http://109.232.234.153:3000 (admin/admin123)"
echo "- Prometheus: http://109.232.234.153:9090"
echo "- Alertmanager: http://109.232.234.153:9093"
echo ""
echo "Next steps:"
echo "1. Configure your domain in .env file"
echo "2. Run: ./scripts/init-letsencrypt.sh"
echo "3. Setup monitoring: ./scripts/setup-monitoring.sh"
echo "4. Configure backup schedules"
