# Apple Container Framework - Comprehensive Research Report

## Executive Summary

Apple's Container Framework is a native macOS containerization solution written in Swift and optimized for Apple Silicon. Unlike traditional container solutions that use shared kernel containerization, Apple's approach runs each container in its own lightweight virtual machine, providing enhanced security through hardware-level isolation while maintaining sub-second start times.

**Key Repositories:**
- CLI Tool: https://github.com/apple/container
- Framework: https://github.com/apple/containerization

**Requirements:**
- Mac with Apple Silicon (M1/M2/M3/M4)
- macOS 26 (Tahoe) for full features
- macOS 15 (Sequoia) with limited networking
- Xcode 26 for development

---

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Architecture Overview](#architecture-overview)
3. [Basic Container Operations](#basic-container-operations)
4. [Building Images](#building-images)
5. [Volume Mounting & File Sharing](#volume-mounting--file-sharing)
6. [Networking Configuration](#networking-configuration)
7. [Resource Management](#resource-management)
8. [Advanced Features](#advanced-features)
9. [System Configuration](#system-configuration)
10. [Common Usage Patterns](#common-usage-patterns)
11. [API Documentation](#api-documentation)
12. [Best Practices](#best-practices)
13. [Limitations & Gotchas](#limitations--gotchas)
14. [Complete Command Reference](#complete-command-reference)

---

## Installation & Setup

### Installing the CLI Tool

**Method 1: From Official Release**
```bash
# Download signed installer from GitHub releases
# https://github.com/apple/container/releases

# Install by double-clicking the package file
# Enter administrator password when prompted
```

**Method 2: Building from Source**
```bash
# Clone the repository
git clone https://github.com/apple/container.git
cd container

# Build and test
make all test integration

# Install binaries
make install

# For release build
BUILD_CONFIGURATION=release make all test integration
BUILD_CONFIGURATION=release make install
```

**Important:** Avoid placing the project in `Documents` or `Desktop` directories due to a `vmnet` framework bug on macOS 26.

### Starting the Container System

```bash
# Start the container system (creates default network)
container system start

# Verify system is running
container system status

# Stop the system when done
container system stop
```

### Optional: Configure DNS

```bash
# Create local DNS resolver
sudo container system dns create test

# Set DNS domain
container system property set dns.domain test

# Now containers can be accessed by name
# e.g., http://my-web-server.test
```

### Upgrading

```bash
# Stop system
container system stop

# Uninstall keeping user data
uninstall-container.sh -k

# Install new version
# Then restart system
container system start
```

### Uninstallation

```bash
# Remove completely with user data
uninstall-container.sh -d

# Remove but keep user data
uninstall-container.sh -k
```

---

## Architecture Overview

### Core Components

1. **container CLI** - Main command-line interface for container management
2. **container-apiserver** - Central management service
3. **container-core-images** - XPC helper for image management
4. **container-network-vmnet** - XPC helper for network configuration
5. **container-runtime-linux** - Individual container runtime management
6. **vminitd** - Lightweight init system with gRPC API inside VMs

### Unique Architecture Features

- **VM-per-Container Isolation:** Each container runs in its own lightweight VM
- **Hardware-Level Security:** Eliminates shared attack surface between containers
- **Dedicated IP Addresses:** Every container gets its own IP address
- **Sub-Second Start Times:** Optimized Linux kernel and minimal root filesystem
- **Resource Efficiency:** Containers consume resources only when active
- **Zero Resource Usage:** When no containers run, no system resources consumed

### Technology Stack

- Written in Swift
- Uses Apple's Virtualization.framework
- Integrates with vmnet, XPC, and Launchd
- Supports OCI (Open Container Initiative) standards
- Uses Rosetta 2 for linux/amd64 containers on arm64

### Key Dependencies

From `Package.swift`:
- Swift Log (1.0.0+)
- Swift Argument Parser (1.3.0+)
- Swift Collections (1.2.0+)
- gRPC Swift (1.26.0+)
- Swift Protobuf (1.29.0+)
- Swift NIO (2.80.0+)
- Async HTTP Client (1.20.1+)
- DNS Client (2.4.1+)
- Containerization (0.9.1 exact)

---

## Basic Container Operations

### Running Containers

**Interactive Shell:**
```bash
# Run Alpine Linux with interactive shell
container run -it alpine:latest /bin/sh

# Shorter form
container run -it alpine /bin/sh
```

**Detached Mode (Background):**
```bash
# Run in background
container run -d --name web-server nginx:latest

# Run with auto-remove after exit
container run -d --rm --name temp-container alpine:latest

# Combine options
container run -itd --rm --name my-container alpine /bin/sh
```

**With Environment Variables:**
```bash
# Single environment variable
container run -e NODE_ENV=production node:18

# Multiple variables
container run \
  -e NODE_ENV=production \
  -e PORT=3000 \
  -e DEBUG=true \
  node:18

# From file
container run --env-file ./config.env node:18
```

**Format for env file (config.env):**
```bash
NODE_ENV=production
PORT=3000
DEBUG=true
# Comments are ignored
```

**With Custom Name:**
```bash
# Name your container for easy reference
container run --name my-web-server --detach --rm web-test
```

**With Arguments:**
```bash
# Pass arguments to container command
container run ubuntu:latest echo "Hello World"

# Run Python HTTP server
container run -d -p 8080:80 python:alpine \
  python3 -m http.server 80 --bind 0.0.0.0
```

### Listing Containers

```bash
# List running containers
container list
container ls  # shorthand

# List all containers (including stopped)
container list --all
container ls -a  # shorthand

# Example output:
# ID        IMAGE                    OS     ARCH   STATE    ADDR
# 180f989b  docker.io/library/alpine linux  arm64  running  192.168.64.2
# abc123de  nginx:latest             linux  arm64  stopped  -
```

### Executing Commands in Running Containers

```bash
# Execute command in running container
container exec <container-name> <command>

# Interactive shell
container exec -it my-web-server sh
container exec -it my-web-server bash

# Run specific command
container exec my-web-server ls -la /app
container exec my-web-server ps aux

# With custom working directory
container exec --workdir /app my-container npm test

# With custom user
container exec --user 1000:1000 my-container whoami

# With environment variables
container exec -e DEBUG=true my-container node app.js

# With environment file
container exec --env-file ./test.env my-container ./test.sh
```

### Viewing Container Logs

```bash
# View container logs
container logs my-web-server

# View boot logs
container logs --boot my-web-server

# System logs for debugging
container system logs

# Follow logs (real-time)
container logs -f my-web-server
```

### Inspecting Containers

```bash
# Get detailed information about container
container inspect my-web-server

# Inspect multiple containers
container inspect container1 container2
```

### Starting and Stopping Containers

```bash
# Start a stopped container
container start my-web-server

# Start with interactive attach
container start -it my-web-server

# Stop running container
container stop my-web-server

# Stop with custom timeout
container stop --timeout 30 my-web-server

# Stop all running containers
container stop --all

# Kill container (force stop)
container kill my-web-server

# Kill multiple containers
container kill container1 container2
```

### Deleting Containers

```bash
# Delete stopped container
container delete my-web-server
container rm my-web-server  # shorthand

# Delete multiple containers
container rm container1 container2

# Force delete running container
container rm -f my-web-server

# Auto-remove after container exits (use when running)
container run --rm alpine echo "temporary"
```

---

## Building Images

### Basic Build

```bash
# Build from Dockerfile in current directory
container build --tag my-app:latest .

# Build from specific Dockerfile
container build --file docker/Dockerfile.prod --tag my-app:prod .

# Build with custom context directory
container build --tag my-app /path/to/context
```

### Example Dockerfile

**Simple Web Server:**
```dockerfile
FROM docker.io/python:alpine
WORKDIR /content
RUN apk add curl
CMD ["python3", "-m", "http.server", "80", "--bind", "0.0.0.0"]
```

**Node.js Application:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**Multi-Stage Build:**
```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm install --production
CMD ["node", "dist/index.js"]
```

### Build with Arguments

```bash
# Pass build arguments
container build \
  --build-arg NODE_VERSION=18 \
  --build-arg ENV=production \
  --tag my-app .
```

**Dockerfile using build args:**
```dockerfile
ARG NODE_VERSION=16
FROM node:${NODE_VERSION}-alpine
ARG ENV=development
ENV NODE_ENV=${ENV}
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
```

### Multi-Platform Builds

```bash
# Build for multiple architectures
container build \
  --arch arm64 \
  --arch amd64 \
  --tag my-multi-arch-image .

# Build for specific platform
container build \
  --platform linux/arm64 \
  --tag my-app:arm64 .

# Use host architecture (default)
container build --arch $(uname -m) --tag my-app .
```

### Build Options

```bash
# Build specific stage from multi-stage Dockerfile
container build \
  --target production \
  --tag my-app:prod .

# Build without cache
container build --no-cache --tag my-app .

# Build with memory limit
container build --memory 4G --tag my-app .

# Build with custom CPU count
container build --cpus 4 --tag my-app .

# Custom output type
container build \
  --output type=oci \
  --tag my-app .

# Build with progress mode
container build \
  --progress auto \
  --tag my-app .
# Progress modes: auto, tty, plain
```

### Builder Management

The builder is a special container that handles image builds. It uses BuildKit internally.

```bash
# Start builder with default resources (2 CPUs, 2GB RAM)
container builder start

# Start with custom resources
container builder start --cpus 8 --memory 32g

# If builder already running, restart with new limits
container builder stop
container builder delete
container builder start --cpus 8 --memory 32g

# Check builder status
container builder list
```

### Working with Built Images

```bash
# List images
container image list
container image ls  # shorthand

# Tag an image
container image tag my-app:latest my-app:v1.0.0

# Push to registry
container image push registry.example.com/my-app:latest

# Pull from registry
container image pull nginx:latest

# Delete image
container image delete my-app:latest
container image rm my-app:latest  # shorthand

# Inspect image
container image inspect my-app:latest
```

---

## Volume Mounting & File Sharing

### Using --volume Flag

The `--volume` (or `-v`) flag allows you to mount directories from your Mac into containers.

**Basic Volume Mount:**
```bash
# Mount host directory to container path
container run \
  --volume ${HOME}/my-project:/app \
  my-image

# Mount with read-only access
container run \
  --volume ${HOME}/my-project:/app:ro \
  my-image

# Mount multiple volumes
container run \
  --volume ${HOME}/project:/app \
  --volume ${HOME}/data:/data \
  my-image
```

**Development Workflow Example:**
```bash
# Mount source code for live editing
container run -d \
  --name dev-server \
  --volume ${HOME}/workspace/myapp:/app \
  -p 3000:3000 \
  node:18 \
  sh -c "cd /app && npm run dev"

# Now edit files on Mac, changes reflect in container
```

**Database with Persistent Storage:**
```bash
# PostgreSQL with data persistence
container run -d \
  --name postgres-db \
  --volume ${HOME}/db-data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:latest

# Data survives container restarts
container stop postgres-db
container start postgres-db  # Data still there
```

### Using --mount Flag

The `--mount` flag provides more explicit syntax.

```bash
# Basic mount
container run -it --rm \
  --mount source=${HOME}/app/data,target=/app/data \
  alpine:latest

# Mount with type specified
container run \
  --mount type=bind,source=${HOME}/config,target=/etc/config \
  my-app

# Read-only mount
container run \
  --mount source=${HOME}/data,target=/data,readonly \
  my-app
```

### Common Volume Use Cases

**Sharing Assets Between Containers:**
```bash
# First container writes data
container run -d \
  --name writer \
  --volume ${HOME}/shared:/shared \
  alpine sh -c "echo 'data' > /shared/file.txt"

# Second container reads data
container run \
  --volume ${HOME}/shared:/shared \
  alpine cat /shared/file.txt
```

**Configuration Files:**
```bash
# Mount configuration directory
container run -d \
  --name nginx-server \
  --volume ${HOME}/nginx-config:/etc/nginx/conf.d:ro \
  -p 8080:80 \
  nginx:latest
```

**Log Collection:**
```bash
# Mount logs directory to host
container run -d \
  --name app-server \
  --volume ${HOME}/logs:/var/log/app \
  my-app
```

### Named Volumes

```bash
# Create a named volume
container volume create my-volume

# Use named volume
container run -d \
  --name app \
  --mount source=my-volume,target=/data \
  my-image

# List volumes
container volume list
container volume ls

# Inspect volume
container volume inspect my-volume

# Delete volume
container volume delete my-volume
container volume rm my-volume
```

### Volume Best Practices

1. **Privacy & Security:** Only mount necessary directories
   - Each container only accesses its required data
   - No shared VM means better isolation

2. **Performance:**
   - Volume mounts perform well due to VM architecture
   - Consider data locality for intensive I/O operations

3. **Path Specifications:**
   - Always use absolute paths
   - Environment variables like `${HOME}` work well

4. **Permissions:**
   - Be aware of file ownership inside containers
   - Use appropriate user/group settings with `--user` flag

---

## Networking Configuration

### Network Modes

**Default Network:**
When you start the container system, a default network is created automatically.

```bash
# Default network created on system start
container system start

# Containers attach to default network by default
container run -d --name web1 nginx:latest
```

### Creating Custom Networks

```bash
# Create isolated network
container network create foo

# Create network with custom settings
container network create \
  --driver bridge \
  my-network

# List networks
container network list
container network ls

# Example output:
# NETWORK  STATE    SUBNET
# default  running  192.168.64.0/24
# foo      running  192.168.65.0/24
```

### Using Custom Networks

```bash
# Run container on specific network
container run -d \
  --name web-server \
  --network foo \
  --rm \
  nginx:latest

# Multiple containers on same network can communicate
container run -d \
  --name app \
  --network foo \
  my-app

container run -d \
  --name db \
  --network foo \
  postgres:latest

# app can reach db at its container name or IP
```

### Network Isolation

Networks are isolated from each other by default.

```bash
# Create two isolated networks
container network create network-a
container network create network-b

# Containers on network-a
container run -d --name app1 --network network-a alpine
container run -d --name app2 --network network-a alpine

# Container on network-b
container run -d --name app3 --network network-b alpine

# app1 and app2 can communicate
# app3 is isolated from app1 and app2
```

### Port Publishing

Publish container ports to host:

```bash
# Publish single port
container run -d \
  --name web \
  -p 8080:80 \
  nginx:latest
# Access at http://localhost:8080

# Publish to specific host IP
container run -d \
  --name web \
  -p 127.0.0.1:8080:80 \
  nginx:latest

# Publish multiple ports
container run -d \
  --name app \
  -p 8080:80 \
  -p 8443:443 \
  my-web-app

# Publish with protocol
container run -d \
  -p 8080:80/tcp \
  -p 5000:5000/udp \
  my-app
```

### Socket Publishing

```bash
# Publish Unix socket from container to host
container run -d \
  --name app \
  --publish-socket /var/run/host.sock:/var/run/app.sock \
  my-app
```

### Accessing Containers

**By IP Address:**
```bash
# Get container IP from list
container list

# Example output shows IP:
# ID        IMAGE    STATE    ADDR
# abc123    nginx    running  192.168.64.3

# Access directly
open http://192.168.64.3
curl http://192.168.64.3
```

**By DNS Name:**
```bash
# Setup DNS (one-time)
sudo container system dns create test
container system property set dns.domain test

# Now access by name
open http://my-web-server.test
curl http://my-container.test
```

### Container-to-Container Communication

**On Same Network:**
```bash
# Create network
container network create app-network

# Start database
container run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:latest

# Start application (can reach db by name)
container run -d \
  --name webapp \
  --network app-network \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  my-webapp
```

**Multi-Container Application Example:**
```bash
# Backend network
container network create backend

# Frontend network
container network create frontend

# Database (backend only)
container run -d \
  --name db \
  --network backend \
  postgres:latest

# API server (both networks)
container run -d \
  --name api \
  --network backend \
  -p 3000:3000 \
  my-api

# Web server (frontend only)
container run -d \
  --name web \
  --network frontend \
  -p 8080:80 \
  nginx:latest
```

### Network Management

```bash
# Inspect network
container network inspect foo

# Delete network (must have no containers attached)
container network delete foo
container network rm foo

# Connect running container to network
container network connect foo my-container

# Disconnect container from network
container network disconnect foo my-container
```

### macOS Version Differences

**macOS 26 (Tahoe) - Full Support:**
- Container-to-container communication works
- Full network isolation
- All networking features available

**macOS 15 (Sequoia) - Limited Support:**
- Containers isolated from each other (no communication)
- Container IPs not reachable from host
- Cannot use `--network` option (error)
- All containers attach to default vmnet network

```bash
# On macOS 15, this will error:
container run --network custom nginx  # ERROR

# Only default network works:
container run nginx  # Works, uses default network
```

---

## Resource Management

### Container Resource Limits

**CPU Limits:**
```bash
# Limit to specific number of CPUs
container run --cpus 2 my-app

# Examples
container run --cpus 4 --name worker my-worker-app
container run -c 8 nginx  # -c is shorthand
```

**Memory Limits:**
```bash
# Set memory limit (various units supported)
container run --memory 1G my-app
container run --memory 512M my-app
container run -m 2G my-app  # -m is shorthand

# Examples with units
container run -m 256M alpine  # 256 megabytes
container run -m 1G postgres  # 1 gigabyte
container run -m 4096M node   # 4 gigabytes
```

**Combined Resource Limits:**
```bash
# Production application
container run \
  --cpus 4 \
  --memory 8G \
  --name prod-app \
  my-production-app

# Development environment
container run \
  --cpus 2 \
  --memory 1G \
  --name dev-app \
  my-app

# Heavy computation
container run \
  --cpus 8 \
  --memory 32G \
  --name big-compute \
  compute-intensive-app
```

### Default Resource Allocations

**Default Container Resources:**
- **CPUs:** 4 cores
- **Memory:** 1 GB

**Default Builder Resources:**
- **CPUs:** 2 cores
- **Memory:** 2 GB

### Builder Resource Configuration

For resource-intensive builds:

```bash
# Check current builder
container builder list

# Stop and reconfigure builder
container builder stop
container builder delete

# Start with more resources
container builder start --cpus 8 --memory 32g

# Now builds have access to more resources
container build --tag my-large-app .
```

### Monitoring Resource Usage

```bash
# View running containers and their allocations
container list

# Inspect specific container for details
container inspect my-container

# System logs for resource-related issues
container system logs
```

### Resource Management Examples

**Database Server:**
```bash
# PostgreSQL with adequate resources
container run -d \
  --name postgres \
  --cpus 4 \
  --memory 4G \
  -v ${HOME}/postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=secret \
  postgres:latest
```

**Web Server (Low Resources):**
```bash
# Nginx needs minimal resources
container run -d \
  --name nginx \
  --cpus 1 \
  --memory 256M \
  -p 8080:80 \
  nginx:latest
```

**Build Process:**
```bash
# Reconfigure builder for large build
container builder stop
container builder start --cpus 8 --memory 16g

# Build large application
container build \
  --memory 4G \
  --cpus 4 \
  --tag my-large-image .
```

**Machine Learning Workload:**
```bash
# ML training with high resources
container run \
  --cpus 8 \
  --memory 16G \
  --volume ${HOME}/ml-data:/data \
  --volume ${HOME}/ml-models:/models \
  tensorflow/tensorflow:latest \
  python train.py
```

### Resource Efficiency Features

1. **Zero Consumption When Idle:**
   - Stopped containers consume no resources
   - No background VM when no containers running

2. **Per-Container VMs:**
   - Each container has dedicated resources
   - No resource sharing or contention between containers

3. **Fast Cleanup:**
   - Stopping container immediately releases resources
   - Deleting container fully reclaims all allocated resources

---

## Advanced Features

### SSH Agent Mounting

Mount your SSH authentication into containers for Git operations:

```bash
# Mount SSH agent and keys
container run -d \
  --name dev-container \
  --ssh \
  --volume ${HOME}/workspace:/workspace \
  node:18

# Now can git clone private repos inside container
container exec dev-container git clone git@github.com:user/private-repo.git
```

### Nested Virtualization

Enable KVM inside containers for nested virtualization:

```bash
# Requires kernel with virtualization support
container run \
  --name nested-vm \
  --virtualization \
  --kernel /path/to/kernel/with/kvm/support \
  --rm \
  ubuntu:latest \
  sh -c "dmesg | grep kvm"
```

### Rosetta 2 for x86_64 Emulation

Run x86_64 containers on Apple Silicon:

```bash
# Build for amd64 architecture (uses Rosetta 2)
container build \
  --arch amd64 \
  --tag my-app:amd64 .

# Run amd64 image on arm64 Mac
container run my-app:amd64

# Multi-architecture build
container build \
  --arch arm64 \
  --arch amd64 \
  --tag my-app:multi .
```

### CID File Generation

Save container ID to file:

```bash
# Write container ID to file
container run -d \
  --cidfile /tmp/container.cid \
  --name my-app \
  nginx:latest

# Read container ID
cat /tmp/container.cid
# Output: abc123def456...

# Use in scripts
CID=$(cat /tmp/container.cid)
container stop $CID
```

### Signal Handling

Containers properly handle SIGINT and SIGTERM:

```bash
# Run in foreground (Ctrl+C sends SIGINT)
container run my-app

# Graceful shutdown on stop (SIGTERM, then SIGKILL after timeout)
container stop --timeout 30 my-app
```

### Interactive TTY Management

```bash
# Full interactive terminal with TTY
container run -it alpine sh

# Interactive but no TTY (for piping)
container run -i alpine sh < script.sh

# TTY without interactive (rare)
container run -t alpine sh
```

### Working Directory Override

```bash
# Run command in specific directory
container exec \
  --workdir /app/tests \
  my-container \
  npm test

# Run container with custom workdir
container run \
  --workdir /data \
  -v ${HOME}/data:/data \
  alpine \
  ls -la
```

### User and Group Context

```bash
# Run as specific user
container exec \
  --user 1000:1000 \
  my-container \
  whoami

# Run container as non-root user
container run \
  --user node \
  node:18 \
  node --version
```

### Registry Authentication

```bash
# Login to private registry
container registry login registry.example.com

# Login with credentials
container registry login \
  --username myuser \
  --password-stdin \
  registry.example.com < password.txt

# Logout
container registry logout registry.example.com

# List configured registries
container registry list
```

### Image Import/Export

```bash
# Save image to tar file
container image save my-app:latest -o my-app.tar

# Load image from tar file
container image load -i my-app.tar

# Export container filesystem
container export my-container -o container-fs.tar
```

---

## System Configuration

### System Properties

View and modify system-wide settings:

```bash
# List all system properties
container system property list

# Example output:
# build.rosetta  Bool  true    Build amd64 images on arm64 using Rosetta
# dns.domain     String *undefined* If defined, the local DNS domain to use
```

### Setting Properties

```bash
# Disable Rosetta for builds
container system property set build.rosetta false

# Set DNS domain
container system property set dns.domain local

# Enable a feature
container system property set some.feature true
```

### DNS Configuration

```bash
# Create DNS resolver
sudo container system dns create mynet

# Set as default
container system dns default set mynet

# List DNS resolvers
container system dns list

# Delete DNS resolver
sudo container system dns delete mynet
```

### System Logs

```bash
# View system component logs
container system logs

# Useful for debugging:
# - container-apiserver issues
# - XPC helper problems
# - Network configuration errors
# - Image management issues
```

### System Status

```bash
# Check if system is running
container system status

# View system information
container system info
```

---

## Common Usage Patterns

### 1. Simple Web Server

```bash
# Python HTTP server
container run -d \
  --name web-server \
  -p 8080:80 \
  --volume ${HOME}/website:/content \
  python:alpine \
  sh -c "cd /content && python3 -m http.server 80 --bind 0.0.0.0"

# Access at http://localhost:8080
```

### 2. Database Development Setup

```bash
# PostgreSQL
container run -d \
  --name postgres-dev \
  -e POSTGRES_PASSWORD=devpass \
  -e POSTGRES_DB=myapp \
  --volume ${HOME}/pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:latest

# Connect from host
psql -h localhost -U postgres -d myapp
```

### 3. Node.js Development

```bash
# Development server with live reload
container run -d \
  --name node-dev \
  --volume ${HOME}/myapp:/app \
  -p 3000:3000 \
  -e NODE_ENV=development \
  node:18 \
  sh -c "cd /app && npm install && npm run dev"

# View logs
container logs -f node-dev

# Execute commands
container exec node-dev npm test
```

### 4. Multi-Container Application

```bash
# Create network
container network create myapp-net

# Database
container run -d \
  --name db \
  --network myapp-net \
  -e POSTGRES_PASSWORD=secret \
  -v ${HOME}/db-data:/var/lib/postgresql/data \
  postgres:latest

# Backend API
container run -d \
  --name api \
  --network myapp-net \
  -e DB_HOST=db \
  -e DB_PASSWORD=secret \
  -p 3000:3000 \
  my-api:latest

# Frontend
container run -d \
  --name web \
  --network myapp-net \
  -p 8080:80 \
  my-frontend:latest
```

### 5. Build and Test Pipeline

```bash
# Build image
container build -t myapp:test .

# Run tests
container run --rm \
  --name test-runner \
  myapp:test \
  npm test

# If tests pass, tag for production
container image tag myapp:test myapp:prod

# Push to registry
container image push registry.example.com/myapp:prod
```

### 6. Temporary Task Container

```bash
# Run one-off task and auto-remove
container run --rm \
  -v ${HOME}/data:/data \
  python:alpine \
  python -c "print('Processing data...')"

# Cleanup is automatic due to --rm
```

### 7. Shell Access for Debugging

```bash
# Start container in background
container run -d --name myapp myapp:latest

# Get shell access
container exec -it myapp sh

# Debug inside container
ps aux
ls -la /app
cat /var/log/app.log
exit

# Stop when done
container stop myapp
```

### 8. Configuration Hot-Reload

```bash
# Mount config directory
container run -d \
  --name nginx \
  -v ${HOME}/nginx-conf:/etc/nginx/conf.d:ro \
  -p 8080:80 \
  nginx:latest

# Edit config on host
vim ${HOME}/nginx-conf/default.conf

# Reload nginx
container exec nginx nginx -s reload
```

### 9. Data Processing Pipeline

```bash
# Process data with mounted volumes
container run --rm \
  --name processor \
  -v ${HOME}/input:/input:ro \
  -v ${HOME}/output:/output \
  my-processor:latest \
  process --input /input --output /output
```

### 10. Development Environment

```bash
# Full development environment
container run -it \
  --name devenv \
  --volume ${HOME}/workspace:/workspace \
  --volume ${HOME}/.ssh:/root/.ssh:ro \
  --ssh \
  -p 8080:8080 \
  --cpus 4 \
  --memory 4G \
  my-devenv:latest \
  zsh
```

---

## API Documentation

### Containerization Swift Package

The underlying framework is available as a Swift package for programmatic use.

**Repository:** https://github.com/apple/containerization

**Documentation:** https://apple.github.io/containerization/documentation/

### Key Modules

Based on source structure:

1. **Containerization** - Core containerization APIs
2. **ContainerizationOCI** - OCI image and runtime spec handling
3. **ContainerizationArchive** - Archive/tar operations
4. **ContainerizationEXT4** - ext4 filesystem creation
5. **ContainerizationNetlink** - Network configuration via netlink
6. **ContainerizationIO** - I/O operations for containers
7. **ContainerizationOS** - OS-level interactions
8. **ContainerizationError** - Error types and handling
9. **ContainerizationExtras** - Utility functions

### Using in Swift Projects

**Package.swift:**
```swift
dependencies: [
    .package(
        url: "https://github.com/apple/containerization",
        .upToNextMinorVersion(from: "0.1.0")
    )
]
```

### Example Tool: cctl

The `cctl` tool in the containerization repo demonstrates API usage:

**Commands Available:**
- `cctl image` - Manipulate OCI images
- `cctl login` - Login to container registries
- `cctl rootfs` - Create root filesystems
- `cctl kernel` - Work with Linux kernels
- `cctl run` - Run Linux containers

**Building cctl:**
```bash
cd containerization
make all
make test integration

# Run cctl
.build/debug/cctl --help
```

### API Capabilities

The Containerization package provides APIs to:

1. **Manage OCI Images:**
   - Pull from registries
   - Push to registries
   - Inspect image manifests
   - Extract layers

2. **Container Registry Interaction:**
   - Authentication
   - Image discovery
   - Blob operations

3. **Filesystem Operations:**
   - Create ext4 filesystems
   - Mount operations
   - File extraction from images

4. **Network Configuration:**
   - Netlink socket interaction
   - Network interface setup
   - IP address management

5. **VM Management:**
   - Spawn lightweight VMs
   - Configure VM resources
   - Manage VM lifecycle

6. **Process Execution:**
   - Run containerized processes
   - Manage process I/O
   - Handle signals

7. **Linux Kernel:**
   - Create optimized kernels
   - Configure kernel parameters
   - Boot kernel in VM

---

## Best Practices

### 1. Resource Allocation

**Do:**
- Set appropriate CPU and memory limits for each container
- Configure builder resources for large builds
- Monitor resource usage during development

**Don't:**
- Over-allocate resources (wastes Mac system resources)
- Under-allocate for production workloads (causes performance issues)

```bash
# Good: Sized for workload
container run --cpus 2 --memory 1G my-app

# Bad: Excessive allocation
container run --cpus 16 --memory 64G simple-app
```

### 2. Volume Mounting

**Do:**
- Mount only necessary directories
- Use absolute paths
- Use read-only mounts for configuration

**Don't:**
- Mount entire home directory unnecessarily
- Mount system directories
- Use relative paths

```bash
# Good: Specific directory
container run -v ${HOME}/myapp:/app my-image

# Bad: Too broad
container run -v ${HOME}:/home my-image
```

### 3. Networking

**Do:**
- Create separate networks for isolation
- Use meaningful network names
- Configure DNS for convenience
- Use macOS 26 for full features

**Don't:**
- Put unrelated containers on same network
- Rely on networking features in macOS 15

```bash
# Good: Isolated networks
container network create frontend
container network create backend
container run --network frontend web-app
container run --network backend database

# Bad: Everything on default
container run app1
container run app2
container run db
```

### 4. Container Lifecycle

**Do:**
- Use `--rm` for temporary containers
- Name containers meaningfully
- Clean up stopped containers regularly

**Don't:**
- Leave many stopped containers
- Use random/unclear names
- Forget to remove test containers

```bash
# Good: Auto-cleanup temporary work
container run --rm -v ${HOME}/data:/data processor

# Good: Clear naming
container run --name prod-api-server api:latest

# Bad: Unclear names
container run --name c1 api:latest
```

### 5. Image Building

**Do:**
- Use multi-stage builds for smaller images
- Configure builder resources appropriately
- Tag images meaningfully
- Use .dockerignore to exclude files

**Don't:**
- Build with default resources for large projects
- Use only `latest` tag
- Include unnecessary files in context

```bash
# Good: Proper tagging
container build -t myapp:v1.2.3 .
container build -t myapp:prod .

# Bad: Unclear versions
container build -t myapp .
```

### 6. Security

**Do:**
- Run containers as non-root when possible
- Use read-only mounts for sensitive data
- Keep images updated
- Review image contents before running

**Don't:**
- Mount SSH keys as read-write
- Run everything as root
- Trust unknown images

```bash
# Good: Read-only sensitive files
container run -v ${HOME}/.ssh:/root/.ssh:ro my-app

# Good: Non-root user
container run --user 1000:1000 my-app
```

### 7. Development Workflow

**Do:**
- Use volume mounts for live code editing
- Configure appropriate resources for dev
- Use meaningful container names
- Leverage logs for debugging

**Don't:**
- Rebuild images for every code change
- Over-provision dev resources
- Ignore container logs

```bash
# Good: Development setup
container run -d \
  --name myapp-dev \
  -v ${HOME}/workspace/myapp:/app \
  --cpus 2 \
  --memory 2G \
  myapp-dev:latest

# View logs during development
container logs -f myapp-dev
```

### 8. System Maintenance

**Do:**
- Restart system service after macOS updates
- Clean up unused images periodically
- Monitor system logs for issues
- Keep container CLI updated

**Don't:**
- Ignore system errors
- Accumulate unused images
- Run old CLI versions

```bash
# Regular cleanup
container system stop
container image prune
container system start

# Check for issues
container system logs
```

---

## Limitations & Gotchas

### Platform Limitations

**macOS Version Requirements:**
- **macOS 26 (Tahoe):** Full feature support, recommended
- **macOS 15 (Sequoia):** Limited networking, reduced functionality
- **Older versions:** Not supported

**Hardware Requirements:**
- **Apple Silicon only:** M1/M2/M3/M4 required
- **Intel Macs:** Not supported

### Networking Limitations

**macOS 15 Specific:**
- Container-to-container communication does NOT work
- Container IPs not reachable from host machine
- Cannot use `--network` flag (will error)
- All containers forced to default isolated vmnet
- Only way for communication is through host port forwarding

```bash
# On macOS 15 - this fails:
container run --network custom nginx  # ERROR

# Workaround - port forwarding through host:
container run -p 8080:80 app1
container run -p 8081:80 app2
# Both accessible from host, but not each other
```

**General Networking:**
- No direct container-to-host networking without port publishing
- Each container in its own network namespace (VM)
- Cannot share network between multiple containers easily

### Resource Management

**Memory:**
- Limited memory release back to macOS until container stops
- Memory allocations are fixed at container start
- Cannot dynamically resize while running

**CPU:**
- CPU allocation fixed at container start
- Cannot change CPU count for running container

```bash
# Cannot do this for running container:
container update --cpus 8 running-container  # No such command

# Must stop and restart:
container stop running-container
container rm running-container
container run --cpus 8 --name running-container my-image
```

### Project Location

**Critical Issue on macOS 26:**
- Do NOT place project in `Documents` or `Desktop`
- vmnet framework bug causes issues
- Use other locations like `~/Projects` or `~/workspace`

```bash
# Bad - may cause vmnet issues:
cd ~/Documents/container-project

# Good - safe locations:
cd ~/Projects/container-project
cd ~/workspace/container-project
cd ~/Development/container-project
```

### Feature Completeness

**Currently Missing (as of v0.1.0):**
- No `docker-compose` equivalent
- Limited lifecycle events
- No `container stats` command
- No built-in log rotation
- No container restart policies
- No health checks
- No update command for running containers

**Builder Limitations:**
- Must restart builder to change resources
- Only one builder instance at a time
- Builder is a container itself (uses resources)

### Storage and Filesystem

**Limitations:**
- No automatic volume cleanup (manual deletion required)
- Limited filesystem driver options (primarily ext4)
- Cannot resize volumes dynamically
- No snapshot/backup features built-in

### Image Compatibility

**Generally Good:**
- OCI-compliant images work well
- Docker Hub images compatible
- Most standard registries supported

**Potential Issues:**
- Some x86_64 images may have issues with Rosetta 2
- Images with kernel dependencies may not work
- Privileged operations not supported the same way

### Performance Considerations

**Pros:**
- Fast startup (sub-second)
- Efficient when containers are running
- No overhead when stopped

**Cons:**
- Each container needs VM overhead (small but present)
- More memory per container than shared-kernel solutions
- Network performance may differ from native Docker

### Security Implications

**Pros:**
- Strong isolation (VM per container)
- Reduced attack surface between containers
- Better privacy (selective mounting)

**Cons:**
- Cannot use traditional container security tools the same way
- Different threat model than standard containers
- Must understand VM security in addition to container security

### Development Workflow Differences

**From Docker:**
- Commands are similar but not identical
- Some docker-compose features missing
- Different networking model
- Must adapt scripts and tooling

**Integration:**
- Not a drop-in Docker replacement
- May need to run both Docker Desktop and Container
- CI/CD pipelines may need adjustments

### Stability and Breaking Changes

**Current Status:**
- Version 0.1.0 - initial release
- Active development
- Breaking changes possible before 1.0.0
- Source stability only within minor versions

**Recommendation:**
```swift
// Pin to minor version in Package.swift
.package(
    url: "https://github.com/apple/containerization",
    .upToNextMinorVersion(from: "0.1.0")
)
```

### Error Messages and Debugging

**Common Issues:**
- Cryptic error messages (improving)
- Limited documentation for errors
- System logs required for deep debugging

```bash
# When things go wrong:
container system logs  # Check this first
container inspect my-container  # Get detailed state
container system status  # Verify system health
```

### Workarounds

**For Container Communication on macOS 15:**
```bash
# Use socat for port forwarding
socat TCP-LISTEN:8000,fork,bind=192.168.64.1 TCP:127.0.0.1:8000
```

**For Missing docker-compose:**
- Write shell scripts to orchestrate containers
- Use make or other build tools
- Wait for future releases

**For Resource Changes:**
- Use container delete/recreate pattern
- Script common configurations
- Plan resource needs upfront

---

## Complete Command Reference

### Container Management

```bash
# Create container (without starting)
container create [OPTIONS] IMAGE [COMMAND] [ARG...]

# Run container (create and start)
container run [OPTIONS] IMAGE [COMMAND] [ARG...]
  -d, --detach              Run in background
  -i, --interactive         Keep STDIN open
  -t, --tty                 Allocate pseudo-TTY
  --rm, --remove            Remove container after it stops
  --name NAME               Assign name to container
  --network NETWORK         Connect to network
  -p, --publish SPEC        Publish port (host:container)
  --publish-socket SPEC     Publish socket
  -v, --volume SPEC         Mount volume
  --mount SPEC              Mount (explicit syntax)
  -e, --env KEY=VALUE       Set environment variable
  --env-file FILE           Read env vars from file
  --cpus COUNT              Number of CPUs
  -m, --memory SIZE         Memory limit (K/M/G/T/P)
  --user USER[:GROUP]       Run as user
  --workdir PATH            Working directory
  --ssh                     Mount SSH agent
  --virtualization          Enable nested virtualization
  --kernel PATH             Custom kernel path
  --cidfile FILE            Write container ID to file

# Start stopped container
container start [OPTIONS] CONTAINER [CONTAINER...]
  -i, --interactive         Attach STDIN
  -t, --tty                 Allocate TTY

# Stop running container
container stop [OPTIONS] CONTAINER [CONTAINER...]
  -t, --timeout SECONDS     Timeout before SIGKILL (default: 10)
  -a, --all                 Stop all running containers

# Restart container
container restart [OPTIONS] CONTAINER [CONTAINER...]

# Kill container (force stop)
container kill [OPTIONS] CONTAINER [CONTAINER...]
  -s, --signal SIGNAL       Signal to send (default: SIGKILL)

# Remove container
container delete [OPTIONS] CONTAINER [CONTAINER...]
container rm [OPTIONS] CONTAINER [CONTAINER...]  # Alias
  -f, --force               Force remove running container
  -v, --volumes             Remove associated volumes

# List containers
container list [OPTIONS]
container ls [OPTIONS]  # Alias
  -a, --all                 Show all (including stopped)
  -q, --quiet               Only display IDs
  --no-trunc                Don't truncate output

# Inspect container
container inspect CONTAINER [CONTAINER...]

# Execute command in container
container exec [OPTIONS] CONTAINER COMMAND [ARG...]
  -i, --interactive         Keep STDIN open
  -t, --tty                 Allocate TTY
  -e, --env KEY=VALUE       Set environment variable
  --env-file FILE           Read env vars from file
  --user USER[:GROUP]       Run as user
  --workdir PATH            Working directory

# View container logs
container logs [OPTIONS] CONTAINER
  -f, --follow              Follow log output
  --boot                    Show boot/init logs
  --tail N                  Show last N lines
```

### Image Management

```bash
# Build image
container build [OPTIONS] PATH
  -t, --tag NAME[:TAG]      Tag for image
  -f, --file FILE           Dockerfile path (default: Dockerfile)
  --arch ARCH               Target architecture (arm64/amd64)
  --platform PLATFORM       Target platform
  --build-arg KEY=VALUE     Build argument
  --target STAGE            Build specific stage
  --no-cache                Don't use cache
  --cpus COUNT              Builder CPUs
  --memory SIZE             Builder memory
  --output TYPE             Output type (oci/tar/local)
  --progress MODE           Progress mode (auto/tty/plain)

# List images
container image list [OPTIONS]
container image ls [OPTIONS]  # Alias
  -a, --all                 Show all images
  -q, --quiet               Only display IDs

# Inspect image
container image inspect IMAGE [IMAGE...]

# Pull image from registry
container image pull IMAGE

# Push image to registry
container image push IMAGE

# Tag image
container image tag SOURCE TARGET

# Remove image
container image delete IMAGE [IMAGE...]
container image rm IMAGE [IMAGE...]  # Alias
  -f, --force               Force removal

# Prune unused images
container image prune [OPTIONS]
  -a, --all                 Remove all unused images
  -f, --force               Don't prompt for confirmation

# Save image to tar
container image save IMAGE -o FILE

# Load image from tar
container image load -i FILE

# Export container filesystem
container export CONTAINER -o FILE
```

### Network Management

```bash
# Create network
container network create [OPTIONS] NETWORK
  --driver DRIVER           Network driver (default: bridge)

# List networks
container network list
container network ls  # Alias

# Inspect network
container network inspect NETWORK [NETWORK...]

# Remove network
container network delete NETWORK [NETWORK...]
container network rm NETWORK [NETWORK...]  # Alias

# Connect container to network
container network connect NETWORK CONTAINER

# Disconnect container from network
container network disconnect NETWORK CONTAINER
```

### Volume Management

```bash
# Create volume
container volume create [OPTIONS] [VOLUME]
  --driver DRIVER           Volume driver
  --opt KEY=VALUE           Driver-specific options

# List volumes
container volume list
container volume ls  # Alias

# Inspect volume
container volume inspect VOLUME [VOLUME...]

# Remove volume
container volume delete VOLUME [VOLUME...]
container volume rm VOLUME [VOLUME...]  # Alias

# Prune unused volumes
container volume prune
  -f, --force               Don't prompt for confirmation
```

### Registry Operations

```bash
# Login to registry
container registry login [OPTIONS] [SERVER]
  -u, --username USERNAME   Username
  -p, --password PASSWORD   Password
  --password-stdin          Read password from stdin

# Logout from registry
container registry logout [SERVER]

# List configured registries
container registry list
container registry ls  # Alias
```

### Builder Management

```bash
# Start builder
container builder start [OPTIONS]
  --cpus COUNT              Builder CPUs (default: 2)
  --memory SIZE             Builder memory (default: 2G)

# Stop builder
container builder stop

# Delete builder
container builder delete
container builder rm  # Alias

# List builders
container builder list
container builder ls  # Alias

# Inspect builder
container builder inspect
```

### System Operations

```bash
# Start container system
container system start

# Stop container system
container system stop

# Show system status
container system status

# Show system information
container system info

# View system logs
container system logs

# List system properties
container system property list

# Set system property
container system property set KEY VALUE

# Create DNS resolver
container system dns create NAME

# Delete DNS resolver
container system dns delete NAME

# Set default DNS resolver
container system dns default set NAME

# List DNS resolvers
container system dns list
```

### Global Options

```bash
# Available for most commands
--help                      Show help
--version                   Show version
-q, --quiet                 Suppress output
-v, --verbose               Verbose output
--generate-completion-script SHELL  # Generate completion (zsh/bash/fish)
```

### Shell Completion

```bash
# Generate completion script
container --generate-completion-script bash > /usr/local/etc/bash_completion.d/container
container --generate-completion-script zsh > /usr/local/share/zsh/site-functions/_container
container --generate-completion-script fish > ~/.config/fish/completions/container.fish
```

---

## Example Workflows

### Complete Web Application Workflow

```bash
# 1. Setup
container system start
container network create app-network
sudo container system dns create myapp
container system property set dns.domain myapp

# 2. Start database
container run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  -v ${HOME}/app-data/postgres:/var/lib/postgresql/data \
  postgres:latest

# 3. Build backend
cd backend
container build -t myapp-api:latest .

# 4. Start backend
container run -d \
  --name api \
  --network app-network \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=secret \
  --cpus 2 \
  --memory 2G \
  myapp-api:latest

# 5. Build frontend
cd ../frontend
container build -t myapp-web:latest .

# 6. Start frontend
container run -d \
  --name web \
  --network app-network \
  -e API_URL=http://api:3000 \
  -p 8080:80 \
  myapp-web:latest

# 7. Access application
open http://web.myapp

# 8. Monitor
container logs -f api
container logs -f web

# 9. Update code (backend)
cd backend
# Make changes...
container build -t myapp-api:latest .
container stop api
container rm api
container run -d \
  --name api \
  --network app-network \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=secret \
  myapp-api:latest

# 10. Cleanup
container stop web api postgres
container rm web api postgres
container network rm app-network
```

### Development Environment Workflow

```bash
# 1. Create dev network
container network create dev-network

# 2. Start services
container run -d \
  --name redis \
  --network dev-network \
  redis:alpine

container run -d \
  --name postgres \
  --network dev-network \
  -e POSTGRES_PASSWORD=dev \
  -v ${HOME}/dev-data/postgres:/var/lib/postgresql/data \
  postgres:latest

# 3. Start app in dev mode (with volume mount)
container run -d \
  --name myapp-dev \
  --network dev-network \
  -v ${HOME}/workspace/myapp:/app \
  -e NODE_ENV=development \
  -e REDIS_URL=redis://redis:6379 \
  -e DATABASE_URL=postgresql://postgres:dev@postgres:5432/myapp \
  -p 3000:3000 \
  --cpus 4 \
  --memory 4G \
  node:18 \
  sh -c "cd /app && npm install && npm run dev"

# 4. Watch logs
container logs -f myapp-dev

# 5. Run tests
container exec myapp-dev npm test

# 6. Debug with shell
container exec -it myapp-dev sh

# 7. Cleanup when done
container stop myapp-dev redis postgres
container rm myapp-dev redis postgres
```

---

## Conclusion

Apple's Container Framework provides a native, Swift-based containerization solution for macOS that prioritizes security through VM-per-container isolation while maintaining performance with sub-second start times. While still in early development (v0.1.0), it offers a compelling alternative to traditional container solutions for Apple Silicon Macs.

**Key Strengths:**
- Enhanced security through hardware-level isolation
- Native macOS integration
- Optimized for Apple Silicon
- OCI-compliant
- Fast startup times
- Zero resource consumption when idle

**Current Limitations:**
- macOS 26 required for full features
- Missing some Docker features (compose, stats, etc.)
- Early stage with potential breaking changes
- Limited to Apple Silicon Macs

**Best For:**
- macOS-native development workflows
- Security-conscious deployments
- Apple Silicon optimization
- Integration with Apple ecosystem

**Not Yet Ready For:**
- Production orchestration (no Kubernetes support)
- Complex multi-container workflows (no compose yet)
- Intel Mac compatibility
- Drop-in Docker replacement

The framework shows great promise and is actively developed by Apple. As it matures towards v1.0.0, expect more features, better stability, and broader adoption in the macOS development community.

---

## Additional Resources

**Official Documentation:**
- Container CLI: https://github.com/apple/container
- Containerization Framework: https://github.com/apple/containerization
- Tutorial: https://github.com/apple/container/blob/main/docs/tutorial.md
- Technical Overview: https://github.com/apple/container/blob/main/docs/technical-overview.md
- Command Reference: https://github.com/apple/container/blob/main/docs/command-reference.md
- How-To Guides: https://github.com/apple/container/blob/main/docs/how-to.md

**Building from Source:**
- Build Instructions: https://github.com/apple/container/blob/main/BUILDING.md
- Contributing: https://github.com/apple/container/blob/main/CONTRIBUTING.md

**Community:**
- GitHub Issues: https://github.com/apple/container/issues
- GitHub Discussions: https://github.com/apple/container/discussions

---

*Report Generated: 2025-10-08*
*Framework Version: 0.1.0*
*CLI Version: Current as of report date*
