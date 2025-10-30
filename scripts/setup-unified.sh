#!/bin/bash
set -e

# Claude Code Container - Unified Setup Script
# Supports both Apple's container framework and Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="claude-code-env"
WORKSPACE_DIR="$HOME/ClaudeCodeWorkspace"
USE_DOCKER=false
USE_APPLE_CONTAINER=false

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Banner
show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════╗
║   Claude Code Secure Container Environment   ║
║         Fast & Secure Development Setup       ║
╚═══════════════════════════════════════════════╝
EOF
}

# Detect container runtime
detect_runtime() {
    log_step "Detecting container runtime..."
    
    # Check for Apple's container framework first
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if swift --version &>/dev/null && \
           [ -f "/System/Library/Frameworks/Virtualization.framework/Versions/A/Virtualization" ]; then
            USE_APPLE_CONTAINER=true
            log_info "Apple Virtualization framework detected"
        elif docker --version &>/dev/null; then
            USE_DOCKER=true
            log_info "Docker detected (Apple framework not available)"
        else
            log_error "No container runtime found!"
            log_info "Please install either:"
            log_info "  - Docker Desktop: https://www.docker.com/products/docker-desktop/"
            log_info "  - Or ensure Xcode and Virtualization.framework are available"
            exit 1
        fi
    else
        # Non-macOS systems use Docker
        if docker --version &>/dev/null; then
            USE_DOCKER=true
            log_info "Docker detected"
        else
            log_error "Docker not found! Please install Docker first."
            exit 1
        fi
    fi
}

# Setup workspace
setup_workspace() {
    log_step "Setting up workspace at $WORKSPACE_DIR..."
    
    # Create directory structure
    mkdir -p "$WORKSPACE_DIR"/{Projects,Documentation,Research}
    mkdir -p "$WORKSPACE_DIR"/{shared,exports,imports}
    mkdir -p "$WORKSPACE_DIR"/.config
    
    # Copy presets if available
    if [ -d "$SCRIPT_DIR/presets" ]; then
        cp -r "$SCRIPT_DIR/presets" "$WORKSPACE_DIR/Documentation/"
        log_info "Copied preset prompts"
    fi
    
    # Create a sample preset if none exist
    if [ ! -d "$WORKSPACE_DIR/Documentation/presets" ]; then
        mkdir -p "$WORKSPACE_DIR/Documentation/presets"
        cat << 'EOF' > "$WORKSPACE_DIR/Documentation/presets/example-prompt.md"
# Example Claude Code Prompt

This is an example preset prompt for Claude Code.

## Instructions
1. Be thorough in your analysis
2. Consider edge cases
3. Write clean, documented code
4. Test your solutions

## Context
You are working in a secure container environment with:
- Python 3.11
- Git
- MCP servers for enhanced capabilities
EOF
        log_info "Created example preset"
    fi
    
    log_info "Workspace ready"
}

# Build with Docker
build_docker() {
    log_step "Building Docker container..."
    
    cd "$SCRIPT_DIR"
    
    # Check if docker-compose exists, otherwise use docker
    if docker-compose --version &>/dev/null; then
        log_info "Using docker-compose..."
        docker-compose build
    else
        log_info "Using docker build..."
        docker build -t claude-code-container:latest .
    fi
    
    log_info "Docker container built successfully"
}

# Build with Apple Container
build_apple_container() {
    log_step "Building with Apple Virtualization framework..."
    
    if [ -f "$SCRIPT_DIR/container-config/init-container.swift" ]; then
        swift "$SCRIPT_DIR/container-config/init-container.swift" \
            --name "$CONTAINER_NAME" \
            --base-image "ubuntu:22.04" \
            --memory "8192" \
            --storage "50" \
            --shared-directory "$WORKSPACE_DIR:/workspace"
    else
        log_warn "Apple container config not found, falling back to Docker"
        USE_APPLE_CONTAINER=false
        USE_DOCKER=true
        build_docker
    fi
}

# Create launch script
create_launch_script() {
    log_step "Creating launch scripts..."
    
    # Docker launch script
    if [ "$USE_DOCKER" = true ]; then
        cat << 'EOF' > "$SCRIPT_DIR/launch-docker.sh"
#!/bin/bash
CONTAINER_NAME="claude-code-env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # Check if running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Attaching to running container..."
        docker exec -it $CONTAINER_NAME /bin/bash
    else
        echo "Starting stopped container..."
        docker start $CONTAINER_NAME
        docker exec -it $CONTAINER_NAME /bin/bash
    fi
else
    echo "Creating new container..."
    # Use docker-compose if available
    if docker-compose --version &>/dev/null && [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        cd "$SCRIPT_DIR"
        docker-compose up -d
        docker-compose exec claude-code /bin/bash
    else
        docker run -it \
            --name $CONTAINER_NAME \
            --hostname claude-container \
            -v "$HOME/ClaudeCodeWorkspace/shared:/workspace/shared" \
            -v "$HOME/ClaudeCodeWorkspace/exports:/workspace/exports" \
            -v "$HOME/ClaudeCodeWorkspace/imports:/workspace/imports" \
            -v "$HOME/ClaudeCodeWorkspace/Projects:/workspace/Projects" \
            -v "$HOME/ClaudeCodeWorkspace/Documentation:/workspace/Documentation" \
            claude-code-container:latest \
            /bin/bash
    fi
fi
EOF
        chmod +x "$SCRIPT_DIR/launch-docker.sh"
    fi
    
    # Apple container launch script
    if [ "$USE_APPLE_CONTAINER" = true ]; then
        cat << 'EOF' > "$SCRIPT_DIR/launch-apple.sh"
#!/bin/bash
CONTAINER_NAME="claude-code-env"
# TODO: Implement Apple container launch
echo "Starting Apple container..."
# This will be implemented based on the specific Apple container framework API
EOF
        chmod +x "$SCRIPT_DIR/launch-apple.sh"
    fi
    
    # Universal launch script
    cat << EOF > "$SCRIPT_DIR/launch.sh"
#!/bin/bash
# Universal launcher - detects which runtime to use

if [ -f "$SCRIPT_DIR/launch-apple.sh" ] && [ "$USE_APPLE_CONTAINER" = true ]; then
    exec "$SCRIPT_DIR/launch-apple.sh"
elif [ -f "$SCRIPT_DIR/launch-docker.sh" ]; then
    exec "$SCRIPT_DIR/launch-docker.sh"
else
    echo "No launch script found!"
    exit 1
fi
EOF
    chmod +x "$SCRIPT_DIR/launch.sh"
    
    log_info "Launch scripts created"
}

# Create shell aliases
create_aliases() {
    log_step "Creating shell aliases..."
    
    # Detect shell
    SHELL_RC="$HOME/.zshrc"
    if [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    # Check if aliases already exist
    if grep -q "claude-container" "$SHELL_RC" 2>/dev/null; then
        log_info "Aliases already exist"
    else
        cat << EOF >> "$SHELL_RC"

# Claude Code Container aliases
alias claude-container='$SCRIPT_DIR/launch.sh'
alias cc-container='$SCRIPT_DIR/launch.sh'
alias cc-workspace='cd $WORKSPACE_DIR'
EOF
        log_info "Added aliases to $SHELL_RC"
    fi
}

# Main setup flow
main() {
    show_banner
    echo
    
    # Parse arguments
    if [ "$1" = "--reset" ]; then
        log_warn "Resetting container..."
        if [ "$USE_DOCKER" = true ]; then
            docker stop $CONTAINER_NAME 2>/dev/null || true
            docker rm $CONTAINER_NAME 2>/dev/null || true
            docker rmi claude-code-container:latest 2>/dev/null || true
        fi
        rm -rf "$WORKSPACE_DIR"
        log_info "Reset complete"
    fi
    
    # Setup steps
    detect_runtime
    setup_workspace
    
    # Build container based on runtime
    if [ "$USE_APPLE_CONTAINER" = true ]; then
        build_apple_container
    elif [ "$USE_DOCKER" = true ]; then
        build_docker
    fi
    
    create_launch_script
    create_aliases
    
    # Success message
    echo
    log_info "🎉 Setup complete!"
    echo
    echo "  Quick Start:"
    echo "  ────────────"
    echo "  1. Restart terminal or run: source $SHELL_RC"
    echo "  2. Start container: claude-container"
    echo "  3. Or go directly to workspace: cc-workspace"
    echo
    echo "  Your workspace: $WORKSPACE_DIR"
    echo
    if [ "$USE_DOCKER" = true ]; then
        echo "  Using: Docker"
    else
        echo "  Using: Apple Virtualization Framework"
    fi
    echo
}

# Run main
main "$@"
