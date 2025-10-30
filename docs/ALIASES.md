# Shell Aliases for ClaudeCodeContainer

Convenient shell aliases to speed up your workflow with ClaudeCodeContainer.

## Setup

### Step 1: Set Your Installation Path

Add this to your shell configuration file (`~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`):

```bash
# ClaudeCodeContainer configuration
export CCODE_HOME="$HOME/Documents/Projects/ClaudeCodeContainer"  # Adjust to your installation path
```

After adding this line, reload your shell configuration:

```bash
# For Bash
source ~/.bashrc

# For Zsh
source ~/.zshrc

# For Fish shell
set -Ux CCODE_HOME ~/Documents/Projects/ClaudeCodeContainer
```

### Step 2: Add Aliases

Copy the aliases below to the same shell configuration file:

## Core Aliases

### Container Lifecycle

```bash
# Build the Docker image
alias ccode-build='docker compose -f $CCODE_HOME/docker-compose.yml build'

# Start the container in detached mode
alias ccode-start='docker compose -f $CCODE_HOME/docker-compose.yml up -d'

# Stop the running container
alias ccode-stop='docker compose -f $CCODE_HOME/docker-compose.yml down'

# Restart the container (stop then start)
alias ccode-restart='ccode-stop && ccode-start'

# Rebuild the image without using cached layers
alias ccode-rebuild='docker compose -f $CCODE_HOME/docker-compose.yml build --no-cache'

# Full rebuild and restart
alias ccode-fresh='ccode-rebuild && ccode-restart'
```

### Container Interaction

```bash
# Open an interactive shell inside the container
alias ccode-shell='docker exec -it claude-code-container /bin/bash'

# View container logs
alias ccode-logs='docker logs claude-code-container'

# Follow container logs in real-time
alias ccode-logs-follow='docker logs -f claude-code-container'

# Tail the last 50 lines of logs
alias ccode-logs-tail='docker logs --tail 50 claude-code-container'

# Run a command inside the container
# Usage: ccode-run "python -m pip list"
alias ccode-run='docker exec -it claude-code-container'
```

### Status and Monitoring

```bash
# Check if container is running
alias ccode-status='docker ps | grep claude-code-container'

# View container resource usage
alias ccode-stats='docker stats claude-code-container --no-stream'

# Get detailed container information
alias ccode-info='docker inspect claude-code-container'

# Check container health status
alias ccode-health='docker ps --format "table {{.Names}}\t{{.Status}}" | grep claude-code'

# View container ports
alias ccode-ports='docker port claude-code-container'
```

### Workspace Navigation

```bash
# Navigate to ClaudeCodeContainer home
alias ccode-home='cd $CCODE_HOME'

# Navigate to workspace directory
alias ccode-ws='cd $CCODE_HOME/workspace'

# Navigate to projects directory
alias ccode-projects='cd $CCODE_HOME/workspace/Projects'

# Navigate to documentation
alias ccode-docs='cd $CCODE_HOME/docs'

# List workspace contents
alias ccode-list='ls -la $CCODE_HOME/workspace'
```

### Maintenance

```bash
# Clean up unused Docker resources
alias ccode-clean='docker system prune -f'

# Clean up everything including volumes (WARNING: removes data!)
alias ccode-clean-all='docker system prune -af --volumes'

# Update ClaudeCodeContainer (pull latest and rebuild)
alias ccode-update='cd $CCODE_HOME && git pull && ccode-rebuild'

# Create a timestamped backup of workspace
alias ccode-backup='tar -czf ~/ccode-backup-$(date +\%Y\%m\%d-\%H\%M\%S).tar.gz $CCODE_HOME/workspace'

# List backup files
alias ccode-backups='ls -lh ~/ccode-backup-*.tar.gz'

# Remove all stopped containers
alias ccode-prune-containers='docker container prune -f'

# Remove dangling images
alias ccode-prune-images='docker image prune -f'
```

### Development Helpers

```bash
# Check Git status of ClaudeCodeContainer repo
alias ccode-git-status='cd $CCODE_HOME && git status'

# View recent commits
alias ccode-git-log='cd $CCODE_HOME && git log --oneline -10'

# List Docker images related to claude-code
alias ccode-images='docker images | grep claude-code'

# View environment variables in running container
alias ccode-env='docker exec claude-code-container env | sort'
```

## Quick Info Aliases

```bash
# Get the container's IP address
alias ccode-ip='docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" claude-code-container'

# Check image size
alias ccode-size='docker images --format "table {{.Repository}}\t{{.Size}}" | grep claude-code'

# View container creation time
alias ccode-created='docker inspect -f "{{.Created}}" claude-code-container'

# Count total aliases
alias ccode-aliases='alias | grep ccode | wc -l'
```

## Usage Examples

### Starting Your Day

```bash
# Start the container
ccode-start

# Check that it's running
ccode-status

# Open a shell inside the container
ccode-shell

# Or check logs to see startup messages
ccode-logs-follow
```

### Development Workflow

```bash
# Navigate to your project
ccode-projects
cd my-project

# Run a quick command in the container
ccode-run python -m pip list

# Check container resource usage
ccode-stats

# View recent changes
ccode-git-status
```

### Troubleshooting

```bash
# Check if container is healthy
ccode-health

# View full logs for debugging
ccode-logs-tail

# Get detailed container info
ccode-info

# Check container IP
ccode-ip
```

### Cleanup and Maintenance

```bash
# Create a backup before making changes
ccode-backup

# Clean up Docker resources
ccode-clean

# Update to the latest version
ccode-update

# Full rebuild if you're having issues
ccode-fresh
```

## Advanced: Function-Based Alternative

If you prefer more flexibility, use shell functions instead of aliases. Add this to your shell configuration:

```bash
# Function: Run command in ClaudeCodeContainer
ccode-exec() {
  if [ -z "$1" ]; then
    echo "Usage: ccode-exec <command>"
    return 1
  fi
  docker exec -it claude-code-container "$@"
}

# Function: View container logs with options
ccode-log() {
  local lines=${1:-50}
  docker logs --tail "$lines" claude-code-container
}

# Function: Backup with optional custom name
ccode-backup-custom() {
  local name=${1:-backup}
  tar -czf "$HOME/ccode-${name}-$(date +%Y%m%d-%H%M%S).tar.gz" "$CCODE_HOME/workspace"
  echo "Backup created: ~/ccode-${name}-$(date +%Y%m%d-%H%M%S).tar.gz"
}

# Function: Print all ccode aliases and functions
ccode-help() {
  echo "ClaudeCodeContainer Aliases and Functions:"
  echo "=========================================="
  alias | grep ccode
  echo ""
  echo "Custom Functions:"
  echo "- ccode-exec <command>"
  echo "- ccode-log [lines]"
  echo "- ccode-backup-custom [name]"
  echo "- ccode-help"
}
```

## Fish Shell Configuration

If you use Fish shell, add this to `~/.config/fish/config.fish`:

```fish
# Set ClaudeCodeContainer home
set -Ux CCODE_HOME ~/Documents/Projects/ClaudeCodeContainer

# Container lifecycle
abbr -a ccode-build docker compose -f $CCODE_HOME/docker-compose.yml build
abbr -a ccode-start docker compose -f $CCODE_HOME/docker-compose.yml up -d
abbr -a ccode-stop docker compose -f $CCODE_HOME/docker-compose.yml down
abbr -a ccode-restart ccode-stop; and ccode-start

# Container interaction
abbr -a ccode-shell docker exec -it claude-code-container /bin/bash
abbr -a ccode-logs docker logs claude-code-container

# Status
abbr -a ccode-status docker ps | grep claude-code-container

# Workspace
abbr -a ccode-home cd $CCODE_HOME
abbr -a ccode-ws cd $CCODE_HOME/workspace
```

## Customization Tips

### Adding Custom Paths

If your installation is in a different location, update `CCODE_HOME`:

```bash
# For custom installation location
export CCODE_HOME="/opt/claude-code"  # or wherever you installed it
export CCODE_HOME="/mnt/projects/ClaudeCodeContainer"  # for WSL2
```

### Renaming Aliases

Prefer shorter names? Create your own variations:

```bash
alias cc-start='ccode-start'
alias cc-stop='ccode-stop'
alias cc='ccode-shell'
```

### Adding Organization-Specific Aliases

Add domain-specific commands for your workflow:

```bash
# For data science work
alias ccode-notebook='ccode-run jupyter notebook --ip=0.0.0.0'

# For Python development
alias ccode-pytest='ccode-run pytest'
alias ccode-pip='ccode-run pip'

# For Node.js development
alias ccode-npm='ccode-run npm'
alias ccode-node='ccode-run node'
```

### Conditional Aliases

Check if container exists before using aliases:

```bash
# Wrap aliases with existence check
ccode-start-safe() {
  if docker ps -a | grep -q claude-code-container; then
    ccode-start
  else
    echo "Error: Container not found. Check docker-compose.yml"
    return 1
  fi
}
```

## Troubleshooting Aliases

### Aliases Not Working

1. **Verify the export is set:**
   ```bash
   echo $CCODE_HOME
   ```

2. **Reload your shell configuration:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc for Zsh
   ```

3. **Check alias is defined:**
   ```bash
   alias | grep ccode
   ```

### Container Name Mismatch

If your container has a different name, update the aliases:

```bash
# Find your actual container name
docker ps -a

# Then replace "claude-code-container" in all aliases with the correct name
```

### Path Issues on Different Operating Systems

- **macOS/Linux:** Paths work as-is
- **Windows (WSL2):** Use `/mnt/c/Users/YourName/...` style paths or convert to Windows paths
- **Windows (Git Bash):** May need to adjust path separators

## Verifying Your Setup

After adding aliases, verify everything works:

```bash
# Count how many ccode aliases you have
alias | grep ccode | wc -l

# Test a simple alias
ccode-status

# Get detailed help (if using function-based setup)
ccode-help
```

## See Also

- [ClaudeCodeContainer Documentation](../README.md)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Shell Configuration Guide](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html)
