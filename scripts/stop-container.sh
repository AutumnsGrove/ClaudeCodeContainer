#!/bin/bash
# Script to stop the Claude Code container

set -e

echo "Stopping Claude Code Container..."

# Navigate to the script directory's parent
cd "$(dirname "$0")/.."

# Stop the container
docker-compose down

echo "✓ Claude Code Container stopped successfully."
echo ""
echo "Note: Your workspace data is preserved in ./workspace/"
echo "To remove all data including volumes, run: docker-compose down -v"
