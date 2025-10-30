# Quick Start Guide - Claude Code Container

## Prerequisites

- Docker Desktop installed and running
- Docker Compose installed (included with Docker Desktop)
- 10GB free disk space
- Internet connection for pulling base images

## 5-Minute Setup

### 1. Build and Start (First Time)

```bash
./scripts/start-container.sh
```

This will:
- Create workspace directories
- Build the Docker image (~5 minutes first time)
- Start the container
- Verify it's running

### 2. Enter the Container

```bash
./scripts/enter-container.sh
```

You're now inside the container with access to:
- Python 3.11 + UV package manager
- Node.js 20.x LTS
- Git
- Claude Code CLI
- All development tools

### 3. Verify Installation

Inside the container, run:

```bash
python --version      # Should show Python 3.11.x
node --version        # Should show v20.x.x
git --version         # Should show git version
uv --version          # Should show UV version
claude --version      # Should show Claude CLI version
```

### 4. Start Working

Your workspace is located at `/workspace`:

```bash
cd /workspace/Projects
mkdir my-first-project
cd my-first-project
git init
```

Files created here are automatically synced to your host machine at:
`./workspace/Projects/my-first-project`

## Daily Usage

### Start Container

```bash
./scripts/start-container.sh
```

### Enter Container

```bash
./scripts/enter-container.sh
```

### Stop Container

```bash
./scripts/stop-container.sh
```

## Common Commands

### Python Development

```bash
# Run Python script
uv run python script.py

# Install package
uv pip install requests

# Run tests
uv run pytest
```

### Node.js Development

```bash
# Run Node script
node app.js

# Install package
npm install express

# Start dev server
npm run dev
```

### Git Operations

```bash
# Clone repository
git clone https://github.com/user/repo.git

# Make changes and commit
git add .
git commit -m "Your changes"
git push
```

## Workspace Directories

- `/workspace/Projects` - Your coding projects
- `/workspace/Documentation` - Documentation and notes
- `/workspace/Research` - Research materials
- `/workspace/shared` - Shared files between projects
- `/workspace/exports` - Files to export from container
- `/workspace/imports` - Files to import to container

## Troubleshooting

### Container won't start

```bash
# Check Docker is running
docker info

# View logs
docker-compose logs

# Rebuild from scratch
./scripts/rebuild-container.sh
```

### Permission errors

```bash
# On host machine
sudo chown -R 1000:1000 workspace/
```

### Need to rebuild

```bash
./scripts/rebuild-container.sh
```

## Next Steps

1. Read [Docker Setup Guide](DOCKER_SETUP.md) for detailed configuration options
2. Set up your API keys in `.env` file (copy from `.env.example`)
3. Customize resource limits in `docker-compose.yml`
4. Add your SSH keys for Git operations

## Support

- Docker Documentation: https://docs.docker.com/
- Claude Code Documentation: https://docs.anthropic.com/
- Project Issues: See project README.md
