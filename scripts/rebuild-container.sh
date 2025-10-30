#!/bin/bash
# Script to rebuild the Claude Code container from scratch

set -e

echo "Rebuilding Claude Code Container..."

# Navigate to the script directory's parent
cd "$(dirname "$0")/.."

# Stop and remove existing container
echo "Stopping existing container..."
docker-compose down

# Rebuild without cache
echo "Building fresh container image..."
docker-compose build --no-cache

# Start the new container
echo "Starting rebuilt container..."
docker-compose up -d

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 3

# Check status
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "✓ Container rebuilt and started successfully!"
    echo ""
    echo "Access with: ./scripts/enter-container.sh"
else
    echo "✗ Container failed to start. Check logs with: docker-compose logs"
    exit 1
fi
