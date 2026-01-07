# Getting Started with SaaS Platform Development

This guide will walk you through setting up your local development environment from scratch.

## Prerequisites

Before you begin, ensure you have:

- A computer with macOS, Linux, or Windows (with WSL2)
- Internet connection for downloading dependencies
- At least 8GB of RAM (16GB recommended)
- At least 20GB of free disk space

## Step 1: Install Dependencies

### Automated Installation (Recommended)

```bash
cd framework
make setup
```

This will install:
- Go 1.21+
- Docker Desktop
- kubectl
- Helm
- protoc (Protocol Buffers compiler)
- Go development tools
- And clone all service repositories

### Manual Installation

If you prefer to install manually, see the detailed instructions below.

#### macOS

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install go docker kubectl helm protobuf jq
brew install --cask docker
```

#### Linux (Ubuntu/Debian)

```bash
# Update package list
sudo apt-get update

# Install basic tools
sudo apt-get install -y git make curl wget unzip jq

# Install Go (1.21+)
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### Windows (WSL2)

1. Install WSL2 and Ubuntu from Microsoft Store
2. Follow Linux instructions above inside WSL2

## Step 2: Clone Repository

```bash
# Create workspace directory
mkdir -p ~/workspace/go-platform
cd ~/workspace/go-platform

# Clone framework repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework
```

## Step 3: Install Development Tools

```bash
# Install Go tools (protoc, linters, etc.)
make setup-tools
```

This installs:
- `protoc-gen-go` - Protocol buffer Go generator
- `protoc-gen-go-grpc` - gRPC Go generator
- `golangci-lint` - Go linter
- `air` - Hot reload tool
- `mockgen` - Mock generation
- `goimports` - Import formatter
- `swag` - Swagger documentation
- `hey` - Load testing tool

## Step 4: Clone Service Repositories

```bash
# Clone all service repositories
make setup-repos
```

This clones:
- `go-shared` - Shared library
- `go-api-gateway` - API Gateway service
- `go-auth-service` - Authentication service
- `go-user-service` - User management service
- `go-tenant-service` - Multi-tenancy service
- `go-notification-service` - Notification service
- `go-system-config-service` - Configuration service
- `go-infrastructure` - Infrastructure as code

## Step 5: Configure Environment

```bash
# Setup environment variables
make setup-env

# Edit .env file with your settings
cd docker
nano .env  # or use your preferred editor
```

Key variables to configure:
- `JWT_SECRET` - Change from default for security
- `SMTP_*` - Configure if testing email notifications

## Step 6: Start Services

```bash
# Start all services
make start

# Wait for services to be ready (takes 1-2 minutes)
# The script will automatically wait and verify
```

## Step 7: Verify Installation

```bash
# Check service health
make status

# View service URLs
make info
```

Expected output:
```
✅ All services are healthy!
```

## Step 8: Test the Platform

### Quick Health Check

```bash
curl http://localhost:8080/health
```

### Using Postman

1. Open Postman
2. Import collections from `postman/SaaS-Platform.postman_collection.json`
3. Import environment from `postman/Development.postman_environment.json`
4. Try the "Login" request

### Using Command Line

```bash
# Test API endpoints
make test-api
```

## Step 9: Load Test Data

```bash
# Generate and load test data
make test-data
make db-seed
```

This creates:
- 3 test users
- 2 test tenants
- 3 role definitions

## Step 10: Explore

### View Dashboards

```bash
# Open Grafana (metrics)
make open-grafana

# Open Jaeger (tracing)
make open-jaeger

# Open RabbitMQ Management
make open-rabbitmq
```

### View Logs

```bash
# All services
make logs

# Specific service
make logs-service SERVICE=auth-service
```

## Next Steps

Now that your environment is set up:

1. **Read the Code** - Explore service repositories
2. **Run Tests** - `make test` to run all tests
3. **Make Changes** - Edit code and see hot-reload in action
4. **Debug** - Use VS Code debug configurations
5. **Read Docs** - Check out [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md)

## Workspace Structure

Your workspace should now look like:

```
~/workspace/go-platform/
└── go/                          # All repositories directory
    ├── go-framework/            # This repository (tools & scripts)
    ├── go-infrastructure/       # Infrastructure code
    ├── go-shared/               # Shared library
    ├── go-api-gateway/          # API Gateway
    ├── go-auth-service/         # Auth service
    ├── go-user-service/         # User service
    ├── go-tenant-service/       # Tenant service
    ├── go-notification-service/ # Notification service
    └── go-system-config-service/ # Config service
```

## Common Issues

### Docker not starting

```bash
# Check Docker is running
docker info

# Restart Docker Desktop
# macOS: Restart from menu bar
# Linux: sudo systemctl restart docker
```

### Port conflicts

```bash
# Check if ports are in use
netstat -tulpn | grep -E '8080|27017|6379|5672'

# Stop conflicting services or change ports in docker-compose.yml
```

### Permission denied

```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
# Log out and log back in
```

## Getting Help

- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- View service logs: `make logs`
- Check service health: `make status`
- Open an issue on GitHub

## What's Next?

Continue with:
- [Local Development Guide](LOCAL_DEVELOPMENT.md) - Development workflow
- [Testing Guide](TESTING.md) - Running and writing tests
- [Debugging Guide](DEBUGGING.md) - Debugging techniques

---

**Estimated Setup Time:** 15-30 minutes (depending on internet speed)

**Need Help?** Open an issue or check the troubleshooting guide.
