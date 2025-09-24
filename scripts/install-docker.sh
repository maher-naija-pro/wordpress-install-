#!/bin/bash

# Docker Installation Script for Ubuntu
# Based on official Docker documentation: https://docs.docker.com/engine/install/ubuntu/
# This script installs Docker Engine and Docker Compose on Ubuntu systems

set -e  # Exit on any error

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check if sudo is available
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        log_error "sudo is not installed. Please install sudo first."
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        log "This script requires sudo privileges. You may be prompted for your password."
    fi
}

# Detect Ubuntu version
detect_ubuntu_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            log "Detected Ubuntu $VERSION_CODENAME"
            UBUNTU_CODENAME="$VERSION_CODENAME"
        else
            log_error "This script is designed for Ubuntu. Detected: $ID"
            exit 1
        fi
    else
        log_error "Cannot detect Ubuntu version. /etc/os-release not found."
        exit 1
    fi
}

# Check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        log_warning "Docker is already installed: $(docker --version)"
        read -p "Do you want to continue with the installation? This may update Docker. (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Installation cancelled."
            exit 0
        fi
    fi
}

# Remove old Docker packages
remove_old_docker() {
    log "Removing old Docker packages..."
    
    # Remove old Docker packages
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        if dpkg -l | grep -q "^ii.*$pkg"; then
            log "Removing $pkg..."
            sudo apt-get remove -y $pkg || true
        fi
    done
    
    log_success "Old Docker packages removed"
}

# Update package index
update_packages() {
    log "Updating package index..."
    sudo apt-get update
    log_success "Package index updated"
}

# Install prerequisites
install_prerequisites() {
    log "Installing prerequisites..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    log_success "Prerequisites installed"
}

# Add Docker's official GPG key
add_docker_gpg_key() {
    log "Adding Docker's official GPG key..."
    
    # Create directory for keyrings
    sudo install -m 0755 -d /etc/apt/keyrings
    
    # Download and add GPG key
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    log_success "Docker GPG key added"
}

# Add Docker repository
add_docker_repository() {
    log "Adding Docker repository..."
    
    # Add repository to sources
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index
    sudo apt-get update
    
    log_success "Docker repository added"
}

# Install Docker Engine
install_docker_engine() {
    log "Installing Docker Engine..."
    
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    log_success "Docker Engine installed"
}

# Start and enable Docker service
start_docker_service() {
    log "Starting Docker service..."
    
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Verify Docker is running
    if sudo systemctl is-active --quiet docker; then
        log_success "Docker service is running"
    else
        log_error "Failed to start Docker service"
        exit 1
    fi
}

# Configure Docker permissions
configure_docker_permissions() {
    log "Configuring Docker permissions..."
    
    # Add user to docker group
    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker $USER
    
    # Set socket permissions (temporary fix)
    sudo chmod 666 /var/run/docker.sock
    
    log_success "Docker permissions configured"
    log_warning "You may need to log out and log back in for group changes to take effect"
}

# Install Docker Compose (standalone)
install_docker_compose() {
    log "Installing Docker Compose..."
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    
    if [[ -z "$COMPOSE_VERSION" ]]; then
        log_warning "Could not fetch latest Docker Compose version, using v2.39.3"
        COMPOSE_VERSION="v2.39.3"
    fi
    
    log "Installing Docker Compose $COMPOSE_VERSION..."
    
    # Download and install Docker Compose
    sudo curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for docker-compose command
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose installed: $COMPOSE_VERSION"
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    # Check Docker version
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_success "Docker installed: $DOCKER_VERSION"
    else
        log_error "Docker installation failed"
        exit 1
    fi
    
    # Check Docker Compose version
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        log_success "Docker Compose installed: $COMPOSE_VERSION"
    else
        log_error "Docker Compose installation failed"
        exit 1
    fi
    
    # Test Docker with hello-world
    log "Testing Docker with hello-world container..."
    if sudo docker run --rm hello-world > /dev/null 2>&1; then
        log_success "Docker test successful"
    else
        log_error "Docker test failed"
        exit 1
    fi
}

# Display post-installation information
display_post_install_info() {
    echo
    log_success "Docker and Docker Compose installation completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Log out and log back in to apply group changes"
    echo "2. Test Docker without sudo: docker run hello-world"
    echo "3. Test Docker Compose: docker-compose --version"
    echo
    echo "Useful commands:"
    echo "  - Check Docker status: sudo systemctl status docker"
    echo "  - View Docker logs: sudo journalctl -u docker"
    echo "  - Start Docker: sudo systemctl start docker"
    echo "  - Stop Docker: sudo systemctl stop docker"
    echo
    echo "For your WordPress project:"
    echo "  - Navigate to your project directory"
    echo "  - Run: docker-compose up -d"
    echo
}

# Main installation function
main() {
    echo "=========================================="
    echo "Docker Installation Script for Ubuntu"
    echo "=========================================="
    echo
    
    # Pre-installation checks
    check_root
    check_sudo
    detect_ubuntu_version
    check_docker_installed
    
    # Installation steps
    remove_old_docker
    update_packages
    install_prerequisites
    add_docker_gpg_key
    add_docker_repository
    install_docker_engine
    start_docker_service
    configure_docker_permissions
    install_docker_compose
    verify_installation
    display_post_install_info
}

# Run main function
main "$@"
