# Makefile for Claude Code Container Management
# Simple commands to manage the Docker container environment

.PHONY: help build start stop restart enter logs status clean rebuild backup

# Default target - show help
help:
	@echo "Claude Code Container - Available Commands:"
	@echo ""
	@echo "  make build       - Build the Docker image"
	@echo "  make start       - Start the container"
	@echo "  make stop        - Stop the container"
	@echo "  make restart     - Restart the container"
	@echo "  make enter       - Enter the container shell"
	@echo "  make logs        - Show container logs"
	@echo "  make status      - Show container status"
	@echo "  make clean       - Stop and remove container"
	@echo "  make rebuild     - Rebuild container from scratch"
	@echo "  make backup      - Backup workspace and home volume"
	@echo ""

# Build the Docker image
build:
	@echo "Building Claude Code container image..."
	docker-compose build

# Start the container
start:
	@echo "Starting Claude Code container..."
	@mkdir -p workspace/{Projects,Documentation,Research,shared,exports,imports}
	docker-compose up -d
	@echo "✓ Container started successfully"
	@echo "Enter with: make enter"

# Stop the container
stop:
	@echo "Stopping Claude Code container..."
	docker-compose down
	@echo "✓ Container stopped"

# Restart the container
restart: stop start

# Enter the container
enter:
	@docker exec -it claude-code-container /bin/bash || \
		(echo "Error: Container not running. Start it with: make start" && exit 1)

# Show container logs
logs:
	docker-compose logs -f

# Show container status
status:
	@echo "Container Status:"
	@docker-compose ps
	@echo ""
	@echo "Resource Usage:"
	@docker stats claude-code-container --no-stream 2>/dev/null || echo "Container not running"

# Clean up (stop and remove container, but keep volumes)
clean:
	@echo "Stopping and removing container..."
	docker-compose down
	@echo "✓ Container removed (volumes preserved)"

# Rebuild from scratch
rebuild:
	@echo "Rebuilding container from scratch..."
	docker-compose down
	docker-compose build --no-cache
	docker-compose up -d
	@echo "✓ Container rebuilt and started"

# Backup workspace and home volume
backup:
	@echo "Creating backups..."
	@tar -czf workspace-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz workspace/ 2>/dev/null || true
	@docker run --rm -v claude-code-home:/data -v $(PWD):/backup ubuntu tar -czf /backup/home-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data . 2>/dev/null || echo "Could not backup home volume"
	@echo "✓ Backups created"
	@ls -lh *backup*.tar.gz 2>/dev/null || true
