#!/bin/bash

# Simple wrapper script to test Docker installation
# This script should be run from the project root directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/scripts/test-docker.sh"

# Check if the test script exists
if [[ ! -f "$TEST_SCRIPT" ]]; then
    echo "Error: Docker test script not found at $TEST_SCRIPT"
    exit 1
fi

# Make sure the script is executable
chmod +x "$TEST_SCRIPT"

# Run the test script
echo "Testing Docker installation..."
exec "$TEST_SCRIPT"
