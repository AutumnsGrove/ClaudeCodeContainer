# Apple Container Framework Implementation Guide

## Prerequisites and Setup

### System Requirements

Before starting, ensure your system meets these requirements:

- ✅ Apple Silicon Mac (M1/M2/M3/M4)
- ✅ macOS 15.0 minimum (macOS 26 recommended)
- ✅ Xcode 26 or later
- ✅ Swift 6.2 or later
- ✅ 16GB+ RAM recommended
- ✅ 50GB+ free disk space

### Installation Methods

#### Method 1: Install from Release (Recommended)

```bash
# Download the latest release
curl -L https://github.com/apple/container/releases/download/v0.5.0/container-0.5.0.pkg -o container.pkg

# Install the package
sudo installer -pkg container.pkg -target /

# Verify installation
container --version
```

#### Method 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/apple/container.git
cd container

# Build with Make
make all

# Run tests (optional)
make test

# Install to /usr/local
sudo make install

# Add to PATH if needed
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Initial Setup

```bash
# Start the container system
container system start

# Verify system is running
container system status

# Pull a test image
container pull alpine:latest

# Run a test container
container run --rm alpine echo "Setup complete!"
```

## Container Lifecycle

### Create → Start → Stop → Destroy

#### 1. Creating a Container

```bash
# Create without starting
container create --name mycontainer alpine:latest

# Create with custom configuration
container create \
  --name webserver \
  --hostname web1 \
  --env PORT=8080 \
  --env DEBUG=true \
  --cpus 2 \
  --memory 1g \
  nginx:latest
```

#### 2. Starting a Container

```bash
# Start a created container
container start mycontainer

# Start with attached output
container start --attach mycontainer

# Start multiple containers
container start container1 container2 container3
```

#### 3. Running Containers (Create + Start)

```bash
# Basic run
container run alpine:latest echo "Hello World"

# Interactive shell
container run -it alpine:latest /bin/sh

# Detached mode
container run -d --name webapp nginx:latest

# Auto-remove after exit
container run --rm alpine:latest ls -la
```

#### 4. Stopping Containers

```bash
# Graceful stop (SIGTERM)
container stop mycontainer

# Stop with timeout
container stop --time 30 mycontainer

# Stop multiple containers
container stop $(container list -q)
```

#### 5. Killing Containers (Force Stop)

```bash
# Force stop with SIGKILL
container kill mycontainer

# Send specific signal
container kill --signal SIGHUP mycontainer
```

#### 6. Removing Containers

```bash
# Remove stopped container
container rm mycontainer

# Force remove running container
container rm --force mycontainer

# Remove all stopped containers
container rm $(container list --all -q)
```

## Workspace Mounting and File Sharing

### Bind Mounts (Host Directories)

```bash
# Mount host directory to container
container run -v /path/on/host:/path/in/container alpine ls /path/in/container

# Read-only mount
container run -v /path/on/host:/data:ro alpine ls /data

# Multiple mounts
container run \
  -v ~/Documents:/documents:ro \
  -v ~/Downloads:/downloads \
  -v /tmp:/tmp \
  alpine ls /

# Development workflow
container run \
  -v $(pwd):/workspace \
  -w /workspace \
  node:latest npm install
```

### Named Volumes

```bash
# Create a volume
container volume create mydata

# Use volume in container
container run -v mydata:/data alpine sh -c "echo test > /data/file.txt"

# Share volume between containers
container run -d --name db -v mydata:/var/lib/postgresql postgres:latest
container run --rm -v mydata:/backup alpine tar czf /backup.tar.gz /backup

# List volumes
container volume list

# Inspect volume
container volume inspect mydata

# Remove volume
container volume rm mydata
```

### Advanced Mount Options

```bash
# Mount with specific options
container run \
  --mount type=bind,source=/host/path,target=/container/path,readonly \
  alpine ls /container/path

# Tmpfs mount (memory-backed)
container run \
  --mount type=tmpfs,target=/tmp,tmpfs-size=1g \
  alpine df -h /tmp

# SSH mount (remote directory)
container run \
  --mount type=ssh,target=/ssh \
  alpine ls /ssh
```

## Network Configuration

### Default Networking

```bash
# Containers get network by default
container run --rm alpine ping -c 3 google.com

# View container IP
container exec mycontainer ip addr show

# Container DNS works automatically
container run --rm alpine nslookup google.com
```

### Custom Networks (macOS 26 only)

```bash
# Create a custom network
container network create mynetwork

# Create with subnet
container network create --subnet 172.20.0.0/16 customnet

# Run container on network
container run --network mynetwork --name web nginx:latest

# Connect running container
container network connect mynetwork existing-container

# Disconnect from network
container network disconnect mynetwork existing-container

# List networks
container network list

# Inspect network
container network inspect mynetwork

# Remove network
container network rm mynetwork
```

### Port Mapping

```bash
# Map container port to host
container run -p 8080:80 nginx:latest

# Map to specific host IP
container run -p 127.0.0.1:8080:80 nginx:latest

# Map random host port
container run -p 80 nginx:latest

# Map multiple ports
container run \
  -p 8080:80 \
  -p 8443:443 \
  nginx:latest

# Map port range
container run -p 8000-8010:8000-8010 myapp:latest
```

### Container-to-Container Communication

```bash
# Create network
container network create webapp

# Run database
container run -d \
  --network webapp \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  postgres:latest

# Run application (can access postgres by name)
container run -d \
  --network webapp \
  --name app \
  -e DATABASE_URL=postgresql://postgres:5432/mydb \
  myapp:latest

# Verify connectivity
container exec app ping postgres
```

## Resource Limits

### CPU Limits

```bash
# Limit to 2 CPUs
container run --cpus 2 ubuntu:latest

# Limit to 50% of one CPU
container run --cpus 0.5 ubuntu:latest

# CPU shares (relative weight)
container run --cpu-shares 512 ubuntu:latest
```

### Memory Limits

```bash
# Limit to 1GB RAM
container run --memory 1g ubuntu:latest

# Memory + swap limit
container run --memory 1g --memory-swap 2g ubuntu:latest

# Memory reservation (soft limit)
container run --memory-reservation 512m ubuntu:latest
```

### Storage Limits

```bash
# Limit container disk size
container run --storage-size 10g ubuntu:latest

# Limit container layers size
container run --storage-opt size=5g ubuntu:latest
```

### Combined Limits

```bash
# Production container with all limits
container run -d \
  --name production-app \
  --cpus 4 \
  --memory 8g \
  --memory-swap 8g \
  --storage-size 20g \
  --restart unless-stopped \
  myapp:production
```

## Security Configuration

### User and Group

```bash
# Run as specific user
container run --user 1000:1000 alpine id

# Run as user by name
container run --user nobody alpine whoami

# Create user in Dockerfile
# FROM alpine
# RUN adduser -D myuser
# USER myuser
```

### Read-only Root Filesystem

```bash
# Make root filesystem read-only
container run --read-only alpine touch /test.txt  # This will fail

# With writable /tmp
container run \
  --read-only \
  --tmpfs /tmp \
  alpine sh -c "touch /tmp/test.txt && ls /tmp"
```

### Capabilities

```bash
# Drop all capabilities
container run --cap-drop ALL alpine

# Add specific capability
container run --cap-add SYS_ADMIN alpine

# Common secure configuration
container run \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --read-only \
  --user nobody \
  nginx:latest
```

### Security Options

```bash
# Disable new privileges
container run --security-opt no-new-privileges alpine

# Custom seccomp profile
container run --security-opt seccomp=/path/to/profile.json alpine
```

## Logging and Debugging

### View Container Logs

```bash
# View all logs
container logs mycontainer

# Follow logs (like tail -f)
container logs -f mycontainer

# View last N lines
container logs --tail 50 mycontainer

# Show timestamps
container logs -t mycontainer

# Since specific time
container logs --since 2024-01-01T00:00:00 mycontainer
container logs --since 10m mycontainer
```

### Debug Running Containers

```bash
# Execute shell in running container
container exec -it mycontainer /bin/sh

# Run command as root
container exec -u root mycontainer id

# Debug networking
container exec mycontainer ping google.com
container exec mycontainer netstat -tlpn
container exec mycontainer ss -tlpn

# Debug processes
container exec mycontainer ps aux
container exec mycontainer top

# Debug filesystem
container exec mycontainer df -h
container exec mycontainer du -sh /
```

### Container Inspection

```bash
# Full container details
container inspect mycontainer

# Format specific field
container inspect --format '{{.Config.Image}}' mycontainer

# Get IP address
container inspect --format '{{.NetworkSettings.IPAddress}}' mycontainer

# Get environment variables
container inspect --format '{{.Config.Env}}' mycontainer

# Get mounts
container inspect --format '{{.Mounts}}' mycontainer
```

### System Debugging

```bash
# Check system status
container system status

# View system logs
container system logs

# Clean up system
container system prune

# View disk usage
container system df

# System information
container system info
```

## Complete Minimal Working Example

### 1. Simple Web Server

```bash
#!/bin/bash
# webapp.sh - Complete web application example

# Create network
container network create webapp-net

# Start database
container run -d \
  --name webapp-db \
  --network webapp-net \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=app \
  -v webapp-data:/var/lib/postgresql/data \
  postgres:13

# Build application
cat > Dockerfile << 'EOF'
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

container build -t webapp:latest .

# Run application
container run -d \
  --name webapp \
  --network webapp-net \
  -p 3000:3000 \
  -e DATABASE_URL=postgresql://postgres:secret@webapp-db:5432/app \
  -e NODE_ENV=production \
  --restart unless-stopped \
  webapp:latest

# Check status
container logs webapp
container exec webapp-db psql -U postgres -c "\\l"

echo "Application running at http://localhost:3000"
```

### 2. Development Environment

```bash
#!/bin/bash
# devenv.sh - Development environment with hot reload

# Create development network
container network create dev-net

# Start services
container run -d \
  --name dev-redis \
  --network dev-net \
  redis:alpine

container run -d \
  --name dev-postgres \
  --network dev-net \
  -e POSTGRES_PASSWORD=dev \
  postgres:13

# Run development container with mounted code
container run -it --rm \
  --name dev-app \
  --network dev-net \
  -p 3000:3000 \
  -v $(pwd):/app \
  -w /app \
  -e REDIS_URL=redis://dev-redis:6379 \
  -e DATABASE_URL=postgresql://postgres:dev@dev-postgres:5432/dev \
  node:16 \
  sh -c "npm install && npm run dev"
```

### 3. Multi-Container Application

```yaml
# compose.yaml - Multi-container setup (manual orchestration)
# Note: No docker-compose equivalent yet, use script below
```

```bash
#!/bin/bash
# stack.sh - Deploy multi-container application

# Create network
container network create app-stack

# Start containers in order
echo "Starting database..."
container run -d \
  --name stack-db \
  --network app-stack \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=app \
  -v stack-mysql:/var/lib/mysql \
  mysql:8

echo "Waiting for database..."
sleep 10

echo "Starting cache..."
container run -d \
  --name stack-redis \
  --network app-stack \
  redis:alpine

echo "Starting application..."
container run -d \
  --name stack-app \
  --network app-stack \
  -p 8080:8080 \
  -e DB_HOST=stack-db \
  -e REDIS_HOST=stack-redis \
  --restart unless-stopped \
  myapp:latest

echo "Starting proxy..."
container run -d \
  --name stack-nginx \
  --network app-stack \
  -p 80:80 \
  -v ./nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

echo "Stack deployed!"
container list
```

## Best Practices

### Container Design

1. **One process per container** - Keep containers focused
2. **Use .dockerignore** - Exclude unnecessary files
3. **Layer caching** - Order Dockerfile commands for cache efficiency
4. **Multi-stage builds** - Reduce final image size
5. **Non-root user** - Run processes as non-privileged user
6. **Health checks** - Define readiness/liveness probes
7. **Graceful shutdown** - Handle SIGTERM properly

### Resource Management

1. **Always set limits** - CPU and memory constraints
2. **Use restart policies** - Handle failures automatically
3. **Clean up regularly** - Remove unused containers/images
4. **Monitor resources** - Track usage patterns
5. **Log rotation** - Prevent disk exhaustion

### Security

1. **Minimal base images** - Use alpine or distroless
2. **Scan for vulnerabilities** - Regular security updates
3. **Secrets management** - Never hardcode credentials
4. **Network isolation** - Use custom networks
5. **Read-only filesystems** - Where possible
6. **Drop capabilities** - Principle of least privilege

### Development Workflow

1. **Version control Dockerfiles** - Track changes
2. **Tag images properly** - Use semantic versioning
3. **Local development mirrors production** - Consistency
4. **Use volumes for development** - Hot reload
5. **Document container requirements** - README files

## Common Patterns

### Init Containers

```bash
# Run initialization before main container
container run --rm \
  -v app-data:/data \
  alpine sh -c "mkdir -p /data/config && echo 'initialized' > /data/config/init"

container run -d \
  -v app-data:/data \
  myapp:latest
```

### Sidecar Containers

```bash
# Main application
container run -d \
  --name app \
  --network mynet \
  -v logs:/var/log \
  myapp:latest

# Log collector sidecar
container run -d \
  --name log-collector \
  --network mynet \
  -v logs:/logs:ro \
  fluentd:latest
```

### Data Container Pattern

```bash
# Create data container
container create \
  --name data \
  -v /data \
  alpine

# Use volumes from data container
container run --rm \
  --volumes-from data \
  ubuntu ls /data
```

## Migration from Docker

### Command Mapping

| Docker Command | Container Command |
|---------------|------------------|
| `docker run` | `container run` |
| `docker ps` | `container list` |
| `docker images` | `container image list` |
| `docker build` | `container build` |
| `docker exec` | `container exec` |
| `docker logs` | `container logs` |
| `docker stop` | `container stop` |
| `docker rm` | `container rm` |
| `docker pull` | `container pull` |
| `docker push` | `container push` |

### Key Differences

1. **No docker-compose** - Use scripts for orchestration
2. **Limited networking on macOS 15** - Upgrade to macOS 26
3. **No swarm mode** - Single-host only
4. **Different plugin system** - Swift-based plugins
5. **VM isolation** - Higher memory usage

## Troubleshooting Common Issues

### Container Won't Start

```bash
# Check logs
container logs mycontainer

# Inspect configuration
container inspect mycontainer

# Verify image exists
container image list

# Check system status
container system status
```

### Network Issues

```bash
# On macOS 15: Limited to network isolation only
# Solution: Upgrade to macOS 26

# Debug DNS
container exec mycontainer nslookup google.com

# Check network configuration
container network inspect bridge
```

### Performance Issues

```bash
# Check resource usage
container stats

# Increase limits
container update --cpus 4 --memory 8g mycontainer

# Use native arm64 images on Apple Silicon
container run --platform linux/arm64 myimage
```

## Next Steps

1. **Read API Reference** - For programmatic usage
2. **Review Examples** - More complex scenarios
3. **Check Troubleshooting** - Common problems and solutions
4. **Monitor GitHub** - For updates and issues
5. **Join Community** - Apple Developer Forums

## Important Notes

⚠️ **Framework is pre-1.0** - Expect breaking changes
⚠️ **macOS 26 recommended** - Full feature support
⚠️ **Production use not advised** - Wait for 1.0 release
⚠️ **Alternative: Use OrbStack or Colima** - Production ready today