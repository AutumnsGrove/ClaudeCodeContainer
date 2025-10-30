#!/bin/bash

# Claude Container Manager
# Utility script for managing the Claude Code container

CONTAINER_NAME="claude-code-env"
WORKSPACE_DIR="$HOME/ClaudeCodeWorkspace"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_warn() { echo -e "${YELLOW}!${NC} $1"; }

# Show usage
show_usage() {
    cat << EOF
Claude Container Manager

Usage: $(basename $0) [command] [options]

Commands:
  start           Start the container
  stop            Stop the container
  restart         Restart the container
  attach          Attach to running container
  status          Show container status
  logs            Show container logs
  exec <cmd>      Execute command in container
  backup          Backup workspace to archive
  reset           Reset container (preserves workspace)
  clean           Remove container and images (preserves workspace)
  destroy         Remove everything including workspace (CAUTION!)
  
File Operations:
  import <file>   Copy file to imports folder
  export          List files in exports folder
  share <file>    Copy file to shared folder
  
Examples:
  $(basename $0) start
  $(basename $0) exec "python3.11 script.py"
  $(basename $0) import myfile.txt
  $(basename $0) backup

EOF
}

# Check Docker
check_docker() {
    if ! docker --version &>/dev/null; then
        log_error "Docker is not installed or not running"
        exit 1
    fi
}

# Container status
container_status() {
    check_docker
    
    echo "Container Status:"
    echo "────────────────"
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Container is running"
        echo
        docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Status}}\t{{.Ports}}"
    elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warn "Container exists but is stopped"
        echo
        docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Status}}"
    else
        log_error "Container does not exist"
    fi
    
    echo
    echo "Workspace Status:"
    echo "────────────────"
    if [ -d "$WORKSPACE_DIR" ]; then
        log_info "Workspace exists at: $WORKSPACE_DIR"
        echo
        echo "Directory sizes:"
        du -sh "$WORKSPACE_DIR"/* 2>/dev/null | sed 's/^/  /'
    else
        log_warn "Workspace not found"
    fi
}

# Start container
start_container() {
    check_docker
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Container is already running"
    elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Starting stopped container..."
        docker start $CONTAINER_NAME
    else
        log_info "Creating and starting new container..."
        if [ -f "docker-compose.yml" ]; then
            docker-compose up -d
        else
            log_error "Container does not exist. Run setup.sh first."
            exit 1
        fi
    fi
}

# Stop container
stop_container() {
    check_docker
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Stopping container..."
        docker stop $CONTAINER_NAME
    else
        log_warn "Container is not running"
    fi
}

# Attach to container
attach_container() {
    check_docker
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Attaching to container (exit with Ctrl+D or 'exit')..."
        docker exec -it $CONTAINER_NAME /bin/bash
    else
        log_error "Container is not running. Start it first with: $0 start"
        exit 1
    fi
}

# Execute command
exec_command() {
    check_docker
    
    if [ -z "$1" ]; then
        log_error "No command specified"
        exit 1
    fi
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Executing: $1"
        docker exec -it $CONTAINER_NAME bash -c "$1"
    else
        log_error "Container is not running"
        exit 1
    fi
}

# Show logs
show_logs() {
    check_docker
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker logs $CONTAINER_NAME --tail 50 -f
    else
        log_error "Container does not exist"
        exit 1
    fi
}

# Backup workspace
backup_workspace() {
    if [ ! -d "$WORKSPACE_DIR" ]; then
        log_error "Workspace not found"
        exit 1
    fi
    
    BACKUP_NAME="claude-workspace-$(date +%Y%m%d-%H%M%S).tar.gz"
    BACKUP_PATH="$HOME/$BACKUP_NAME"
    
    log_info "Creating backup..."
    tar -czf "$BACKUP_PATH" -C "$HOME" "ClaudeCodeWorkspace" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_info "Backup created: $BACKUP_PATH"
        log_info "Size: $(du -h "$BACKUP_PATH" | cut -f1)"
    else
        log_error "Backup failed"
        exit 1
    fi
}

# Import file
import_file() {
    if [ -z "$1" ]; then
        log_error "No file specified"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        log_error "File not found: $1"
        exit 1
    fi
    
    mkdir -p "$WORKSPACE_DIR/imports"
    cp "$1" "$WORKSPACE_DIR/imports/"
    log_info "Imported: $(basename "$1") -> $WORKSPACE_DIR/imports/"
}

# List exports
list_exports() {
    if [ ! -d "$WORKSPACE_DIR/exports" ]; then
        log_warn "Exports folder not found"
        exit 1
    fi
    
    echo "Files in exports folder:"
    echo "───────────────────────"
    if [ -z "$(ls -A "$WORKSPACE_DIR/exports" 2>/dev/null)" ]; then
        echo "  (empty)"
    else
        ls -la "$WORKSPACE_DIR/exports"
    fi
}

# Share file
share_file() {
    if [ -z "$1" ]; then
        log_error "No file specified"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        log_error "File not found: $1"
        exit 1
    fi
    
    mkdir -p "$WORKSPACE_DIR/shared"
    cp "$1" "$WORKSPACE_DIR/shared/"
    log_info "Shared: $(basename "$1") -> $WORKSPACE_DIR/shared/"
}

# Reset container
reset_container() {
    check_docker
    
    read -p "Reset container? This will remove the container but preserve your workspace. Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Resetting container..."
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        log_info "Container reset. Workspace preserved at: $WORKSPACE_DIR"
    else
        log_info "Reset cancelled"
    fi
}

# Clean everything except workspace
clean_container() {
    check_docker
    
    read -p "Remove container and images? Workspace will be preserved. Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning container and images..."
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        docker rmi claude-code-container:latest 2>/dev/null || true
        docker volume prune -f 2>/dev/null || true
        log_info "Cleanup complete. Workspace preserved at: $WORKSPACE_DIR"
    else
        log_info "Cleanup cancelled"
    fi
}

# Destroy everything
destroy_all() {
    log_warn "WARNING: This will remove EVERYTHING including your workspace!"
    read -p "Are you absolutely sure? Type 'DESTROY' to confirm: " CONFIRM
    
    if [ "$CONFIRM" = "DESTROY" ]; then
        log_info "Destroying everything..."
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        docker rmi claude-code-container:latest 2>/dev/null || true
        docker volume prune -f 2>/dev/null || true
        rm -rf "$WORKSPACE_DIR"
        log_info "Everything has been removed"
    else
        log_info "Destroy cancelled"
    fi
}

# Main
case "$1" in
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    restart)
        stop_container
        sleep 2
        start_container
        ;;
    attach)
        attach_container
        ;;
    status)
        container_status
        ;;
    logs)
        show_logs
        ;;
    exec)
        exec_command "$2"
        ;;
    backup)
        backup_workspace
        ;;
    import)
        import_file "$2"
        ;;
    export)
        list_exports
        ;;
    share)
        share_file "$2"
        ;;
    reset)
        reset_container
        ;;
    clean)
        clean_container
        ;;
    destroy)
        destroy_all
        ;;
    *)
        show_usage
        ;;
esac
