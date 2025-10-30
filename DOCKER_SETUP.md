# Docker Setup Guide for Claude Code Container

This directory contains a production-ready Docker environment for running Claude Code in a secure, isolated container.

## Quick Start

### 1. Build the Container

```bash
docker-compose build
```

### 2. Start the Container

```bash
docker-compose up -d
```

### 3. Access the Container

```bash
docker exec -it claude-code-container /bin/bash
```

### 4. Stop the Container

```bash
docker-compose down
```

## Directory Structure

```
ClaudeCodeContainer/
├── Dockerfile                 # Container image definition
├── docker-compose.yml         # Container orchestration config
├── .dockerignore             # Files to exclude from build
└── workspace/                # Mounted workspace directory
    ├── Projects/             # Your coding projects
    ├── Documentation/        # Documentation files
    ├── Research/             # Research materials
    ├── shared/               # Shared files between host and container
    ├── exports/              # Files to export from container
    └── imports/              # Files to import to container
```

## Container Specifications

### Base Image
- **OS**: Ubuntu 24.04 LTS
- **User**: Non-root user `claude` (UID 1000)
- **Working Directory**: `/workspace`

### Installed Tools
- **Python**: 3.11 with UV package manager
- **Node.js**: 20.x LTS
- **Git**: Latest stable version
- **Build Tools**: gcc, g++, make, build-essential
- **Utilities**: curl, wget, vim, nano, jq, tree
- **Claude Code CLI**: Latest stable release

### Resource Limits
- **CPU**: 4 cores maximum (1 core guaranteed)
- **RAM**: 8GB maximum (1GB guaranteed)

### Security Features
- Non-root user execution
- No privilege escalation
- Resource limits enforced
- Read-only system partitions (configurable)

## Usage Examples

### Running Python Code

```bash
# Inside the container
uv run python script.py

# Run tests
uv run pytest

# Install Python packages
uv pip install package-name
```

### Running Node.js Code

```bash
# Inside the container
node app.js

# Install packages
npm install package-name

# Run npm scripts
npm run dev
```

### Git Operations

```bash
# Git is pre-configured with defaults
git clone https://github.com/user/repo.git
git status
git add .
git commit -m "Your message"
```

## Volume Management

### Workspace Volume
- **Host Path**: `./workspace`
- **Container Path**: `/workspace`
- **Purpose**: Main working directory for projects and files

### Home Volume
- **Volume Name**: `claude-code-home`
- **Container Path**: `/home/claude`
- **Purpose**: Persists user settings, cache, and configurations

### Backing Up Data

```bash
# Backup workspace
tar -czf workspace-backup.tar.gz workspace/

# Backup home volume
docker run --rm -v claude-code-home:/data -v $(pwd):/backup ubuntu tar -czf /backup/home-backup.tar.gz /data
```

## Customization

### Environment Variables

Edit `docker-compose.yml` to add environment variables:

```yaml
environment:
  - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
  - CUSTOM_VAR=value
```

### Port Mapping

Uncomment and modify the `ports` section in `docker-compose.yml`:

```yaml
ports:
  - "3000:3000"  # Node.js dev server
  - "8000:8000"  # Python web server
```

### Additional Volumes

Mount additional directories in `docker-compose.yml`:

```yaml
volumes:
  - ./my-projects:/workspace/Projects/my-projects
  - ~/.ssh:/home/claude/.ssh:ro  # SSH keys (read-only)
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Check container status
docker-compose ps

# Rebuild from scratch
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Permission Issues

If you encounter permission issues with mounted volumes:

```bash
# On the host, match the UID/GID
sudo chown -R 1000:1000 workspace/

# Or run container as your user
docker-compose run --user $(id -u):$(id -g) claude-code-container
```

### Resource Limits

Adjust CPU and memory limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '8.0'
      memory: 16G
```

## Maintenance

### Update Container

```bash
# Pull latest base image
docker pull ubuntu:24.04

# Rebuild container
docker-compose build --no-cache

# Restart with new image
docker-compose down
docker-compose up -d
```

### Clean Up

```bash
# Remove stopped containers
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Clean up Docker system
docker system prune -a
```

## Security Considerations

1. **API Keys**: Never commit API keys. Use environment variables or `.env` files.
2. **Network Access**: Container has internet access via bridge network.
3. **User Permissions**: Container runs as non-root user `claude`.
4. **Volume Security**: Mounted volumes have the same security as host filesystem.
5. **Updates**: Regularly update base image and installed packages.

## Advanced Configuration

### Docker-in-Docker

To enable Docker inside the container (use with caution):

1. Uncomment the Docker socket mount in `docker-compose.yml`
2. Install Docker CLI in the container
3. Add `claude` user to docker group

### Custom Network

Create a custom network for multiple containers:

```yaml
networks:
  claude-network:
    driver: bridge

services:
  claude-code-container:
    networks:
      - claude-network
```

## Support

For issues related to:
- **Docker setup**: Check Docker and docker-compose documentation
- **Claude Code**: Visit Anthropic's official documentation
- **Container environment**: Review the Dockerfile and docker-compose.yml

## License

This Docker configuration is part of the ClaudeCodeContainer project.
