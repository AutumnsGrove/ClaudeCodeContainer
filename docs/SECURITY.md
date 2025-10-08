# Security Overview

## 🔒 Security Features

This Claude Code Container implementation prioritizes security through multiple layers of isolation and access control.

### File System Isolation

**What's Protected:**
- Your home directory remains untouched
- System files are completely isolated
- Claude Code can only access designated workspace folders

**Access Boundaries:**
```
Container Access:
✅ /workspace/Projects
✅ /workspace/Documentation  
✅ /workspace/Research
✅ /workspace/shared (bidirectional)
✅ /workspace/imports (read)
✅ /workspace/exports (write)

❌ Your home directory
❌ System directories
❌ Other applications' data
❌ Network shares (unless explicitly mounted)
```

### Container Security Settings

**Docker Implementation:**
- Runs with `no-new-privileges` flag
- Drops all Linux capabilities except essential ones
- Memory limited to 8GB (configurable)
- CPU limited to 4 cores (configurable)
- Non-root user by default

**Apple Virtualization Framework:**
- Full VM isolation
- Separate kernel space
- VirtioFS for controlled file sharing
- Network isolation with NAT

### Network Security

**Default Configuration:**
- Isolated network bridge (172.28.0.0/24)
- Internet access for package installation and Claude API
- No incoming connections allowed
- No access to local network services

**What Claude Code Can Access:**
- ✅ Internet (for API calls and package downloads)
- ✅ DNS resolution
- ❌ Local network devices
- ❌ Host machine services
- ❌ Other containers

### Data Persistence & Cleanup

**Persistence Model:**
- Work persists in `~/ClaudeCodeWorkspace`
- Container can be destroyed without losing data
- Volumes are named and managed separately
- Easy backup with single command

**Clean Deletion:**
```bash
# Remove container only (keeps data)
./manage.sh reset

# Remove container and images (keeps data)
./manage.sh clean

# Remove everything including data (requires confirmation)
./manage.sh destroy
```

## 🛡️ Best Practices

### 1. Regular Backups
```bash
# Create timestamped backup
./manage.sh backup
# Creates: ~/claude-workspace-YYYYMMDD-HHMMSS.tar.gz
```

### 2. Project Isolation
Keep different projects in separate folders:
```
/workspace/Projects/
├── client-work/      # Sensitive client data
├── personal/         # Personal projects
└── experiments/      # Testing and experiments
```

### 3. Sensitive Data Handling
- Never put credentials in `/workspace/shared`
- Use environment variables for API keys
- Keep secrets in `.env` files (git-ignored)
- Use the imports folder for one-time sensitive file transfers

### 4. Git Security
Inside the container:
```bash
# Use SSH keys for git
ssh-keygen -t ed25519 -C "container@claude-code"

# Configure git with container-specific identity
git config --global user.email "dev@container.local"
git config --global user.name "Claude Container Dev"
```

### 5. Network Services
If you need to expose services:
```yaml
# In docker-compose.yml, explicitly map ports:
ports:
  - "127.0.0.1:8080:8080"  # Local only
  # NOT: "8080:8080"       # This would expose to network
```

## 🔍 Audit Trail

### Container Logs
```bash
# View container activity
./manage.sh logs

# Docker logs location
docker inspect claude-code-env | grep LogPath
```

### File System Changes
```bash
# Inside container - see what's changed
find /workspace -type f -mtime -1  # Files modified in last day
```

### Resource Usage
```bash
# Monitor container resources
docker stats claude-code-env
```

## ⚠️ Security Considerations

### What This DOESN'T Protect Against:
1. **Malicious code execution** - If you run malicious code inside the container, it can still:
   - Delete files in /workspace
   - Make network requests
   - Consume resources

2. **Supply chain attacks** - Packages installed via pip/npm are not vetted

3. **Data exfiltration** - The container has internet access for Claude API

### Recommended Mitigations:

**For Highly Sensitive Work:**
1. Disable network access entirely:
   ```yaml
   # In docker-compose.yml
   network_mode: none
   ```

2. Use read-only mounts for sensitive data:
   ```yaml
   volumes:
     - ./sensitive-data:/workspace/data:ro
   ```

3. Run periodic security scans:
   ```bash
   # Scan for vulnerabilities
   docker scan claude-code-container:latest
   ```

## 🚨 Incident Response

### If Something Goes Wrong:

1. **Immediately stop the container:**
   ```bash
   ./manage.sh stop
   ```

2. **Backup current state for investigation:**
   ```bash
   ./manage.sh backup
   mv ~/claude-workspace-*.tar.gz ~/incident-backup.tar.gz
   ```

3. **Check logs:**
   ```bash
   ./manage.sh logs > incident-logs.txt
   ```

4. **Reset environment:**
   ```bash
   ./manage.sh clean
   ./setup.sh
   ```

## 📋 Security Checklist

Before starting work:
- [ ] Workspace directory has correct permissions (755)
- [ ] No sensitive files in shared folders
- [ ] Git configured with container-specific identity
- [ ] Recent backup exists

During work:
- [ ] Only install trusted packages
- [ ] Review code before execution
- [ ] Keep sensitive data in appropriate folders
- [ ] Use imports/exports for controlled file transfer

After work:
- [ ] Export important files
- [ ] Commit and push code changes
- [ ] Stop container when not in use
- [ ] Backup if significant changes made

## 🔐 Advanced Security Options

### Enable SELinux (Linux hosts)
```bash
# Add to docker run command
--security-opt label=level:s0:c100,c200
```

### Use secrets management
```bash
# Create secret
echo "my-api-key" | docker secret create claude_api_key -

# Use in container
docker service create --secret claude_api_key ...
```

### Network policies
```yaml
# Restrict to specific DNS
networks:
  claude-net:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: claude0
    ipam:
      config:
        - subnet: 172.28.0.0/24
          aux_addresses:
            dns: 172.28.0.253
```

---

**Security is a shared responsibility.** This container provides isolation and controls, but secure usage depends on following best practices and being mindful of what code you run and what data you expose.
