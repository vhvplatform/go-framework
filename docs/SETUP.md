# Setup and Installation Guide

Complete guide for setting up the go-framework development environment from scratch.

## Table of Contents

- [System Requirements](#system-requirements)
- [Quick Setup](#quick-setup)
- [Detailed Installation](#detailed-installation)
- [Environment Configuration](#environment-configuration)
- [Verification](#verification)
- [Common Setup Issues](#common-setup-issues)
- [Advanced Configuration](#advanced-configuration)

---

## System Requirements

### Minimum Requirements

- **Operating System:** macOS 10.15+, Linux (Ubuntu 20.04+, Debian 11+, Fedora 35+), or Windows 10+ with WSL2
- **RAM:** 8GB (16GB recommended for running all services)
- **Disk Space:** 20GB free space
- **CPU:** 2 cores (4+ recommended)
- **Internet:** Broadband connection for downloading dependencies

### Required Software

The following will be installed automatically via `make setup`:

- **Docker Desktop** 4.0+
- **Go** 1.21+
- **Make** (usually pre-installed on macOS/Linux)
- **Git** 2.0+

### Optional but Recommended

- **kubectl** 1.27+ (for Kubernetes deployments)
- **Helm** 3.12+ (for Helm chart deployments)
- **VS Code** with Go extension (for development)
- **Postman** or similar API testing tool

---

## Quick Setup

For users who want to get started quickly:

```bash
# 1. Clone the repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework

# 2. Run automated setup (installs everything)
make setup

# 3. Start all services
make start

# 4. Verify services are running
make status

# 5. View service URLs
make info
```

**Estimated Time:** 15-30 minutes (depending on internet speed)

That's it! Your development environment is ready. See [GETTING_STARTED.md](GETTING_STARTED.md) for next steps.

---

## Detailed Installation

For users who prefer step-by-step installation or manual control:

### Step 1: Install System Dependencies

#### macOS

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install go docker git make jq
brew install --cask docker

# Start Docker Desktop
open -a Docker
```

Wait for Docker Desktop to start (whale icon in menu bar should be stable).

#### Linux (Ubuntu/Debian)

```bash
# Update package list
sudo apt-get update

# Install basic tools
sudo apt-get install -y git make curl wget unzip jq apt-transport-https ca-certificates gnupg lsb-release

# Install Go (1.21+)
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc

# Verify Go installation
go version

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Log out and log back in for docker group to take effect
# Or run: newgrp docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
docker --version
docker ps
```

#### Linux (Fedora/RHEL)

```bash
# Install basic tools
sudo dnf install -y git make curl wget unzip jq

# Install Go
sudo dnf install -y golang

# Verify Go version (should be 1.21+)
go version

# If Go version is too old, install manually:
# wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
# sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Install Docker
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Log out and log back in
```

#### Windows (WSL2)

```bash
# 1. Install WSL2 from PowerShell (as Administrator):
wsl --install

# 2. Install Ubuntu from Microsoft Store

# 3. Open Ubuntu terminal and follow Linux (Ubuntu/Debian) instructions above

# 4. Install Docker Desktop for Windows
#    - Download from https://www.docker.com/products/docker-desktop
#    - Enable WSL2 integration in Docker Desktop settings
#    - Enable Ubuntu integration
```

### Step 2: Clone Repository

```bash
# Create workspace directory
mkdir -p ~/workspace/go-platform
cd ~/workspace/go-platform

# Clone go-framework repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework
```

### Step 3: Install Go Development Tools

```bash
# Install Go tools (protoc, linters, etc.)
./scripts/setup/install-tools.sh

# Or use make target
make setup-tools
```

This installs:
- Protocol Buffer compilers
- gRPC code generators
- Linting tools
- Hot reload tools
- Mock generators
- Testing utilities

**Note:** Ensure `$GOPATH/bin` is in your `$PATH`:

```bash
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc

# Or for zsh:
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.zshrc
source ~/.zshrc
```

### Step 4: Clone Service Repositories

```bash
# Clone all microservice repositories
./scripts/setup/clone-repos.sh

# Or use make target
make setup-repos
```

This clones all required repositories to your workspace:
- Shared library
- All microservices
- Infrastructure code

**Custom workspace location:**
```bash
WORKSPACE_DIR=/custom/path/to/workspace make setup-repos
```

### Step 5: Initialize Workspace

```bash
# Initialize workspace structure
./scripts/setup/init-workspace.sh
```

Creates necessary directories:
- `bin/` - For compiled binaries
- `logs/` - For service logs
- `data/` - For persistent data
- `backups/` - For database backups

---

## Environment Configuration

### Basic Configuration

```bash
# Create environment file from example
cd docker
cp .env.example .env

# Edit with your preferred editor
nano .env
# or
vim .env
# or
code .env
```

### Essential Environment Variables

Edit `docker/.env` and configure:

```bash
# JWT Configuration (CHANGE IN PRODUCTION!)
JWT_SECRET=dev-secret-change-in-production
JWT_EXPIRATION=24h

# Database
MONGODB_URI=mongodb://mongodb:27017
MONGODB_DATABASE=saas_platform

# Redis
REDIS_URL=redis://redis:6379

# RabbitMQ
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/

# Observability
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
JAEGER_PORT=16686

# Service Ports (usually don't need to change)
API_GATEWAY_PORT=8080
AUTH_SERVICE_PORT=8081
USER_SERVICE_PORT=8082
TENANT_SERVICE_PORT=8083
NOTIFICATION_SERVICE_PORT=8084
SYSTEM_CONFIG_SERVICE_PORT=8085

# Optional: Email Configuration (for notifications)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-email@example.com
SMTP_PASSWORD=your-password
SMTP_FROM=noreply@example.com

# Optional: Grafana
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin
```

### Advanced Configuration

For production or custom setups, additional configuration files:

#### Docker Compose Overrides

Create `docker/docker-compose.override.yml` for local customizations:

```yaml
version: '3.8'

services:
  api-gateway:
    environment:
      - CUSTOM_VAR=custom_value
    ports:
      - "8888:8080"  # Custom port mapping
```

#### Service-Specific Configuration

Each microservice can be configured via environment variables or config files. See individual service documentation.

---

## Verification

### Verify Installation

```bash
# Check installed tools
go version          # Should be 1.21+
docker --version    # Should be 4.0+
make --version      # Any recent version
git --version       # Should be 2.0+

# Check Go tools
protoc --version
golangci-lint --version
air -v
```

### Verify Repository Structure

```bash
# Your workspace should look like:
tree -L 1 ~/workspace/go-platform/
```

Expected output:
```
~/workspace/go-platform/
├── go-framework/
├── go-shared-go/
├── go-api-gateway/
├── go-auth-service/
├── go-user-service/
├── go-tenant-service/
├── go-notification-service/
├── go-system-config-service/
└── go-infrastructure/
```

### Start and Verify Services

```bash
cd ~/workspace/go-platform/go-framework

# Start all services
make start

# Wait for services to be healthy (automatically done)
# Check status
make status
```

Expected output:
```
✅ Docker is running
✅ API Gateway is healthy
✅ Auth Service is healthy
✅ User Service is healthy
✅ Tenant Service is healthy
✅ Notification Service is healthy
✅ System Config Service is healthy
✅ MongoDB is healthy
✅ Redis is healthy
✅ RabbitMQ is healthy
```

### Test API Connectivity

```bash
# Quick health check
curl http://localhost:8080/health

# Should return:
# {"status":"healthy"}

# Or use make target
make test-api
```

### Verify Monitoring Stack

```bash
# Open monitoring dashboards
make open-grafana     # http://localhost:3000
make open-prometheus  # http://localhost:9090
make open-jaeger      # http://localhost:16686
```

---

## Common Setup Issues

### Issue: Docker daemon not running

**Symptoms:**
```
Cannot connect to the Docker daemon
```

**Solution:**
```bash
# macOS: Start Docker Desktop from Applications
# Linux: Start Docker service
sudo systemctl start docker

# Verify
docker ps
```

---

### Issue: Port already in use

**Symptoms:**
```
Error: port 8080 is already allocated
```

**Solution:**
```bash
# Find process using the port
lsof -i :8080
# or
netstat -tulpn | grep 8080

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.yml
```

---

### Issue: Permission denied (Docker)

**Symptoms:**
```
Got permission denied while trying to connect to Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or run:
newgrp docker

# Verify
docker ps
```

---

### Issue: Go tools not in PATH

**Symptoms:**
```
command not found: protoc-gen-go
```

**Solution:**
```bash
# Add to PATH
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc

# Verify
which protoc-gen-go
```

---

### Issue: Git clone fails (SSH key)

**Symptoms:**
```
Permission denied (publickey)
```

**Solution:**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Add public key to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy output and add to GitHub: Settings > SSH Keys

# Or use HTTPS instead
git config --global url."https://github.com/".insteadOf git@github.com:
```

---

### Issue: Services not starting

**Symptoms:**
```
Service exited with code 1
```

**Solution:**
```bash
# Check logs
make logs-service SERVICE=<service-name>

# Common causes:
# 1. Missing environment variables
make validate-env

# 2. Port conflicts
# Check docker-compose.yml and resolve conflicts

# 3. Database not ready
# Ensure MongoDB is running
docker ps | grep mongodb

# 4. Rebuild service
make rebuild SERVICE=<service-name>
```

---

### Issue: Slow performance on macOS

**Symptoms:**
- Services slow to start
- High CPU usage
- Sluggish response

**Solution:**
```bash
# 1. Increase Docker resources
# Docker Desktop > Preferences > Resources
# - CPUs: 4+
# - Memory: 8GB+
# - Swap: 2GB+
# - Disk: 60GB+

# 2. Enable VirtioFS (faster file sharing)
# Docker Desktop > Preferences > Experimental Features
# - Enable VirtioFS

# 3. Reduce file watchers in dev mode
# Edit docker-compose.dev.yml and limit watched paths
```

---

### Issue: Out of disk space

**Symptoms:**
```
Error: no space left on device
```

**Solution:**
```bash
# Clean up Docker
make clean

# Remove unused images and volumes
docker system prune -a --volumes

# Check disk usage
df -h
docker system df
```

---

## Advanced Configuration

### Custom Workspace Location

```bash
# Set custom workspace location
export WORKSPACE_DIR=/path/to/custom/workspace

# Run setup
make setup
```

### Network Configuration

For custom networking or corporate proxies:

```bash
# Configure Docker proxy
mkdir -p ~/.docker
cat > ~/.docker/config.json << EOF
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.example.com:8080",
      "httpsProxy": "http://proxy.example.com:8080",
      "noProxy": "localhost,127.0.0.1"
    }
  }
}
EOF

# Configure Go proxy
export GOPROXY=https://proxy.golang.org,direct
export GOPRIVATE=github.com/vhvplatform/*
```

### Using Pre-built Images

If you don't want to build from source:

```bash
# Pull pre-built images
docker-compose -f docker/docker-compose.yml pull

# Start services
make start
```

### Multi-Platform Setup

For teams with mixed environments:

```bash
# Build for multiple platforms
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t myimage:latest .
```

---

## Next Steps

After successful setup:

1. **Load Test Data**
   ```bash
   make db-seed
   make test-data
   ```

2. **Run Tests**
   ```bash
   make test
   ```

3. **Start Development**
   - See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md)
   - See [DEVELOPMENT.md](DEVELOPMENT.md)

4. **Explore Monitoring**
   ```bash
   make open-grafana
   make open-jaeger
   ```

5. **Read Documentation**
   - [TOOLS.md](TOOLS.md) - Tool reference
   - [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
   - [TESTING.md](TESTING.md) - Testing guide

---

## Getting Help

If you encounter issues:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review logs: `make logs`
3. Validate environment: `make validate-env`
4. Check status: `make status`
5. Open GitHub issue with:
   - Error messages
   - System information (`make version`)
   - Steps to reproduce

---

**Setup Time:** 15-30 minutes  
**Support:** [GitHub Issues](https://github.com/vhvplatform/go-framework/issues)  
**Last Updated:** 2024-01-15
