# Apple Container Framework Troubleshooting Guide

## Known Limitations

### Critical Limitations

1. **No Volume Support (v0.5.0)**
   - Bind mounts not implemented
   - Workaround: Use VirtioFS directly or switch to Colima/OrbStack

2. **macOS Version Restrictions**
   - macOS 15: Only basic network isolation
   - macOS 26: Required for full networking features
   - Solution: Upgrade to macOS 26 or use alternative solution

3. **Platform Restrictions**
   - Apple Silicon only (M1/M2/M3/M4)
   - No Intel Mac support
   - No workaround available

4. **Breaking Changes**
   - API changes between minor versions until 1.0
   - Solution: Pin to specific version in Package.swift

## Common Error Messages and Fixes

### Error: "Container system is not running"

**Symptom:**
```
Error: Container system is not running. Please run: container system start
```

**Solution:**
```bash
# Start the container system
container system start

# Verify it's running
container system status

# If it fails to start, check logs
container system logs
```

### Error: "Operation not permitted"

**Symptom:**
```
Error: failed to start container: Operation not permitted
```

**Causes and Solutions:**

1. **Missing entitlements:**
   ```bash
   # Check code signing
   codesign -d --entitlements - /usr/local/bin/container

   # Re-sign if needed
   sudo codesign --force --sign - /usr/local/bin/container
   ```

2. **System Integrity Protection:**
   ```bash
   # Check SIP status
   csrutil status

   # May need to disable (not recommended)
   # Boot to Recovery Mode, then:
   csrutil disable
   ```

3. **Permissions issue:**
   ```bash
   # Fix permissions
   sudo chmod 755 /usr/local/bin/container
   sudo chown root:wheel /usr/local/bin/container
   ```

### Error: "Transport became inactive"

**Symptom:**
```
Error: XPC connection error: transport became inactive
```

**Solution:**
```bash
# Restart the API server
container system stop
container system start

# If persists, reinstall helpers
sudo make install

# Check launchd status
launchctl list | grep container
```

### Error: "SIGKILL during build"

**Symptom:**
```
Error: build failed: process killed with signal: SIGKILL
```

**Known Issue:** Random build failures in v0.5.0

**Workarounds:**
1. **Retry the build:**
   ```bash
   # Simple retry
   container build -t myimage . || container build -t myimage .
   ```

2. **Increase memory:**
   ```bash
   # Allocate more memory to builder
   container builder create --memory 8g
   container build -t myimage .
   ```

3. **Use alternative:**
   ```bash
   # Use Docker/Colima for builds
   docker build -t myimage .
   ```

### Error: "Failed to pull image"

**Symptom:**
```
Error: failed to pull image: no matching manifest
```

**Solutions:**

1. **Specify platform:**
   ```bash
   # For Apple Silicon
   container pull --platform linux/arm64 alpine:latest

   # For x86 emulation
   container pull --platform linux/amd64 alpine:latest
   ```

2. **Check registry access:**
   ```bash
   # Test connectivity
   curl -I https://registry-1.docker.io/v2/

   # Login if needed
   container registry login docker.io
   ```

3. **Clear image cache:**
   ```bash
   container system prune --all
   container pull alpine:latest
   ```

### Error: "Network creation failed"

**Symptom:**
```
Error: failed to create network: vmnet framework error
```

**Known Bug:** vmnet fails when project is in Documents/Desktop

**Solution:**
```bash
# Move project outside Documents/Desktop
cd ~
mkdir -p projects
mv ~/Documents/container ~/projects/
cd ~/projects/container

# Rebuild and reinstall
make clean
make all
sudo make install
```

### Error: "Container won't start"

**Symptom:**
Container created but fails to start

**Debugging Steps:**

1. **Check container logs:**
   ```bash
   container logs <container-id>
   ```

2. **Inspect container:**
   ```bash
   container inspect <container-id>
   ```

3. **Check system resources:**
   ```bash
   # Memory
   vm_stat

   # Disk space
   df -h

   # Process limits
   ulimit -a
   ```

4. **Try minimal configuration:**
   ```bash
   container run --rm alpine:latest echo "test"
   ```

### Error: "Race condition in ContainersService"

**Symptom:**
```
Error: concurrent map access in ContainersService
```

**Known Issue:** Race conditions in v0.5.0

**Workarounds:**
1. **Serialize operations:**
   ```bash
   # Don't run concurrent operations
   container stop container1 && container stop container2
   ```

2. **Add delays:**
   ```bash
   container start container1
   sleep 1
   container start container2
   ```

## Debugging Techniques

### Enable Debug Logging

```bash
# Set debug environment variable
export CONTAINER_LOG_LEVEL=debug

# Run with verbose output
container --verbose run alpine:latest

# Check system logs
log show --predicate 'subsystem == "com.apple.container"' --last 1h
```

### System Diagnostics

```bash
# Check container system health
container system info
container system status

# List running processes
ps aux | grep container

# Check XPC services
launchctl list | grep container

# View system logs
tail -f /var/log/container.log
```

### Container Diagnostics

```bash
# Get detailed container info
container inspect <container-id> | jq '.'

# Check resource usage
container stats <container-id>

# Access container filesystem
container exec <container-id> ls -la /

# Check network configuration
container exec <container-id> ip addr
container exec <container-id> route -n
```

### Network Debugging

```bash
# List networks
container network list

# Inspect network
container network inspect bridge

# Test connectivity
container run --rm alpine ping -c 3 8.8.8.8

# Check DNS
container run --rm alpine nslookup google.com

# Debug with tcpdump
container exec <container-id> tcpdump -i eth0
```

## Performance Considerations

### Memory Issues

**Problem:** Containers using too much memory

**Solutions:**
1. **Set memory limits:**
   ```bash
   container run --memory 512m alpine
   ```

2. **Monitor usage:**
   ```bash
   container stats --no-stream
   ```

3. **Clean up:**
   ```bash
   container system prune
   ```

### Slow Container Startup

**Problem:** Containers taking longer than expected to start

**Solutions:**
1. **Use local images:**
   ```bash
   container images  # Check what's available locally
   ```

2. **Pre-pull images:**
   ```bash
   container pull alpine:latest
   container pull ubuntu:latest
   ```

3. **Reduce image size:**
   ```dockerfile
   # Use alpine base
   FROM alpine:latest
   # Multi-stage builds
   ```

### File I/O Performance

**Problem:** Slow file operations in mounted directories

**Solutions:**
1. **Use VirtioFS (default in v0.5.0)**
2. **Limit mounted directories**
3. **Use volumes instead of bind mounts**
4. **Consider alternatives (OrbStack has better I/O)**

## Platform-Specific Gotchas

### macOS 15 Issues

1. **No container-to-container networking**
   - Containers can't communicate
   - Solution: Upgrade to macOS 26

2. **Single network only**
   - Can't create custom networks
   - Solution: Use default bridge network

3. **Limited network features**
   - No network isolation options
   - Solution: Use firewall rules

### macOS 26 Issues

1. **vmnet bug with Documents/Desktop**
   - Network creation fails
   - Solution: Move project elsewhere

2. **Rosetta 2 performance**
   - x86 containers slower
   - Solution: Use arm64 images

### Apple Silicon Specific

1. **Architecture mismatches**
   ```bash
   # Always specify platform
   container run --platform linux/arm64 image
   ```

2. **Missing x86 emulation**
   ```bash
   # Enable Rosetta 2
   softwareupdate --install-rosetta
   ```

## Known Bugs and Workarounds

### Bug: OCaml images hang (10+ minutes)

**Workaround:**
```bash
# Use Docker/Colima for OCaml
docker run ocaml/opam:alpine
```

### Bug: Memory not released after container stops

**Workaround:**
```bash
# Restart container system periodically
container system stop
container system start
```

### Bug: 16k file limit in containers

**Workaround:**
```bash
# Split large directories
# Use multiple volumes
# Consider alternatives
```

### Bug: Parallel layer downloads not working

**Impact:** Slow image pulls

**Workaround:**
```bash
# Pre-pull images during off-hours
# Use local registry mirror
```

## Alternative Solutions

### When to Switch to Alternatives

Consider switching if you encounter:
- Frequent SIGKILL errors
- Data corruption
- Unrecoverable system state
- Critical missing features
- Production deployment needs

### Quick Migration Guide

**To Colima:**
```bash
# Install
brew install colima docker

# Start
colima start --vm-type=vz

# Migrate containers
docker run <same-options-as-container>
```

**To OrbStack:**
```bash
# Install
brew install orbstack

# GUI starts automatically
# Use Docker CLI as normal
```

## Getting Help

### Resources

1. **GitHub Issues:**
   https://github.com/apple/container/issues

2. **Apple Developer Forums:**
   https://developer.apple.com/forums/

3. **Documentation:**
   https://apple.github.io/container/documentation/

4. **Source Code:**
   https://github.com/apple/container

### Reporting Issues

When reporting issues, include:
- macOS version
- Container framework version
- Hardware (Apple Silicon model)
- Steps to reproduce
- Error messages
- Container logs
- System diagnostics

### Community Workarounds

Check the GitHub issues for community-provided workarounds:
- Search closed issues for solutions
- Check pull requests for fixes
- Review discussions for alternatives

## Emergency Recovery

### System Won't Start

```bash
# Force stop all containers
sudo killall container-runtime-linux

# Clean up state
rm -rf ~/Library/Containers/com.apple.container.*

# Reinstall
sudo make uninstall
sudo make install

# Start fresh
container system start
```

### Complete Reset

```bash
# Stop everything
container system stop

# Remove all containers
container rm -f $(container list -aq)

# Remove all images
container image rm $(container image list -q)

# Remove all networks
container network rm $(container network list -q)

# Clean system
container system prune --all --volumes

# Restart
container system start
```

## Prevention Best Practices

1. **Regular Backups**
   - Backup container data
   - Export important images
   - Document configurations

2. **Monitoring**
   - Watch system resources
   - Monitor container health
   - Track error patterns

3. **Gradual Adoption**
   - Test thoroughly before production
   - Have fallback plans
   - Keep alternative ready

4. **Stay Updated**
   - Monitor GitHub releases
   - Read release notes carefully
   - Test updates in staging

## Conclusion

The Apple Container Framework (v0.5.0) has numerous issues and limitations. This guide provides workarounds for known problems, but for production use, consider mature alternatives like Colima or OrbStack until the framework reaches v1.0 stability.