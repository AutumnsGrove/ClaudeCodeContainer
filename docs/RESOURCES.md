# Resource Management

Detailed information about system resources, monitoring, and optimization for the Claude Code Container environment.

## System Requirements

### Minimum Requirements

| Component | Specification | Notes |
|-----------|---------------|-------|
| Docker | 24.0+ | Docker Compose V2 required |
| RAM | 8GB | 6GB available for host + 2GB for container |
| CPU | 2 cores | Intel/AMD x86_64 or ARM64 |
| Disk Space | 10GB free | 2GB for image + 8GB for workspace |
| OS | Modern 64-bit | macOS 11+, Ubuntu 20.04+, Windows 10+ WSL2 |

### Recommended Resources

| Component | Specification | Benefits |
|-----------|---------------|----------|
| RAM | 10GB+ | Better performance for large builds and tests |
| CPU | 4+ cores | Faster compilation and parallel operations |
| Disk Space | 20GB+ | Room for multiple projects and caches |
| SSD | NVMe/SATA SSD | Significantly faster I/O operations |

## Docker Image Footprint

### Image Size Breakdown

The container image is built in layers. Approximate sizes:

| Component | Size | Description |
|-----------|------|-------------|
| Base Ubuntu 24.04 | ~80 MB | Minimal Ubuntu LTS base |
| System packages | ~150 MB | build-essential, curl, wget, git, etc. |
| Python 3.12 + pip | ~180 MB | Python runtime and package manager |
| Node.js 20 LTS | ~220 MB | Node.js runtime and npm |
| UV package manager | ~30 MB | Fast Python package installer |
| Development tools | ~100 MB | vim, nano, htop, jq, etc. |
| Claude CLI | ~15 MB | Anthropic CLI (if available) |
| **Total Compressed** | **~775 MB** | Downloaded/stored size |
| **Total Uncompressed** | **~1.08 GB** | Actual disk usage |

### Layer Caching

Docker caches layers during builds. Rebuilds are faster:
- First build: ~3-5 minutes (downloads everything)
- Subsequent builds: ~30-60 seconds (uses cached layers)
- `make rebuild`: ~3-5 minutes (bypasses cache with `--no-cache`)

## Runtime Resource Usage

### Memory Usage

The container's memory usage varies based on workload:

| Scenario | Memory Usage | Configuration |
|----------|--------------|---------------|
| **Idle** | 100-200 MB | Just bash shell running |
| **Light Development** | 300-500 MB | Editing files, running simple scripts |
| **Python Development** | 500 MB - 2 GB | Running tests, imports, type checking |
| **Node.js Development** | 800 MB - 3 GB | npm install, webpack, dev servers |
| **Heavy Compilation** | 2-6 GB | Large builds, parallel operations |
| **Maximum Limit** | 8 GB | Hard limit set in docker-compose.yml |

**Configuration (docker-compose.yml):**
```yaml
deploy:
  resources:
    limits:
      memory: 8G         # Maximum 8GB RAM
    reservations:
      memory: 1G         # Guaranteed 1GB RAM
```

### CPU Usage

CPU usage patterns:

| Activity | CPU Cores | Duration |
|----------|-----------|----------|
| **Idle** | 0-5% of 1 core | Continuous |
| **File editing** | 5-15% of 1 core | Bursts |
| **Python script** | 1-2 cores | Varies |
| **npm install** | 2-4 cores | 1-5 minutes |
| **Parallel tests** | Up to 4 cores | Varies |
| **Maximum limit** | 4.0 cores | Hard limit |

**Configuration (docker-compose.yml):**
```yaml
deploy:
  resources:
    limits:
      cpus: '4.0'        # Maximum 4 CPU cores
    reservations:
      cpus: '1.0'        # Guaranteed 1 CPU core
```

### Disk Space Usage

| Component | Initial | Growth Rate | Notes |
|-----------|---------|-------------|-------|
| Docker image | 1.08 GB | Stable | Only grows on rebuild |
| Container layer | <10 MB | Slow | Ephemeral, lost on rebuild |
| `/workspace` | ~1 MB | Variable | Your project files |
| `claude-home` volume | ~50 MB | Moderate | Caches, config, history |
| Python packages (UV cache) | 0 MB | Fast | Can grow to 1-5 GB |
| Node modules | 0 MB | Very fast | 100-500 MB per project |
| Git repositories | Variable | Variable | Depends on projects |

**Total expected usage:** 2-10 GB depending on project complexity.

### Network Bandwidth

| Operation | Bandwidth | Frequency |
|-----------|-----------|-----------|
| Initial build | 500 MB - 1 GB | Once |
| Package updates | 10-500 MB | As needed |
| Git operations | Variable | Per operation |
| Claude API calls | <1 MB | Per request |

## Resource Monitoring

### Quick Status Check

```bash
# Show container status and resource usage
make status
```

**Example output:**
```
Container Status:
NAME                    STATUS              PORTS
claude-code-container   Up 2 hours

Resource Usage:
CONTAINER               CPU %     MEM USAGE / LIMIT   MEM %     NET I/O
claude-code-container   1.23%     456MB / 8GB         5.70%     1.2kB / 890B
```

### Continuous Monitoring

```bash
# Monitor resources in real-time (updates every 1 second)
docker stats claude-code-container
```

**Example output:**
```
CONTAINER               CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O
claude-code-container   2.45%     892MB / 8GB           11.15%    15.3kB / 12.1kB   45.2MB / 12.3MB

# Press Ctrl+C to stop monitoring
```

### Detailed Container Inspection

```bash
# Show all container details including resource limits
docker inspect claude-code-container

# Filter for specific resource information
docker inspect claude-code-container | jq '.[0].HostConfig.Memory'
docker inspect claude-code-container | jq '.[0].HostConfig.NanoCpus'
```

### Disk Usage Analysis

```bash
# Overview of Docker disk usage
docker system df
```

**Example output:**
```
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          5         1         2.5GB     1.4GB (56%)
Containers      1         1         45MB      0B (0%)
Local Volumes   1         1         156MB     0B (0%)
Build Cache     23        0         1.2GB     1.2GB (100%)
```

```bash
# Detailed breakdown with sizes
docker system df -v

# Show specific volume size
docker volume inspect claude-code-home | jq '.[0].Mountpoint'
```

### Inside Container Monitoring

Once inside the container (`make enter`):

```bash
# Memory usage
free -h

# Disk usage
df -h

# Process list with resource usage
htop

# Top CPU/memory consumers
top

# Directory sizes
du -sh /workspace/*
du -sh ~/.cache/*
```

## Resource Comparison: Container vs Native

| Aspect | Container | Native | Overhead |
|--------|-----------|--------|----------|
| **Memory (idle)** | 100-200 MB | 0 MB | +100-200 MB |
| **Memory (active)** | +50-100 MB | Baseline | ~5-10% overhead |
| **CPU (idle)** | <1% | 0% | Negligible |
| **CPU (active)** | 1-2% | Baseline | ~1-5% overhead |
| **Disk I/O** | 85-95% | 100% | 5-15% slower |
| **Network** | 95-99% | 100% | 1-5% slower |
| **Startup time** | 2-5 seconds | Instant | +2-5 seconds |

### Advantages of Container Approach

Despite the overhead, containerization provides:

1. **Isolation**: No conflicts with host system packages
2. **Consistency**: Same environment across all platforms
3. **Security**: Sandboxed execution with resource limits
4. **Portability**: Works identically on macOS, Linux, Windows
5. **Reproducibility**: Dockerfile ensures identical setup
6. **Clean removal**: Delete container = no trace left

### When Native Might Be Better

Consider native installation if:
- Working on resource-constrained machines (<4GB RAM)
- Need absolute maximum performance
- Already have compatible development environment
- Don't need isolation or portability

## Optimization Tips

### Reducing Memory Usage

1. **Adjust memory limits** in `docker-compose.yml`:
   ```yaml
   limits:
     memory: 4G  # Reduce from 8G if not needed
   ```

2. **Clear UV cache** periodically:
   ```bash
   # Inside container
   uv cache clean
   ```

3. **Remove unused packages**:
   ```bash
   # Inside container
   uv prune  # Remove unused Python packages
   npm prune  # Remove unused Node packages
   ```

### Reducing Disk Usage

1. **Clear build cache**:
   ```bash
   docker builder prune
   ```

2. **Remove unused images**:
   ```bash
   docker image prune -a
   ```

3. **Clean node_modules** in old projects:
   ```bash
   # Inside workspace
   find . -name "node_modules" -type d -prune -exec rm -rf '{}' +
   ```

4. **Clear Python cache**:
   ```bash
   # Inside container
   find . -type d -name "__pycache__" -exec rm -rf {} +
   find . -type f -name "*.pyc" -delete
   ```

### Improving Performance

1. **Use SSD for workspace**: Store workspace on fast SSD
2. **Allocate more CPU**: Increase CPU limit for faster builds
   ```yaml
   limits:
     cpus: '8.0'  # If you have 8+ cores
   ```

3. **Use volume for heavy I/O**: For databases, use Docker volumes instead of bind mounts

4. **Enable BuildKit**: Faster Docker builds
   ```bash
   export DOCKER_BUILDKIT=1
   make rebuild
   ```

## Cleanup and Maintenance

### Regular Maintenance (Weekly)

```bash
# Remove unused Docker resources
docker system prune -f

# Check disk usage
docker system df

# Check container logs size
docker logs claude-code-container 2>&1 | wc -c
```

### Deep Cleaning (Monthly)

```bash
# Stop container
make stop

# Remove all unused Docker data (WARNING: affects all Docker projects)
docker system prune -a --volumes

# Rebuild container
make build
make start
```

### Emergency Disk Space Recovery

If running out of disk space:

```bash
# 1. Stop container
make stop

# 2. Remove all unused Docker resources
docker system prune -a -f

# 3. Remove build cache
docker builder prune -a -f

# 4. Remove unused volumes (CAREFUL: may delete data)
docker volume prune -f

# 5. Restart container
make start
```

### Backup Before Cleaning

Always backup important data:

```bash
# Backup workspace and home volume
make backup

# Creates timestamped archives:
# - workspace-backup-YYYYMMDD-HHMMSS.tar.gz
# - home-backup-YYYYMMDD-HHMMSS.tar.gz
```

## Resource Limit Configuration

### Adjusting Limits

Edit `docker-compose.yml` to customize resource limits:

```yaml
deploy:
  resources:
    limits:
      cpus: '4.0'        # Adjust based on your CPU count
      memory: 8G         # Adjust based on your RAM
    reservations:
      cpus: '1.0'        # Minimum guaranteed CPU
      memory: 1G         # Minimum guaranteed RAM
```

### Process Limits

The container includes ulimit configurations:

```yaml
ulimits:
  nofile:              # Maximum open files
    soft: 65536
    hard: 65536
  nproc:               # Maximum processes
    soft: 32768
    hard: 32768
```

### Storage Limits

To limit workspace disk usage, use Docker storage quotas:

```bash
# Example: Limit volume to 50GB (requires Docker Desktop or compatible driver)
docker volume create --driver local \
  --opt type=none \
  --opt o=size=50g \
  --opt device=/path/to/workspace \
  claude-workspace
```

## Troubleshooting Resource Issues

### Container Won't Start (Out of Memory)

```bash
# Check Docker daemon resources
docker info | grep Memory

# Reduce container memory limit
# Edit docker-compose.yml: memory: 4G

# Restart Docker daemon (macOS/Windows)
```

### Slow Performance

```bash
# Check if container is hitting CPU limits
docker stats claude-code-container

# Increase CPU allocation in docker-compose.yml
# Check host CPU usage: top or htop
```

### Disk Space Full

```bash
# Find what's using space
docker system df -v

# Clean up (see cleanup section above)
docker system prune -a -f
```

## Monitoring Best Practices

1. **Check resources before large operations**:
   ```bash
   make status  # Before npm install, large builds
   ```

2. **Monitor during heavy workloads**:
   ```bash
   docker stats claude-code-container  # Keep running in separate terminal
   ```

3. **Set up alerts** (optional):
   ```bash
   # Example: Alert if memory usage > 90%
   watch -n 5 'docker stats --no-stream claude-code-container | awk "NR==2 {if (substr(\$7,1,length(\$7)-1) > 90) print \"WARNING: High memory usage\"}"'
   ```

4. **Regular cleanup schedule**:
   - Weekly: `docker system prune -f`
   - Monthly: Review and clean workspace projects
   - Quarterly: Deep clean with `docker system prune -a --volumes`

---

**Related Documentation:**
- [Quick Start Guide](QUICK_START.md) - Getting started with the container
- [Docker Setup Guide](DOCKER_SETUP.md) - Detailed Docker configuration
- [Security Overview](SECURITY.md) - Security features and best practices

**Need Help?** Open an issue on GitHub or check the main [README](../README.md) for support options.
