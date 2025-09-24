#!/bin/bash

# Docker Installation Test Script
# This script tests if Docker and Docker Compose are properly installed and working

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

# Test Docker installation
test_docker() {
    log "Testing Docker installation..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Check Docker version
    DOCKER_VERSION=$(docker --version)
    log_success "Docker installed: $DOCKER_VERSION"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        return 1
    fi
    
    log_success "Docker daemon is running"
    return 0
}

# Test Docker Compose installation
test_docker_compose() {
    log "Testing Docker Compose installation..."
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        return 1
    fi
    
    # Check Docker Compose version
    COMPOSE_VERSION=$(docker-compose --version)
    log_success "Docker Compose installed: $COMPOSE_VERSION"
    
    return 0
}

# Test Docker functionality
test_docker_functionality() {
    log "Testing Docker functionality..."
    
    # Test with hello-world container
    log "Running hello-world container test..."
    if docker run --rm hello-world > /dev/null 2>&1; then
        log_success "Docker hello-world test passed"
    else
        log_error "Docker hello-world test failed"
        return 1
    fi
    
    # Test Docker Compose functionality
    log "Testing Docker Compose functionality..."
    if docker-compose --version > /dev/null 2>&1; then
        log_success "Docker Compose functionality test passed"
    else
        log_error "Docker Compose functionality test failed"
        return 1
    fi
    
    return 0
}

# Test Docker permissions
test_docker_permissions() {
    log "Testing Docker permissions..."
    
    # Check if user can run Docker without sudo
    if docker ps &> /dev/null; then
        log_success "Docker permissions configured correctly (no sudo required)"
    else
        log_warning "Docker requires sudo. You may need to log out and log back in for group changes to take effect."
        log "Testing with sudo..."
        if sudo docker ps &> /dev/null; then
            log_success "Docker works with sudo"
        else
            log_error "Docker does not work even with sudo"
            return 1
        fi
    fi
    
    return 0
}

# Test Docker service status
test_docker_service() {
    log "Testing Docker service status..."
    
    if systemctl is-active --quiet docker; then
        log_success "Docker service is running"
    else
        log_error "Docker service is not running"
        return 1
    fi
    
    if systemctl is-enabled --quiet docker; then
        log_success "Docker service is enabled (will start on boot)"
    else
        log_warning "Docker service is not enabled (will not start on boot)"
    fi
    
    return 0
}

# Display system information
display_system_info() {
    log "System Information:"
    echo "  - OS: $(lsb_release -d | cut -f2)"
    echo "  - Kernel: $(uname -r)"
    echo "  - Architecture: $(uname -m)"
    echo "  - User: $(whoami)"
    echo "  - Groups: $(groups)"
    echo
}

# Main test function
main() {
    echo "=========================================="
    echo "Docker Installation Test Script"
    echo "=========================================="
    echo
    
    display_system_info
    
    local tests_passed=0
    local total_tests=5
    
    # Run tests
    if test_docker; then
        ((tests_passed++))
    fi
    
    if test_docker_compose; then
        ((tests_passed++))
    fi
    
    if test_docker_functionality; then
        ((tests_passed++))
    fi
    
    if test_docker_permissions; then
        ((tests_passed++))
    fi
    
    if test_docker_service; then
        ((tests_passed++))
    fi
    
    echo
    echo "=========================================="
    echo "Test Results: $tests_passed/$total_tests tests passed"
    echo "=========================================="
    
    if [[ $tests_passed -eq $total_tests ]]; then
        log_success "All tests passed! Docker and Docker Compose are properly installed and working."
        echo
        echo "You can now use Docker and Docker Compose for your WordPress project:"
        echo "  - Run: docker-compose up -d"
        echo "  - Check status: docker-compose ps"
        echo "  - View logs: docker-compose logs"
        return 0
    else
        log_error "Some tests failed. Please check the output above for details."
        echo
        echo "Common solutions:"
        echo "  - If Docker requires sudo: Log out and log back in"
        echo "  - If Docker service is not running: sudo systemctl start docker"
        echo "  - If permissions are wrong: sudo usermod -aG docker \$USER"
        return 1
    fi
}

# Run main function
main "$@"
