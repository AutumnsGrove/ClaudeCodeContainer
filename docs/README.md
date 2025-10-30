# ClaudeCodeContainer Documentation

Complete documentation for the ClaudeCodeContainer Docker environment.

## Overview

ClaudeCodeContainer provides a secure, isolated Docker environment for Claude Code development. This system offers containerized execution, persistent workspaces, and pre-configured development tools optimized for AI-assisted coding workflows.

Built on Docker Desktop, this solution ensures consistent development environments across machines while maintaining security isolation between your host system and AI-powered code execution.

## Getting Started

**New to ClaudeCodeContainer?**
1. [Quick Start Guide](QUICK_START.md) - Get running in 5 minutes
2. [Docker Setup Guide](DOCKER_SETUP.md) - Detailed installation and configuration

**Prerequisites:**
- macOS 13.0 or later (Linux support planned)
- Docker Desktop 4.0+
- 8GB available RAM (16GB recommended)
- 50GB free disk space

## Configuration

### Essential Configuration Files
- [Shell Aliases](ALIASES.md) - Time-saving command shortcuts
- [Resource Management](RESOURCES.md) - Monitor and optimize system resources
- [Environment Variables](.env.example) - Configure API keys and settings

### Docker Configuration
The container is configured in `Dockerfile` with:
- Ubuntu 24.04 LTS base image
- Python 3.12.3 with UV package manager
- Node.js 20.x LTS
- Git with pre-configured settings
- Pre-installed development tools

## Usage

### Daily Workflow

**Starting Your Session:**
```bash
# Start the container (if not running)
docker-compose up -d

# Enter the container
docker exec -it claude-code-container bash

# Or use the alias (if configured)
cc-enter
```

**Working in the Container:**
```bash
# Navigate to your projects
cd /workspace/Projects

# Use Claude Code with UV
uv run python -m src.cli

# Run tests
uv run pytest

# Format code with Black
black .
```

**Ending Your Session:**
```bash
# Exit the container shell
exit

# Stop the container (optional - data persists)
docker-compose down

# View container logs
docker-compose logs
```

### Common Tasks

**Starting/Stopping the Container:**
```bash
# Start container in background
docker-compose up -d

# Stop container
docker-compose down

# Restart container
docker-compose restart

# View running containers
docker ps
```

**Accessing the Workspace:**
```bash
# Enter the container
docker exec -it claude-code-container bash

# Execute single command
docker exec claude-code-container ls /workspace

# Copy files to container
docker cp ./local-file.txt claude-code-container:/workspace/imports/

# Copy files from container
docker cp claude-code-container:/workspace/exports/output.txt ./
```

**Running Commands Inside the Container:**
```bash
# Python scripts (always use uv run)
docker exec claude-code-container uv run python script.py

# Run tests
docker exec claude-code-container uv run pytest

# Git operations
docker exec claude-code-container git status
docker exec claude-code-container git commit -m "Update"

# Install packages
docker exec claude-code-container uv pip install package-name
```

**Viewing Logs:**
```bash
# Follow container logs
docker-compose logs -f

# View last 100 lines
docker-compose logs --tail=100

# View logs for specific service
docker logs claude-code-container
```

See the [Docker Setup Guide](DOCKER_SETUP.md) for detailed commands and configuration options.

## Advanced Topics

- [Implementation Details](IMPLEMENTATION.md) - Technical architecture and design decisions
- [Security](SECURITY.md) - Security model and best practices
- [Git Commit Style](GIT_COMMIT_STYLE.md) - Contribution guidelines

### Container Customization

**Modifying the Container:**
Edit `Dockerfile` to add packages or change configuration, then rebuild:
```bash
docker-compose build --no-cache
docker-compose up -d
```

**Environment Variables:**
Configure in `.env` file:
- API keys and credentials
- Custom paths
- Feature flags
- Resource limits

**Volume Mounts:**
Configured in `docker-compose.yml`:
- `/workspace` - Main working directory (persistent)
- `/workspace/shared` - Bidirectional file sharing
- `/workspace/exports` - Export files to host
- `/workspace/imports` - Import files from host

## Workspace Organization

The container workspace is organized as follows:

```
/workspace/
├── Projects/           # Active development projects
│   └── .git/          # Git repositories
├── Documentation/      # Project documentation
│   └── presets/       # Claude Code prompt templates
├── Research/          # Research materials and notes
├── shared/            # Bidirectional file sharing with host
├── exports/           # Files to export from container to host
└── imports/           # Files to import from host to container
```

**Directory Purposes:**

- **Projects/**: Your coding projects and repositories. Full git support.
- **Documentation/**: Technical docs, guides, and Claude Code presets.
- **Research/**: Experimental code, proof-of-concepts, research notes.
- **shared/**: Real-time bidirectional access between host and container.
- **exports/**: One-way transfer from container to host system.
- **imports/**: One-way transfer from host to container.

**Host Mapping:**
The workspace is mapped to `~/ClaudeCodeWorkspace/` on your host system, allowing direct file access when the container is running.

## Troubleshooting

### Container Won't Start
```bash
# Check Docker is running
docker info

# View detailed logs
docker-compose logs

# Rebuild container
docker-compose build --no-cache
docker-compose up -d
```

### Permission Issues
```bash
# Fix workspace permissions
docker exec claude-code-container chown -R ubuntu:ubuntu /workspace

# Check current permissions
docker exec claude-code-container ls -la /workspace
```

### Out of Disk Space
```bash
# Clean up Docker resources
docker system prune -a

# Remove unused volumes
docker volume prune

# Check disk usage
docker system df
```

### Python/UV Issues
```bash
# Always use uv run for Python commands
docker exec claude-code-container uv run python --version

# Reinstall UV if needed
docker exec claude-code-container curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Common Error Messages

**"Cannot connect to Docker daemon"**
- Solution: Ensure Docker Desktop is running

**"Port already in use"**
- Solution: Stop conflicting containers or change port in `docker-compose.yml`

**"No space left on device"**
- Solution: Run `docker system prune -a` to clean up

For more issues, see [Docker Setup Guide](DOCKER_SETUP.md) or open an issue on GitHub.

## Technical Stack

**Base System:**
- OS: Ubuntu 24.04 LTS
- Runtime: Docker Desktop 4.0+
- Container Orchestration: Docker Compose

**Development Tools:**
- Python: 3.12.3
- Package Manager: UV 0.9.6
- Node.js: 20.x LTS
- Git: Latest stable
- Black: Python code formatter
- pytest: Testing framework

**Pre-installed Utilities:**
- curl, wget
- vim, nano
- tmux, screen
- build-essential
- ssh client

## Additional Resources

- [Main README](../README.md) - Project overview and installation
- [Research Archive](../research/archive/) - Historical research and design decisions
- [Docker Documentation](https://docs.docker.com/) - Official Docker docs
- [UV Documentation](https://github.com/astral-sh/uv) - UV package manager

## Contributing

Contributions are welcome! Please see [Git Commit Style](GIT_COMMIT_STYLE.md) for guidelines.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: Follow commit guidelines
4. Push to branch: `git push origin feature-name`
5. Open a Pull Request

## Support

**Getting Help:**
- Open an issue on GitHub
- Check [Discussions](https://github.com/yourusername/claude-code-container/discussions)
- Review closed issues for solutions

**Security Issues:**
Report security vulnerabilities privately via GitHub Security Advisories.

## Historical Note

Early research for this project explored Apple's native container framework as a Docker alternative. This work is preserved in `research/archive/apple-framework/` for future reference when the framework reaches production maturity. The current implementation uses Docker for broader compatibility and production readiness.

---

**Project Status:** Active Development
**License:** MIT
**Maintained by:** Community Contributors

*Note: This project is not officially affiliated with Anthropic. It's a community tool designed to enhance the Claude Code experience with containerized security and better organization.*
