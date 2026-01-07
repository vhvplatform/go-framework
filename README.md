# SaaS Platform - Monorepo

<p align="center">
  <strong>Full-stack SaaS Platform with Backend, Frontend, and Mobile App</strong>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#repository-structure">Structure</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#requirements">Requirements</a>
</p>

---

## 📁 Repository Structure

This monorepo contains all components of the SaaS Platform:

```
go-framework/
├── server/         # Golang backend microservices
├── client/         # React.js frontend application (coming soon)
├── flutter/        # Flutter mobile application (coming soon)
└── docs/           # Project documentation
```

### [Server](server/) - Backend Microservices
Complete Golang backend with microservices architecture, Docker setup, development tools, and automation scripts.

### [Client](client/) - Frontend Application
React.js-based frontend microservice for the web interface (placeholder - to be implemented).

### [Flutter](flutter/) - Mobile Application  
Flutter-based mobile application for iOS and Android (placeholder - to be implemented).

### [Docs](docs/) - Documentation
Comprehensive documentation including guides, architecture, deployment instructions, and diagrams.

---

## 🚀 Quick Start

Get up and running in minutes:

```bash
# Clone this repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework

# Setup backend development environment
cd server
make setup

# Start all backend services
make start

# View service status
make status

# Access services
make info
```

**Windows Users:** See the [Windows Setup Guide](docs/windows/WINDOWS_SETUP.md) for automated setup using PowerShell. Supports custom installation paths (e.g., `E:\go\go-framework`).

That's it! Your backend services are now running locally.

## 📦 What's Included

### Infrastructure & Services
- **Docker Compose** - Full local development stack
- **All Microservices** - API Gateway, Auth, User, Tenant, Notification, System Config
- **Databases** - MongoDB, Redis, RabbitMQ
- **Observability** - Prometheus, Grafana, Jaeger

### Development Tools
- **40+ Make Commands** - Automation for everything
- **25+ Shell Scripts** - Setup, testing, deployment
- **IDE Configurations** - VS Code ready-to-use setups
- **Git Hooks** - Commit quality enforcement
- **Postman Collections** - Complete API testing suite

### Testing & Utilities
- **Test Fixtures** - Sample data for development
- **Load Testing** - Performance testing tools
- **Health Checks** - Service monitoring
- **JWT Generator** - Testing token generation

## 📚 Documentation

See the [docs](docs/) directory for comprehensive documentation:

### Getting Started
- [Getting Started](docs/guides/GETTING_STARTED.md) - Detailed setup guide
- [Beginner Guide](docs/guides/BEGINNER_GUIDE.md) - For new developers
- [Setup Guide](docs/guides/SETUP.md) - Installation instructions

### Development
- [Local Development](docs/guides/LOCAL_DEVELOPMENT.md) - Development workflow
- [Coding Guidelines](docs/guides/CODING_GUIDELINES.md) - Code standards
- [Testing Guide](docs/guides/TESTING.md) - How to run tests
- [Debugging](docs/guides/DEBUGGING.md) - Debugging tips and tricks
- [Troubleshooting](docs/guides/TROUBLESHOOTING.md) - Common issues and solutions
- [Tools Reference](docs/guides/TOOLS.md) - Complete tool documentation

### Deployment
- [Kubernetes Deployment](docs/deployment/KUBERNETES_DEPLOYMENT.md) - Deploy to Kubernetes cluster

### Architecture
- [System Architecture](docs/architecture/ARCHITECTURE.md) - System design and components
- [Architecture Diagrams](docs/diagrams/) - Visual representations

### Platform-Specific
- [Windows Setup Guide](docs/windows/WINDOWS_SETUP.md) - Windows-specific setup
- [Windows Testing Guide](docs/windows/WINDOWS_TESTING_GUIDE.md) - Testing Windows installations

## 💻 Requirements

### Backend (Server)
- **Docker Desktop** 4.0+
- **Go** 1.25+
- **Make** (usually pre-installed on macOS/Linux)

### Frontend (Client) - Coming Soon
- **Node.js** 18+
- **npm** or **yarn**
- **React** 18+

### Mobile (Flutter) - Coming Soon
- **Flutter SDK** 3.0+
- **Dart** 3.0+
- **Android Studio** / **Xcode**

### Recommended Tools
- **kubectl** 1.27+ (for Kubernetes deployment)
- **Helm** 3.12+ (for Helm deployments)
- **VS Code** (with Go, React, and Flutter extensions)

### Operating Systems
- ✅ macOS (Intel & Apple Silicon)
- ✅ Linux (Ubuntu, Debian, Fedora, etc.)
- ✅ Windows 10/11 (with WSL2) - See [Windows Setup Guide](docs/windows/WINDOWS_SETUP.md)

## 🎯 Key Features

### Backend Server Features

#### One-Command Operations

```bash
# Navigate to server directory
cd server

# Development commands
make setup          # Complete development environment setup
make start          # Start all services with one command
make test           # Run full test suite
make build          # Build all microservices
make clean          # Clean up everything
```

### Powerful Scripts

```bash
# Navigate to server directory first
cd server

# Database Management
make db-seed        # Populate with test data
make db-reset       # Reset database
make db-backup      # Backup database
make db-restore     # Restore from backup

# Development
make restart-service SERVICE=auth-service
make logs-service SERVICE=auth-service
make shell SERVICE=auth-service

# Testing
make test-unit           # Unit tests
make test-integration    # Integration tests
make test-e2e           # End-to-end tests
make test-load          # Load/performance tests

# Monitoring
make open-grafana       # Open Grafana dashboard
make open-prometheus    # Open Prometheus
make open-jaeger        # Open Jaeger tracing
```

### Hot Reload Development

```bash
# Navigate to server directory
cd server

# Start with development mode for hot-reload
make start-dev

# Edit code - changes are automatically reflected!
```

## 🛠️ Directory Structure

### Server Directory
```
server/
├── docker/                    # Docker Compose configurations
│   ├── docker-compose.yml     # Main stack
│   ├── docker-compose.dev.yml # Development overrides
│   └── docker-compose.test.yml# Testing configuration
├── scripts/                   # Automation scripts
│   ├── setup/                 # Setup and installation
│   ├── dev/                   # Development utilities
│   ├── database/              # Database management
│   ├── testing/               # Test automation
│   ├── deployment/            # Deployment automation
│   ├── monitoring/            # Monitoring utilities
│   └── utilities/             # General utilities
├── configs/                   # IDE and tool configurations
│   ├── vscode/                # VS Code settings
│   ├── git/                   # Git hooks and config
│   └── linting/               # Linter configurations
├── mocks/                     # Mock services for testing
├── tools/                     # CLI development tools
├── fixtures/                  # Test data
├── postman/                   # API testing collections
├── k8s/                       # Kubernetes manifests
└── Makefile                   # Build and automation commands
```

### Documentation Directory
```
docs/
├── guides/        # Development and setup guides
├── architecture/  # System architecture documentation
├── deployment/    # Deployment guides
├── windows/       # Windows-specific documentation
├── diagrams/      # Architecture diagrams (Mermaid)
└── vi/           # Vietnamese documentation
```

### Coming Soon
- `client/` - React.js frontend application
- `flutter/` - Mobile application for iOS/Android

## 🌐 Service URLs

Once started, services are available at:

### Microservices
- **API Gateway**: http://localhost:8080
- **Auth Service**: http://localhost:8081 (gRPC: 50051)
- **User Service**: http://localhost:8082 (gRPC: 50052)
- **Tenant Service**: http://localhost:8083 (gRPC: 50053)
- **Notification Service**: http://localhost:8084 (gRPC: 50054)
- **System Config Service**: http://localhost:8085 (gRPC: 50055)

### Infrastructure
- **MongoDB**: mongodb://localhost:27017
- **Redis**: redis://localhost:6379
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

### Observability
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Jaeger**: http://localhost:16686

## 🔧 Configuration

### Environment Variables

Copy and customize the environment file:

```bash
cd server/docker
cp .env.example .env
# Edit .env with your settings
```

Key variables:
- `JWT_SECRET` - JWT signing secret (change in production!)
- `SMTP_*` - Email configuration (optional for local dev)
- `GRAFANA_PASSWORD` - Grafana admin password

### VS Code Setup

VS Code configuration is included! Just open the workspace:

```bash
code ../go-platform
```

Features:
- Debug configurations for all services
- Recommended extensions
- Task automation
- Code formatting and linting

## 🧪 Testing

```bash
# Run all tests
make test

# Run specific test suites
make test-unit              # Fast unit tests
make test-integration       # Integration tests with services
make test-e2e              # Full end-to-end tests
make test-load             # Performance/load tests

# Generate test data
make test-data
make db-seed
```

## 🐛 Debugging

### View Logs

```bash
make logs                          # All services
make logs-service SERVICE=auth-service   # Specific service
```

### Check Health

```bash
make status          # Quick health check
make health          # Detailed status
```

### Access Service Shell

```bash
make shell SERVICE=auth-service
```

### Debug with VS Code

1. Start infrastructure: `make start`
2. Open VS Code: `code .`
3. Press F5 and select service to debug
4. Set breakpoints and debug!

## 📊 Monitoring

Built-in observability stack:

```bash
# Open dashboards
make open-grafana      # Metrics and dashboards
make open-prometheus   # Raw metrics and queries
make open-jaeger       # Distributed tracing
```

**Grafana** provides:
- Request rates and latency
- Error rates
- Resource usage (CPU, memory)
- Database metrics
- Queue sizes

## 🚢 Deployment

### Kubernetes (Production & Staging)

For detailed instructions on deploying to a Kubernetes cluster, see the comprehensive guide:

📖 **[Kubernetes Deployment Guide](docs/deployment/KUBERNETES_DEPLOYMENT.md)**

The guide includes:
- Prerequisites and requirements
- Step-by-step deployment instructions
- Configuration management
- Health checks and verification
- Troubleshooting common issues
- Best practices for production

Quick start:
```bash
# Deploy all resources to Kubernetes
kubectl apply -f server/k8s/base/

# Check deployment status
kubectl get pods -n go-platform

# Port-forward to access services
kubectl port-forward -n go-platform svc/api-gateway 8080:8080
```

### Local Kubernetes

```bash
# Deploy to local cluster (minikube, kind, etc.)
make deploy-local

# Setup port forwarding
make port-forward
```

### Remote Environments

```bash
# Deploy to development environment
make deploy-dev
```

## 💡 Tips & Tricks

### Fast Restart

```bash
# Restart specific service quickly
make restart-service SERVICE=auth-service

# Rebuild and restart
make rebuild SERVICE=auth-service
```

### Generate JWT for Testing

```bash
make generate-jwt
# Copy token and use in API requests
```

### API Testing

```bash
# Quick API test
make test-api

# Or use Postman collections in postman/
```

### Clean Start

```bash
# Stop everything and clean data
make clean-all

# Fresh start
make start
```

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and coding standards.

## 📋 Common Tasks

### Adding a New Service

1. Clone service repo to workspace
2. Add to `docker-compose.yml`
3. Add health check to `scripts/utilities/check-health.sh`
4. Update Makefile if needed
5. Test with `make start`

### Updating Dependencies

```bash
# Update Go dependencies
cd <service-directory>
go get -u ./...
go mod tidy

# Update Docker images
make docker-build
```

### Backing Up Data

```bash
# Backup database
make db-backup

# Backup is saved to: framework/backups/
```

## 🔧 Available Tools & Scripts

### Setup Scripts (`scripts/setup/`)
- **install-deps.sh** - Automatically install all system dependencies (Docker, Go 1.25+, kubectl, Helm, etc.)
- **clone-repos.sh** - Clone all microservice repositories to workspace
- **install-tools.sh** - Install Go development tools and utilities
- **init-workspace.sh** - Initialize workspace structure and configuration

### Development Scripts (`scripts/dev/`)
- **restart-service.sh** - Quick restart of a specific service (with optional health check wait)
- **rebuild.sh** - Rebuild service with code changes
- **shell.sh** - Access service container shell for debugging
- **wait-for-services.sh** - Wait for all services to be healthy
- **create-service.sh** - Scaffold a new microservice with templates

### Database Scripts (`scripts/database/`)
- **seed.sh** - Populate database with test data
- **reset.sh** - Reset database (delete all data)
- **backup.sh** - Backup MongoDB with compression and timestamping
- **restore.sh** - Restore database from backup file
- **migrate.sh** - Run database migrations

### Testing Scripts (`scripts/testing/`)
- **run-unit-tests.sh** - Execute unit tests across all services
- **run-integration-tests.sh** - Run integration tests with real services
- **run-e2e-tests.sh** - End-to-end testing of complete workflows
- **run-load-tests.sh** - Performance and load testing
- **generate-test-data.sh** - Generate realistic test data

### Build Scripts (`scripts/build/`)
- **build-all.sh** - Build all microservices
- **build-service.sh** - Build a specific service
- **docker-build-all.sh** - Build all Docker images
- **docker-push-all.sh** - Push images to container registry

### Deployment Scripts (`scripts/deployment/`)
- **deploy-local.sh** - Deploy to local Kubernetes (minikube/kind)
- **deploy-dev.sh** - Deploy to development environment
- **port-forward.sh** - Setup port forwarding for K8s services
- **tunnel.sh** - Create tunnel to remote cluster

### Monitoring Scripts (`scripts/monitoring/`)
- **open-grafana.sh** - Open Grafana dashboards in browser
- **open-prometheus.sh** - Open Prometheus metrics UI
- **open-jaeger.sh** - Open Jaeger tracing UI
- **tail-logs.sh** - Real-time log streaming from all services

### Utility Scripts (`scripts/utilities/`)
- **cleanup.sh** - Clean up Docker resources
- **validate-env.sh** - Validate environment configuration
- **generate-jwt.sh** - Generate JWT tokens for testing
- **test-api.sh** - Quick API endpoint testing
- **check-health.sh** - Comprehensive health check of all services

### Configuration Files (`configs/`)
- **vscode/** - VS Code settings, debug configurations, extensions
- **git/pre-commit.sh** - Git pre-commit hooks for code quality
- **linting/** - Linter configurations (golangci-lint, shellcheck)

### Developer CLI Tool (`server/tools/cli/`)
Built with Go 1.25+ and Cobra, the `saas` CLI provides a user-friendly interface:

```bash
# Navigate to server directory
cd server

# Build the CLI
make build-cli

# Install system-wide
make install-cli

# Usage examples
saas setup          # Setup development environment
saas start          # Start all services
saas stop           # Stop all services
saas logs auth      # View auth service logs
saas test           # Run all tests
saas status         # Check service status
saas deploy local   # Deploy to local Kubernetes
```

## 🆘 Getting Help

1. Check [Troubleshooting Guide](docs/guides/TROUBLESHOOTING.md)
2. View service logs: `make logs-service SERVICE=<name>` (from server directory)
3. Check service health: `make status` (from server directory)
4. Review [Mermaid diagrams](docs/diagrams/) for architecture understanding
5. Read the [comprehensive documentation](docs/)
6. Open an issue on GitHub

## 🎓 Learning Resources

### Documentation
- [Getting Started Guide](docs/guides/GETTING_STARTED.md) - Step-by-step onboarding
- [Local Development Guide](docs/guides/LOCAL_DEVELOPMENT.md) - Daily workflow
- [Testing Guide](docs/guides/TESTING.md) - Testing strategies
- [Debugging Guide](docs/guides/DEBUGGING.md) - Troubleshooting tips
- [Tools Reference](docs/guides/TOOLS.md) - Complete tool documentation
- [Architecture Diagrams](docs/diagrams/) - Visual system overview

### Best Practices
- [Contributing Guidelines](CONTRIBUTING.md) - Coding standards and workflow
- [Changelog](CHANGELOG.md) - Version history and updates
- Pre-commit hooks for code quality enforcement
- golangci-lint for Go code standards
- shellcheck for shell script best practices

## 📊 Code Quality & Standards

This repository follows industry best practices:

- **Go**: Version 1.25+, follows official Go style guide (see `server/.golangci.yml`)
- **Linting**: golangci-lint with strict rules
- **Testing**: Unit tests with >80% coverage target
- **Shell Scripts**: ShellCheck validated, includes error handling
- **Git Hooks**: Automated pre-commit checks (see `server/configs/git/`)
- **Documentation**: Comprehensive inline comments and external docs
- **Security**: Regular dependency updates, no hardcoded secrets

## 📄 License

This project is licensed under the MIT License - see [LICENSE](../LICENSE) file for details.

## 🔗 Links

- [Main Repository](https://github.com/vhvplatform/go-framework-go)
- [Shared Library](https://github.com/vhvplatform/go-shared-go)
- [Infrastructure](https://github.com/vhvplatform/go-infrastructure)

---

<p align="center">
  Made with ❤️ for developers who want to move fast
</p>
