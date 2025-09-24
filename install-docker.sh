#!/bin/bash

# Simple wrapper script to run Docker installation
# This script should be run from the project root directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/scripts/install-docker.sh"

# Check if the installation script exists
if [[ ! -f "$INSTALL_SCRIPT" ]]; then
    echo "Error: Docker installation script not found at $INSTALL_SCRIPT"
    exit 1
fi

# Make sure the script is executable
chmod +x "$INSTALL_SCRIPT"

# Run the installation script
echo "Starting Docker installation..."
echo "This will install Docker Engine and Docker Compose on your Ubuntu system."
echo
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    exec "$INSTALL_SCRIPT"
else
    echo "Installation cancelled."
    exit 0
fi
