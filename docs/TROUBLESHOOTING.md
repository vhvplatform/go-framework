# Troubleshooting Guide

Common issues and solutions for the go-framework development environment.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Docker Issues](#docker-issues)
- [Service Issues](#service-issues)
- [Database Issues](#database-issues)
- [Network and Port Issues](#network-and-port-issues)
- [Build and Compilation Issues](#build-and-compilation-issues)
- [macOS Specific Issues](#macos-specific-issues)
- [Linux Specific Issues](#linux-specific-issues)
- [Windows/WSL2 Specific Issues](#windowswsl2-specific-issues)
- [Performance Issues](#performance-issues)
- [Getting Help](#getting-help)

---

## Quick Diagnostics

Run these commands to get diagnostic information:

```bash
# Check service status
make status

# View all logs
make logs

# Check Docker
docker ps
docker info

# Check versions
make version

# Validate environment
make validate-env

# Check disk space
df -h
docker system df
```

---

## Docker Issues

### Docker Daemon Not Running

**Symptoms:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solutions:**

**macOS:**
```bash
# Start Docker Desktop from Applications
open -a Docker

# Wait for Docker to start (whale icon in menu bar)
# Then verify
docker ps
```

**Linux:**
```bash
# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

**Windows/WSL2:**
```
1. Start Docker Desktop for Windows
2. Ensure WSL2 integration is enabled in Docker Desktop settings
3. Restart WSL2: wsl --shutdown (in PowerShell)
4. Open WSL2 terminal again
```

---

### Docker Permission Denied

**Symptoms:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Or log out and log back in

# Verify
docker ps
```

---

### Docker Out of Disk Space

**Symptoms:**
```
Error: no space left on device
write /var/lib/docker/...: no space left on device
```

**Solutions:**

```bash
# Check Docker disk usage
docker system df

# Clean up stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes (WARNING: deletes data)
docker volume prune

# Complete cleanup (WARNING: removes everything)
docker system prune -a --volumes

# Or use framework cleanup
make clean
make clean-all  # Includes volumes
```

---

### Docker Containers Keep Restarting

**Symptoms:**
```
Container restarts continuously
Status shows "Restarting"
```

**Solutions:**

```bash
# Check logs for errors
make logs-service SERVICE=<service-name>

# Check container status
docker ps -a

# Inspect container
docker inspect <container-name>

# Common causes:
# 1. Configuration error - check environment variables
# 2. Port conflict - check ports are available
# 3. Resource limits - increase Docker resources
# 4. Dependency not ready - check depends_on in docker-compose.yml

# Try removing and recreating
docker-compose down
docker-compose up -d
```

---

## Service Issues

### Service Won't Start

**Symptoms:**
```
Service exited with code 1
Service status: unhealthy
```

**Diagnostic Steps:**

```bash
# 1. Check logs
make logs-service SERVICE=<service-name>

# 2. Check if port is available
lsof -i :<port>
# or
netstat -tulpn | grep <port>

# 3. Check environment variables
docker exec <container-name> env

# 4. Check service configuration
docker inspect <container-name>

# 5. Try rebuilding
make rebuild SERVICE=<service-name>
```

**Common Causes and Solutions:**

**Missing Environment Variables:**
```bash
# Check .env file exists
ls -la docker/.env

# Copy from example if missing
cp docker/.env.example docker/.env

# Validate
make validate-env
```

**Port Already in Use:**
```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

**Dependency Not Ready:**
```bash
# Ensure dependencies are running
docker ps | grep -E "mongodb|redis|rabbitmq"

# Wait for services
./scripts/dev/wait-for-services.sh

# Check health
make status
```

---

### Service Health Check Failing

**Symptoms:**
```
Health: unhealthy
Health check failed
```

**Solutions:**

```bash
# Check health endpoint manually
curl -v http://localhost:8080/health

# Check if service is listening
docker exec <container> netstat -tuln | grep 8080

# Check application logs
make logs-service SERVICE=<service-name>

# Increase health check timeout in docker-compose.yml
healthcheck:
  interval: 30s
  timeout: 10s
  retries: 5

# Restart service
make restart-service SERVICE=<service-name>
```

---

### Service Responding Slowly

**Symptoms:**
```
Requests timeout
Slow response times
High CPU/memory usage
```

**Diagnostic Steps:**

```bash
# Check resource usage
docker stats

# Check service metrics
make open-grafana
make open-prometheus

# Check logs for errors
make logs-service SERVICE=<service-name>

# Check database performance
# Connect to MongoDB and check slow queries

# Check for memory leaks
docker exec <container> top
```

**Solutions:**

```bash
# Increase Docker resources
# Docker Desktop > Preferences > Resources
# - CPUs: 4+
# - Memory: 8GB+

# Optimize service configuration
# Reduce log verbosity
# Adjust connection pool sizes
# Enable caching

# Restart service
make restart-service SERVICE=<service-name>

# Clear caches
docker exec redis-container redis-cli FLUSHALL
```

---

## Database Issues

### MongoDB Connection Failed

**Symptoms:**
```
Failed to connect to MongoDB
Connection refused: 27017
Authentication failed
```

**Solutions:**

```bash
# Check if MongoDB is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs mongodb

# Test connection
docker exec mongodb mongosh --eval "db.adminCommand('ping')"

# Restart MongoDB
docker restart mongodb

# Check connection string in .env
# Should be: mongodb://mongodb:27017

# Reset MongoDB (WARNING: deletes data)
docker-compose down
docker volume rm go-framework_mongodb-data
docker-compose up -d mongodb
```

---

### Database Corruption

**Symptoms:**
```
Data inconsistencies
Query errors
Unexpected results
```

**Solutions:**

```bash
# 1. Backup existing data
make db-backup

# 2. Check MongoDB logs
docker logs mongodb

# 3. Try repair
docker exec mongodb mongosh --eval "db.repairDatabase()"

# 4. If repair fails, restore from backup
make db-restore FILE=backups/latest-backup.tar.gz

# 5. As last resort, reset and reseed
make db-reset
make db-seed
```

---

### Redis Connection Issues

**Symptoms:**
```
Redis connection timeout
ECONNREFUSED: Connection refused
```

**Solutions:**

```bash
# Check if Redis is running
docker ps | grep redis

# Test connection
docker exec redis redis-cli ping
# Should return: PONG

# Check Redis logs
docker logs redis

# Restart Redis
docker restart redis

# Clear Redis cache
docker exec redis redis-cli FLUSHALL

# Check connection string
# Should be: redis://redis:6379
```

---

## Network and Port Issues

### Port Already in Use

**Symptoms:**
```
Error: port 8080 is already allocated
Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Solutions:**

```bash
# Find process using port
lsof -i :8080
# or
netstat -tulpn | grep 8080

# On macOS
lsof -ti:8080 | xargs kill -9

# On Linux
sudo fslof -t -i:8080
kill -9 <PID>

# Change port in docker-compose.yml if needed
ports:
  - "8888:8080"  # Use 8888 externally instead
```

---

### Cannot Connect to Service

**Symptoms:**
```
Connection refused
curl: (7) Failed to connect to localhost port 8080
```

**Diagnostic Steps:**

```bash
# 1. Check if service is running
docker ps | grep <service-name>

# 2. Check if port is mapped
docker port <container-name>

# 3. Check service logs
make logs-service SERVICE=<service-name>

# 4. Test from inside container
docker exec <container> curl localhost:8080/health

# 5. Check firewall
sudo iptables -L
# or on macOS
sudo pfctl -s rules
```

**Solutions:**

```bash
# Ensure service is healthy
make status

# Check port mapping in docker-compose.yml
ports:
  - "8080:8080"

# Restart service
make restart-service SERVICE=<service-name>

# Check if using correct host
# Use localhost or 127.0.0.1, not 0.0.0.0
curl http://localhost:8080/health
```

---

### DNS Resolution Issues

**Symptoms:**
```
Could not resolve host
Name or service not known
```

**Solutions:**

```bash
# Check Docker network
docker network ls
docker network inspect go-framework_saas-network

# Restart Docker networking
docker-compose down
docker-compose up -d

# Check /etc/hosts (for custom entries)
cat /etc/hosts

# Test DNS inside container
docker exec <container> nslookup mongodb
docker exec <container> ping -c 1 redis
```

---

## Build and Compilation Issues

### Go Module Issues

**Symptoms:**
```
go: module not found
cannot find module
checksum mismatch
```

**Solutions:**

```bash
# Clear Go module cache
go clean -modcache

# Update dependencies
cd <service-directory>
go get -u ./...
go mod tidy
go mod download

# Verify checksums
go mod verify

# If using private repos, setup Git credentials
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Set GOPRIVATE
export GOPRIVATE=github.com/vhvcorp/*
```

---

### Docker Build Failures

**Symptoms:**
```
Build failed
ERROR: failed to solve
```

**Solutions:**

```bash
# Clear Docker build cache
docker builder prune -a

# Rebuild without cache
docker-compose build --no-cache

# Check Dockerfile syntax
docker build --check .

# Increase build timeout
DOCKER_BUILDKIT=0 docker-compose build

# Check disk space
df -h
docker system df
```

---

### Missing Dependencies

**Symptoms:**
```
command not found
package not found
```

**Solutions:**

```bash
# Re-run setup
make setup

# Install specific tool
./scripts/setup/install-tools.sh

# Check if tool is in PATH
echo $PATH
which protoc-gen-go

# Add Go bin to PATH
export PATH=$PATH:$(go env GOPATH)/bin

# Add to shell profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

---

## macOS Specific Issues

### Docker Desktop Resource Issues

**Symptoms:**
```
Slow performance
High CPU usage
Docker consuming too much memory
```

**Solutions:**

```bash
# Increase Docker resources
# Docker Desktop > Preferences > Resources
# Recommended:
# - CPUs: 4+
# - Memory: 8GB+
# - Swap: 2GB+
# - Disk: 60GB+

# Enable VirtioFS for better file sharing
# Docker Desktop > Preferences > Experimental Features
# - Enable VirtioFS

# Restart Docker Desktop
# Click whale icon > Restart
```

---

### Permission Issues on macOS

**Symptoms:**
```
Operation not permitted
Permission denied
```

**Solutions:**

```bash
# Grant Docker Full Disk Access
# System Preferences > Security & Privacy > Privacy
# Add Docker to Full Disk Access

# Fix file permissions
chmod +x scripts/**/*.sh

# Use sudo for system operations
sudo make install-cli
```

---

### Homebrew Issues

**Symptoms:**
```
brew command not found
brew install failed
```

**Solutions:**

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Update Homebrew
brew update

# Fix Homebrew permissions
sudo chown -R $(whoami) /usr/local/bin /usr/local/share

# Check Homebrew
brew doctor
```

---

## Linux Specific Issues

### systemd Service Issues

**Symptoms:**
```
Docker service failed to start
systemd errors
```

**Solutions:**

```bash
# Check systemd status
systemctl status docker

# View service logs
journalctl -u docker -n 50

# Restart Docker
sudo systemctl restart docker

# Enable on boot
sudo systemctl enable docker

# Check for conflicts
sudo systemctl list-units --failed
```

---

### SELinux Issues

**Symptoms:**
```
Permission denied (SELinux)
Operation not permitted
```

**Solutions:**

```bash
# Check SELinux status
getenforce

# Temporarily disable (for testing)
sudo setenforce 0

# Set to permissive mode
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Or configure SELinux policies for Docker
# (preferred for production)
```

---

### Firewall Issues

**Symptoms:**
```
Cannot access services
Connection filtered
```

**Solutions:**

```bash
# Check firewall status
sudo firewall-cmd --state
# or
sudo ufw status

# Allow Docker ports
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Or disable firewall temporarily
sudo systemctl stop firewalld
# or
sudo ufw disable
```

---

## Windows/WSL2 Specific Issues

### WSL2 Network Issues

**Symptoms:**
```
Cannot connect from Windows to WSL2 services
Port forwarding not working
```

**Solutions:**

```bash
# Get WSL2 IP address
ip addr show eth0 | grep inet

# From Windows, access via WSL2 IP
http://<WSL2-IP>:8080

# Or use localhost (usually works)
http://localhost:8080

# Restart WSL2 network
# In PowerShell (as Administrator):
wsl --shutdown
# Then restart WSL2 terminal
```

---

### Docker Desktop Integration

**Symptoms:**
```
Docker not available in WSL2
Cannot connect to Docker daemon
```

**Solutions:**

```
1. Open Docker Desktop settings
2. Go to Resources > WSL Integration
3. Enable integration with your WSL2 distro
4. Click "Apply & Restart"
5. Open new WSL2 terminal
6. Verify: docker ps
```

---

### File Permission Issues

**Symptoms:**
```
Permission denied when editing files
chmod doesn't work
```

**Solutions:**

```bash
# Add to /etc/wsl.conf
sudo tee /etc/wsl.conf > /dev/null <<EOF
[automount]
options = "metadata"
EOF

# Restart WSL2
# In PowerShell: wsl --shutdown

# Then reopen WSL2 terminal
```

---

## Performance Issues

### Slow File System Operations

**Symptoms:**
```
Slow builds
Slow file operations
High I/O wait
```

**Solutions:**

```bash
# macOS: Enable VirtioFS
# Docker Desktop > Experimental Features > VirtioFS

# Don't work with files in /mnt/ on WSL2
# Clone repos to WSL2 file system:
cd ~
mkdir -p workspace
cd workspace
git clone ...

# Use Docker volumes instead of bind mounts
# In docker-compose.yml:
volumes:
  - node_modules:/app/node_modules  # Named volume (fast)
  # instead of:
  # - ./node_modules:/app/node_modules  # Bind mount (slow)
```

---

### High Memory Usage

**Symptoms:**
```
System running slow
Out of memory errors
Docker using too much RAM
```

**Solutions:**

```bash
# Check current usage
docker stats

# Limit container memory
# In docker-compose.yml:
services:
  service-name:
    mem_limit: 512m

# Stop unnecessary services
make stop

# Clear caches
docker system prune

# Increase system resources in Docker Desktop
```

---

### Slow Network Performance

**Symptoms:**
```
Slow API responses
High latency
```

**Solutions:**

```bash
# Check network statistics
docker exec <container> netstat -s

# Use host network mode (Linux only)
# In docker-compose.yml:
network_mode: "host"

# Optimize Docker DNS
# In docker-compose.yml:
services:
  service-name:
    dns:
      - 8.8.8.8
      - 8.8.4.4

# Check Docker network driver
docker network inspect go-framework_saas-network
```

---

## Getting Help

### Self-Help Resources

1. **Check Documentation**
   - [README.md](../README.md) - Quick start
   - [SETUP.md](SETUP.md) - Installation guide
   - [TOOLS.md](TOOLS.md) - Tool reference
   - [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture

2. **Check Logs**
   ```bash
   make logs
   make logs-service SERVICE=<name>
   ```

3. **Run Diagnostics**
   ```bash
   make status
   make validate-env
   make version
   docker info
   ```

4. **Search Existing Issues**
   - [GitHub Issues](https://github.com/vhvcorp/go-framework/issues)

### Reporting Issues

If you can't resolve the issue, open a GitHub issue with:

**Required Information:**

```bash
# System information
uname -a
make version

# Docker information
docker info
docker-compose version

# Service status
make status

# Recent logs
make logs > logs.txt

# Environment (sanitize secrets!)
cat docker/.env.example  # Don't include actual .env
```

**Issue Template:**

```markdown
## Description
Brief description of the issue

## Steps to Reproduce
1. Step 1
2. Step 2
3. ...

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [macOS 13.0 / Ubuntu 22.04 / Windows 11 WSL2]
- Docker: [version]
- Go: [version]

## Logs
```
Paste relevant logs here
```

## Additional Context
Any other relevant information
```

### Community Support

- **GitHub Discussions:** Ask questions and share ideas
- **Pull Requests:** Contribute improvements
- **Documentation:** Help improve these docs

---

## Common Error Messages

### "Cannot connect to the Docker daemon"
→ See [Docker Daemon Not Running](#docker-daemon-not-running)

### "Port already allocated"
→ See [Port Already in Use](#port-already-in-use)

### "Permission denied"
→ See [Docker Permission Denied](#docker-permission-denied)

### "No space left on device"
→ See [Docker Out of Disk Space](#docker-out-of-disk-space)

### "Connection refused"
→ See [Cannot Connect to Service](#cannot-connect-to-service)

### "Health check failed"
→ See [Service Health Check Failing](#service-health-check-failing)

### "Container is restarting"
→ See [Docker Containers Keep Restarting](#docker-containers-keep-restarting)

---

**Last Updated:** 2024-01-15  
**Need more help?** Open an issue on [GitHub](https://github.com/vhvcorp/go-framework/issues)
