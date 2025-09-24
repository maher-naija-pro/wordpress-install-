#!/bin/bash
# Setup monitoring stack

set -e

echo "Setting up monitoring stack..."

# Start monitoring services
docker-compose up -d prometheus grafana alertmanager

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check if services are running
echo "Checking service status..."
docker-compose ps

echo "Monitoring stack setup completed!"
echo "Access Grafana at: http://localhost:3000 (admin/admin123)"
echo "Access Prometheus at: http://localhost:9090"
echo "Access Alertmanager at: http://localhost:9093"
