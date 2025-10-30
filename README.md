# ClaudeCodeContainer

A production-ready, containerized development environment for Claude Code. Provides secure isolation, pre-configured tooling, consistent cross-platform development experience, and integrated BaseProject workflows using Docker.

**Status:** Production Ready v1.0.1

> **Historical Note:** Early research explored Apple's container framework for native macOS virtualization. That work is archived in `research/archive/`.

## Features

- **Docker-based Isolation**: Secure, containerized environment with controlled resource limits
- **Modern Toolchain**: Python 3.12, Node.js 20, UV package manager, Git
- **Pre-configured Workspace**: Organized project structure with persistent storage
- **Resource Management**: Configurable limits (8GB RAM, 4 CPUs by default)
- **Cross-platform**: Runs consistently on macOS, Linux, and Windows
- **Production Security**: Non-root user, no privilege escalation, isolated file access
- **Development Ready**: Claude Code CLI pre-installed with MCP server support
- **BaseProject Integration**: 18+ workflow guides, best practices, and project templates
- **House Agents**: Context-saving specialized agents (house-research, house-git, house-bash, house-coder)

## Quick Start

```bash
# Clone and navigate to project
git clone https://github.com/AutumnsGrove/ClaudeCodeContainer.git
cd ClaudeCodeContainer

# Build and start container
make build
make start

# Enter container shell
make enter
```

Your workspace is now available at `./workspace` on your host machine and `/workspace` inside the container.

## System Requirements

| Requirement | Specification |
|-------------|---------------|
| Docker | 24.0+ (with Docker Compose V2) |
| RAM | 8GB minimum (10GB+ recommended) |
| Disk Space | 10GB free space |
| OS | macOS 11+, Ubuntu 20.04+, Windows 10+ with WSL2 |

## Usage

### Common Commands

```bash
# Container lifecycle
make start              # Start container in detached mode
make stop               # Stop container (preserves data)
make restart            # Stop and restart container
make enter              # Open interactive shell in container

# Build and maintenance
make build              # Build container image
make rebuild            # Rebuild from scratch
make clean              # Remove stopped containers and images

# Monitoring
make status             # Show container status
make stats              # Display resource usage
make logs               # View container logs
```

### Docker Compose (Alternative)

```bash
docker compose up -d                                    # Start container
docker compose down                                     # Stop container
docker exec -it claude-code-container /bin/bash        # Enter shell
docker compose logs -f                                 # Follow logs
```

### Working with Python

```bash
# Inside container
uv run python script.py         # Run Python scripts
uv run pytest                   # Run tests
uv add package-name             # Add dependency
```

## Documentation

### Getting Started
- [Quick Start Guide](docs/QUICK_START.md) - Detailed setup walkthrough
- [Docker Setup Guide](docs/DOCKER_SETUP.md) - Comprehensive Docker configuration
- [BaseProject Integration](docs/BASEPROJECT.md) - Workflow guides and house agents
- [Getting Started](docs/GETTING_STARTED.md) - Development workflow basics

### Configuration
- [Shell Aliases](docs/ALIASES.md) - Time-saving command shortcuts
- [Resource Management](docs/RESOURCES.md) - Memory, CPU, and disk configuration
- [Security Overview](docs/SECURITY.md) - Security features and best practices

### Advanced
- [Implementation Details](docs/IMPLEMENTATION.md) - Technical architecture and design
- [Git Commit Style](docs/GIT_COMMIT_STYLE.md) - Contributing guidelines

## Project Structure

```
ClaudeCodeContainer/
├── workspace/              # Your projects and files (persistent)
├── docker/                 # Docker configuration files
│   └── Dockerfile
├── scripts/                # Helper scripts for container management
├── docs/                   # Comprehensive documentation
├── research/               # Archived Apple framework research
├── docker-compose.yml      # Container orchestration
├── Makefile               # Convenient command shortcuts
└── README.md              # This file
```

## Technical Stack

**Container Platform:**
- Ubuntu 24.04 LTS base image
- Docker Compose V2 orchestration
- Resource-limited execution (configurable)

**Development Tools:**
- Python 3.12 with UV package manager
- Node.js 20 LTS with npm
- Git 2.40+
- Claude Code CLI
- build-essential toolchain

**Security:**
- Non-root container user (UID 1000)
- Read-only root filesystem options
- No privilege escalation
- Isolated network namespace
- Configurable resource limits

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Claude Code](https://claude.ai) by Anthropic - AI-powered development assistant
- [UV](https://github.com/astral-sh/uv) - Fast Python package manager
- [Docker](https://www.docker.com/) - Container platform
- Project architecture designed with Claude AI

---

**Contributing:** Issues and pull requests welcome. Please follow the [commit style guide](docs/GIT_COMMIT_STYLE.md).
