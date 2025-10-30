#!/bin/bash
# Script to start the Claude Code container environment

set -e

echo "Starting Claude Code Container..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed. Please install docker-compose."
    exit 1
fi

# Navigate to the script directory's parent
cd "$(dirname "$0")/.."

# Create workspace directories if they don't exist
echo "Ensuring workspace directories exist..."
mkdir -p workspace/{Projects,Documentation,Research,shared,exports,imports}

# Build the container if needed
echo "Building container (if needed)..."
docker-compose build

# Start the container
echo "Starting container..."
docker-compose up -d

# Wait for container to be healthy
echo "Waiting for container to be ready..."
sleep 3

# Check container status
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "✓ Claude Code Container is running!"
    echo ""
    echo "Access the container with:"
    echo "  docker exec -it claude-code-container /bin/bash"
    echo ""
    echo "Or use the helper script:"
    echo "  ./scripts/enter-container.sh"
    echo ""
    echo "Stop the container with:"
    echo "  docker-compose down"
else
    echo "✗ Container failed to start. Check logs with: docker-compose logs"
    exit 1
fi
