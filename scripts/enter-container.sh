#!/bin/bash
# Script to enter the Claude Code container

set -e

# Check if container is running
if ! docker ps | grep -q claude-code-container; then
    echo "Error: Claude Code Container is not running."
    echo "Start it with: ./scripts/start-container.sh"
    exit 1
fi

# Enter the container
echo "Entering Claude Code Container..."
docker exec -it claude-code-container /bin/bash
