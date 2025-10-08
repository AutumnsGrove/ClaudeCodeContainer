#!/bin/bash
set -e

# Claude Code Container Setup Script
# A secure, containerized development environment for Claude Code

CONTAINER_NAME="claude-code-env"
WORKSPACE_DIR="$HOME/ClaudeCodeWorkspace"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script requires macOS with Apple's container framework"
        exit 1
    fi
    
    # Check for Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        log_warn "Xcode Command Line Tools not found. Installing..."
        xcode-select --install
    fi
    
    log_info "System requirements met!"
}

# Create workspace structure
setup_workspace() {
    log_info "Setting up workspace directory structure..."
    
    mkdir -p "$WORKSPACE_DIR"/{Projects,Documentation,Research,shared,exports,imports}
    mkdir -p "$WORKSPACE_DIR"/.config/claude-code
    
    # Copy presets if they exist
    if [ -d "$SCRIPT_DIR/presets" ]; then
        cp -r "$SCRIPT_DIR/presets" "$WORKSPACE_DIR/Documentation/"
        log_info "Copied preset prompts to Documentation/presets/"
    fi
    
    log_info "Workspace created at $WORKSPACE_DIR"
}

# Build container with Apple's framework
build_container() {
    log_info "Building container with Apple's virtualization framework..."
    
    # This will need to be implemented using Swift and Apple's Virtualization framework
    # Claude Code can help research and implement this part
    swift "$SCRIPT_DIR/container-config/init-container.swift" \
        --name "$CONTAINER_NAME" \
        --base-image "ubuntu:22.04" \
        --memory "8192" \
        --storage "50" \
        --shared-directory "$WORKSPACE_DIR:/workspace"
}

# Install base packages in container
install_base_packages() {
    log_info "Installing base packages..."
    
    cat << 'EOF' > "$SCRIPT_DIR/scripts/install-base.sh"
#!/bin/bash
apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    build-essential \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release

# Install Python 3.11
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update && apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/claude/.bashrc

# Install UV (fast Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Node.js and npm for Claude Code
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Claude Code
npm install -g @anthropic/claude-code
EOF
    
    # Execute in container
    run_in_container "$SCRIPT_DIR/scripts/install-base.sh"
}

# Install MCP servers
install_mcp_servers() {
    log_info "Installing MCP servers..."
    
    cat << 'EOF' > "$SCRIPT_DIR/scripts/install-mcp.sh"
#!/bin/bash

# Create MCP directory
mkdir -p /home/claude/.config/claude-code/mcp-servers

# Install Sequential Thinking MCP server
cd /home/claude/.config/claude-code/mcp-servers
git clone https://github.com/modelcontextprotocol/servers.git mcp-servers-repo
cd mcp-servers-repo/src/sequentialthinking
npm install
npm run build

# Install Zen MCP server
cd /home/claude/.config/claude-code/mcp-servers
git clone https://github.com/BeehiveInnovations/zen-mcp-server.git
cd zen-mcp-server
npm install
npm run build

# Configure MCP servers in Claude Code config
cat << 'CONFIG' > /home/claude/.config/claude-code/mcp-config.json
{
  "servers": {
    "sequential-thinking": {
      "command": "node",
      "args": ["/home/claude/.config/claude-code/mcp-servers/mcp-servers-repo/src/sequentialthinking/dist/index.js"],
      "enabled": true
    },
    "zen": {
      "command": "node",
      "args": ["/home/claude/.config/claude-code/mcp-servers/zen-mcp-server/dist/index.js"],
      "enabled": true
    }
  }
}
CONFIG
EOF
    
    run_in_container "$SCRIPT_DIR/scripts/install-mcp.sh"
}

# Configure environment
configure_environment() {
    log_info "Configuring environment..."
    
    cat << 'EOF' > "$SCRIPT_DIR/scripts/configure-env.sh"
#!/bin/bash

# Set up directory structure
mkdir -p /workspace/{Projects,Documentation,Research}

# Configure git
git config --global init.defaultBranch main
git config --global core.editor "nano"

# Set up aliases
cat << 'ALIASES' >> /home/claude/.bashrc

# Claude Code aliases
alias cc='claude-code'
alias ccp='claude-code --project'
alias ccr='claude-code --research'

# Navigation aliases
alias proj='cd /workspace/Projects'
alias docs='cd /workspace/Documentation'
alias research='cd /workspace/Research'

# Python aliases
alias py='python3.11'
alias venv='python3.11 -m venv'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

ALIASES

# Create welcome message
cat << 'WELCOME' > /etc/motd

=========================================
  Claude Code Secure Container Environment
=========================================
  
  Workspace: /workspace
  ├── Projects/      - Your coding projects
  ├── Documentation/ - Docs and presets
  ├── Research/      - Research materials
  ├── shared/        - Shared with host
  ├── exports/       - Export files here
  └── imports/       - Import files here
  
  Commands:
  - cc              : Launch Claude Code
  - proj/docs/research : Navigate to folders
  - py              : Python 3.11
  
  MCP Servers Available:
  - Sequential Thinking
  - Zen
  
=========================================

WELCOME
EOF
    
    run_in_container "$SCRIPT_DIR/scripts/configure-env.sh"
}

# Helper function to run commands in container
run_in_container() {
    # Implementation depends on Apple's container framework
    # This is a placeholder that Claude Code can help implement
    container run "$CONTAINER_NAME" bash -c "$1"
}

# Create shell alias for easy access
create_alias() {
    log_info "Creating shell alias..."
    
    SHELL_RC="$HOME/.zshrc"
    if [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    cat << EOF >> "$SHELL_RC"

# Claude Code Container alias
alias claude-container='$SCRIPT_DIR/launch.sh'
alias cc-container='$SCRIPT_DIR/launch.sh'
EOF
    
    # Create launch script
    cat << 'EOF' > "$SCRIPT_DIR/launch.sh"
#!/bin/bash
CONTAINER_NAME="claude-code-env"

echo "Starting Claude Code Container..."
# Implementation for starting/attaching to container
container start "$CONTAINER_NAME"
container attach "$CONTAINER_NAME"
EOF
    
    chmod +x "$SCRIPT_DIR/launch.sh"
    log_info "Alias 'claude-container' and 'cc-container' created!"
}

# Main installation flow
main() {
    log_info "Starting Claude Code Container Setup..."
    
    check_requirements
    setup_workspace
    build_container
    install_base_packages
    install_mcp_servers
    configure_environment
    create_alias
    
    log_info "Setup complete! 🎉"
    log_info "Use 'claude-container' or 'cc-container' to start the environment"
    log_info "Workspace is at: $WORKSPACE_DIR"
    log_info "Please restart your terminal or run 'source ~/.zshrc' to use the alias"
}

# Run main function
main "$@"
