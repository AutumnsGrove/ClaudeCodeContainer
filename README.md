# Claude Code Container

A secure, containerized development environment for Claude Code with dual implementation options.

> **Implementation Options:**
> - **Docker** (Production-Ready): Cross-platform Docker container with Ubuntu 24.04 LTS
> - **Apple Framework** (In Development): Native macOS virtualization using Apple's container framework

## 🎯 Project Status

This project is in **early development**. Initial scaffolding and architecture planning completed in a single session with Claude 4.1 Opus.

**Current Phase:** Research

**Next Steps:**
1. 🔬 **Research Phase** - Use `research/RESEARCH_PROMPT.md` to conduct comprehensive Apple container framework research
2. 💻 **Implementation Phase** - Use research documentation to implement container solution
3. 🧪 **Testing Phase** - Validate and refine implementation

## 📋 Features (Planned)

- **Native macOS Virtualization**: Built on Apple's container framework
- **Secure File Access**: Isolated container environment with controlled workspace access
- **Pre-configured Development Tools**:
  - Git
  - Python 3.11
  - Claude Code with MCP servers
  - Homebrew
  - UV (fast Python package manager)
- **Organized Workspace**: Pre-structured directories for Projects, Documentation, and Research
- **Persistent Storage**: Workspace persists across container sessions

## 💾 System Footprint

Understanding the resource requirements helps you plan your container deployment effectively.

### Resource Requirements

**Docker Image Size:**
- Base Ubuntu 24.04 LTS: ~77 MB
- With all tools installed: ~800 MB - 1.2 GB
- After build optimization: ~950 MB (estimated)

**Container Runtime Memory:**
- Idle state: 50-100 MB
- Active development: 200-500 MB
- Running tests/builds: 500 MB - 1 GB

**Disk Space:**
- Docker base image: ~1 GB
- Workspace data: Depends on your projects (plan for 2-5 GB minimum)
- Docker system overhead: ~500 MB
- **Total recommended**: 5-10 GB free space

**CPU Usage:**
- Idle: <1% CPU
- Active coding: 2-10% CPU
- Build/test operations: 20-50% CPU (burst)

**Network Bandwidth:**
- Initial image pull: ~1 GB download
- Package updates: 50-200 MB (occasional)
- Normal operation: Minimal (<10 MB/day)

### Checking Resource Usage

**Before Setup:**
```bash
# Check available disk space
df -h

# Check Docker disk usage
docker system df
```

**During Container Operation:**
```bash
# Real-time resource monitoring
docker stats claude-code-container

# Detailed container info
docker inspect claude-code-container --format '{{.State.Status}}'

# Check image sizes
docker images | grep claude-code
```

**Sample docker stats output:**
```
CONTAINER ID   NAME                    CPU %   MEM USAGE / LIMIT   MEM %   NET I/O     BLOCK I/O
abc123def456   claude-code-container   2.5%    256MiB / 7.7GiB    3.25%   1.2kB/0B    12MB/8MB
```

### Resource Comparison

**Containerized vs Native:**
| Aspect | Container | Native |
|--------|-----------|--------|
| Memory overhead | +50-100 MB | Baseline |
| Disk space | +1-2 GB | Baseline |
| CPU overhead | +1-2% | Baseline |
| Isolation | Full | None |
| Portability | High | Low |
| Security | Enhanced | Standard |

**The overhead is minimal compared to the benefits of isolation and portability.**

### Cleaning Up Resources

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove all unused Docker resources (CAUTION: removes all unused data)
docker system prune -a --volumes

# Check space reclaimed
docker system df
```

## 📁 Project Structure

```
ClaudeCodeContainer/
├── src/                    # Source code (Swift)
│   └── init-container.swift
├── scripts/                # Setup and management scripts
│   ├── setup.sh
│   ├── setup-unified.sh
│   └── manage.sh
├── docs/                   # Documentation
│   ├── README.md
│   ├── GETTING_STARTED.md
│   ├── SECURITY.md
│   └── GIT_COMMIT_STYLE.md
├── research/               # Research documentation
│   ├── RESEARCH_PROMPT.md  # Metaprompt for research phase
│   └── README.md           # Research guide
├── CLAUDE_NEXT_STEPS.md    # Implementation roadmap
└── README.md               # This file
```

## 🚀 Quick Start

### Docker (Production-Ready)

**Prerequisites:**
- Docker Desktop installed and running
- 10GB free disk space

**Setup:**
```bash
# Clone the repository
git clone <your-repo-url>
cd ClaudeCodeContainer

# Quick start (using Makefile)
make build      # Build the container
make start      # Start the container
make enter      # Enter the container shell

# Or use helper scripts
./scripts/start-container.sh
./scripts/enter-container.sh
```

See [QUICK_START.md](QUICK_START.md) for detailed Docker setup instructions.

### Apple Framework (In Development)

**Prerequisites:**
- macOS 13.0 or later
- Xcode Command Line Tools
- Apple's container framework

**Setup:**
```bash
# Run setup (when implementation is complete)
./scripts/setup.sh
```

## ⚡ Shell Aliases (Time Savers)

Speed up your workflow with these convenient shell aliases. Add them to your shell configuration file for one-command container operations.

### Quick Setup

**For Bash users** (add to `~/.bashrc` or `~/.bash_profile`):
```bash
# Open your bash config
nano ~/.bashrc

# Or for macOS
nano ~/.bash_profile

# Add the aliases below, save, then reload
source ~/.bashrc
```

**For Zsh users** (add to `~/.zshrc`):
```bash
# Open your zsh config
nano ~/.zshrc

# Add the aliases below, save, then reload
source ~/.zshrc
```

### Copy-Paste Ready Aliases

```bash
# === Claude Code Container Aliases ===

# Core container operations
alias ccode-build='docker compose -f /Users/autumn/Documents/Projects/ClaudeCodeContainer/docker-compose.yml build'
alias ccode-start='docker compose -f /Users/autumn/Documents/Projects/ClaudeCodeContainer/docker-compose.yml up -d'
alias ccode-stop='docker compose -f /Users/autumn/Documents/Projects/ClaudeCodeContainer/docker-compose.yml down'
alias ccode-restart='ccode-stop && ccode-start'
alias ccode-shell='docker exec -it claude-code-container /bin/bash'

# Status and monitoring
alias ccode-status='docker ps -a | grep claude-code'
alias ccode-stats='docker stats claude-code-container --no-stream'
alias ccode-logs='docker logs claude-code-container'
alias ccode-logs-follow='docker logs -f claude-code-container'

# Workspace access
alias ccode-ws='cd /Users/autumn/Documents/Projects/ClaudeCodeContainer/workspace'
alias ccode-projects='ccode-shell -c "cd /workspace/Projects && /bin/bash"'

# Maintenance
alias ccode-clean='docker system prune -f'
alias ccode-clean-all='docker system prune -a -f --volumes'
alias ccode-rebuild='ccode-stop && ccode-build && ccode-start'
alias ccode-update='cd /Users/autumn/Documents/Projects/ClaudeCodeContainer && git pull && ccode-rebuild'

# Quick info
alias ccode-info='docker inspect claude-code-container --format "Status: {{.State.Status}} | Running: {{.State.Running}} | Started: {{.State.StartedAt}}"'
alias ccode-ip='docker inspect -f "{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" claude-code-container'
alias ccode-size='docker images | grep claude-code && docker ps -s | grep claude-code'
```

### Usage Examples

Once aliases are configured, your workflow becomes much simpler:

```bash
# Start your day
ccode-start                 # Start the container
ccode-status                # Verify it's running
ccode-shell                 # Enter the container

# Check resource usage
ccode-stats                 # See CPU, memory, disk usage
ccode-size                  # Check image and container sizes

# Monitor activity
ccode-logs-follow           # Watch container logs in real-time
# Press Ctrl+C to exit log viewing

# End your day
ccode-stop                  # Stop the container (preserves data)

# Weekly maintenance
ccode-clean                 # Remove unused Docker resources
ccode-update                # Update to latest version
```

### Bonus: Advanced Aliases

For power users, add these advanced shortcuts:

```bash
# Development helpers
alias ccode-exec='docker exec -it claude-code-container'
alias ccode-root='docker exec -it -u root claude-code-container /bin/bash'
alias ccode-backup='tar -czf ~/ccode-backup-$(date +%Y%m%d).tar.gz /Users/autumn/Documents/Projects/ClaudeCodeContainer/workspace'
alias ccode-restore='tar -xzf ~/ccode-backup-*.tar.gz -C /'

# Quick testing
alias ccode-test='ccode-exec uv run pytest'
alias ccode-lint='ccode-exec black --check .'

# Resource monitoring
alias ccode-disk='docker exec claude-code-container df -h'
alias ccode-mem='docker exec claude-code-container free -h'
alias ccode-top='docker exec claude-code-container top -bn1'
```

### Customization Tips

**Path Adjustment:**
If your container is in a different location, update the path in the aliases:
```bash
# Replace this path in all aliases above
/Users/autumn/Documents/Projects/ClaudeCodeContainer

# With your actual path
/your/actual/path/ClaudeCodeContainer
```

**Container Name:**
If you use a different container name, update `claude-code-container` throughout.

**Multiple Containers:**
For multiple Claude Code containers, create numbered aliases:
```bash
alias ccode1-start='docker compose -f /path/to/container1/docker-compose.yml up -d'
alias ccode2-start='docker compose -f /path/to/container2/docker-compose.yml up -d'
```

### Verification

Test your aliases after adding them:
```bash
# Reload your shell config
source ~/.bashrc  # or source ~/.zshrc

# Test an alias
ccode-status

# If it works, you're all set!
```

## 🔧 Development

This project follows [Conventional Commits](docs/GIT_COMMIT_STYLE.md) style for commit messages.

See [CLAUDE_NEXT_STEPS.md](CLAUDE_NEXT_STEPS.md) for implementation roadmap and next steps.

## 📚 Documentation

**Docker Implementation:**
- [Quick Start Guide](QUICK_START.md) - Get running in 5 minutes
- [Docker Setup Guide](DOCKER_SETUP.md) - Comprehensive Docker documentation
- [Implementation Summary](DOCKER_IMPLEMENTATION.md) - Technical details and architecture

**General:**
- [Getting Started Guide](docs/GETTING_STARTED.md)
- [Security Overview](docs/SECURITY.md)
- [Git Commit Style Guide](docs/GIT_COMMIT_STYLE.md)

**Development:**
- [Implementation Roadmap](CLAUDE_NEXT_STEPS.md) - Next steps for Claude Code
- [Research Guide](research/README.md) - How to conduct framework research
- [Research Metaprompt](research/RESEARCH_PROMPT.md) - For Claude in research mode

## 🛠️ Technical Details

### Docker Implementation (Current)
- **Base OS**: Ubuntu 24.04 LTS
- **Python**: 3.11 with UV package manager
- **Node.js**: 20.x LTS
- **Tools**: Git, Claude Code CLI, build-essential
- **Security**: Non-root user, resource limits, no privilege escalation
- **Management**: Docker Compose, Makefile, helper scripts

### Apple Framework Implementation (In Development)
- **Swift** - Container implementation using Apple's Virtualization framework
- **Bash** - Setup and management scripts
- **Apple Container Framework** - [GitHub Repository](https://github.com/apple/container)

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [Claude Code](https://claude.ai) by Anthropic
- [Apple Container Framework](https://github.com/apple/container)
- Initial architecture designed with Claude 4.1 Opus

---

**Note**: This project is in early development. Contributions and feedback welcome!
