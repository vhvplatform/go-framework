# Architecture Documentation

Technical architecture and design documentation for the go-devtools repository and the SaaS platform it supports.

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Design Philosophy](#design-philosophy)
- [Tool Organization](#tool-organization)
- [Docker Compose Architecture](#docker-compose-architecture)
- [Service Interactions](#service-interactions)
- [Extension Points](#extension-points)
- [Integration Patterns](#integration-patterns)
- [Development Workflow](#development-workflow)

---

## Overview

The go-devtools repository provides a comprehensive development environment for the SaaS Platform microservices. It follows a **tools-as-code** approach where all development operations are scripted, versioned, and automated.

### Core Principles

1. **Convention over Configuration** - Sensible defaults, minimal setup required
2. **Single Command Operations** - Complex tasks wrapped in simple commands
3. **Idempotent Scripts** - Safe to run multiple times
4. **Cross-Platform Support** - Works on macOS, Linux, and Windows/WSL2
5. **Fail-Fast** - Clear error messages and early validation

### Architecture Layers

```
┌─────────────────────────────────────────────────┐
│           Developer Interface Layer              │
│  (Makefile - Single entry point for all ops)    │
└─────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────┐
│         Automation Script Layer                  │
│  (Shell scripts organized by function)           │
└─────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────┐
│      Container Orchestration Layer               │
│   (Docker Compose - Service definitions)        │
└─────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────┐
│         Infrastructure Layer                     │
│  (Docker Engine - Runtime environment)           │
└─────────────────────────────────────────────────┘
```

---

## Directory Structure

### Root Level

```
go-devtools/
├── Makefile                    # Primary interface - all commands
├── README.md                   # Quick start and overview
├── CONTRIBUTING.md             # Contribution guidelines
├── CHANGELOG.md                # Version history
│
├── scripts/                    # Automation scripts (see below)
├── docker/                     # Docker Compose configurations
├── configs/                    # Tool and IDE configurations
├── docs/                       # Documentation
├── fixtures/                   # Test data and fixtures
├── postman/                    # API testing collections
├── tools/                      # Developer CLI tools
│
└── .gitignore                  # Git ignore patterns
```

### Scripts Directory Organization

Scripts are organized by **functional domain** for easy discovery:

```
scripts/
├── setup/                      # One-time setup operations
│   ├── install-deps.sh         # Install system dependencies
│   ├── install-tools.sh        # Install Go development tools
│   ├── clone-repos.sh          # Clone service repositories
│   └── init-workspace.sh       # Initialize workspace structure
│
├── dev/                        # Daily development operations
│   ├── wait-for-services.sh    # Health check orchestration
│   ├── restart-service.sh      # Quick service restart
│   ├── rebuild.sh              # Rebuild and restart service
│   └── shell.sh                # Access container shell
│
├── database/                   # Database operations
│   ├── seed.sh                 # Load test data
│   ├── reset.sh                # Reset to clean state
│   ├── backup.sh               # Create backup
│   ├── restore.sh              # Restore from backup
│   └── migrate.sh              # Run migrations
│
├── testing/                    # Test automation
│   ├── run-unit-tests.sh       # Unit test runner
│   ├── run-integration-tests.sh # Integration test runner
│   ├── run-e2e-tests.sh        # End-to-end test runner
│   ├── run-load-tests.sh       # Load test runner
│   └── generate-test-data.sh   # Test data generator
│
├── build/                      # Build operations
│   ├── build-all.sh            # Build all services
│   ├── build-service.sh        # Build specific service
│   ├── docker-build-all.sh     # Build all Docker images
│   └── docker-push-all.sh      # Push images to registry
│
├── deployment/                 # Deployment operations
│   ├── deploy-local.sh         # Local Kubernetes deployment
│   ├── deploy-dev.sh           # Development environment
│   ├── port-forward.sh         # Port forwarding setup
│   └── tunnel.sh               # Secure tunnel creation
│
├── monitoring/                 # Monitoring utilities
│   ├── open-grafana.sh         # Open Grafana dashboard
│   ├── open-prometheus.sh      # Open Prometheus UI
│   ├── open-jaeger.sh          # Open Jaeger tracing
│   └── tail-logs.sh            # Stream service logs
│
└── utilities/                  # General utilities
    ├── check-health.sh         # Health check all services
    ├── cleanup.sh              # Clean Docker resources
    ├── validate-env.sh         # Validate configuration
    ├── generate-jwt.sh         # Generate test JWT token
    └── test-api.sh             # Quick API test
```

**Design Rationale:**
- **Discoverability** - Clear naming makes finding the right tool easy
- **Separation of Concerns** - Each script has a single, well-defined purpose
- **Composability** - Scripts can be combined via Makefile targets
- **Maintainability** - Changes are localized to specific domains

### Docker Directory

```
docker/
├── docker-compose.yml          # Main service definitions
├── docker-compose.dev.yml      # Development overrides (hot-reload)
├── docker-compose.test.yml     # Testing configuration
├── .env.example                # Environment template
└── .env                        # Local environment (git-ignored)
```

**Composition Strategy:**
- Base (`docker-compose.yml`) defines production-like setup
- Dev overlay (`docker-compose.dev.yml`) adds development features
- Test overlay (`docker-compose.test.yml`) optimizes for testing
- Compose files are merged: `docker-compose -f base.yml -f overlay.yml`

---

## Design Philosophy

### 1. Progressive Enhancement

The devtools support multiple levels of usage:

```
Beginner:  make start, make test, make logs
           ↓
Intermediate: SERVICE=auth make restart-service
           ↓
Advanced: Direct script invocation with custom parameters
           ↓
Expert: Custom Docker Compose overlays and extensions
```

### 2. Fail-Fast with Clear Errors

Every script includes:
- **Prerequisite checks** - Verify dependencies exist
- **Clear error messages** - Explain what went wrong and how to fix
- **Exit codes** - Proper codes for automation

Example:
```bash
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "📖 Install: https://docs.docker.com/get-docker/"
    exit 1
fi
```

### 3. Idempotency

Scripts are safe to run multiple times:
- Check if action is needed before executing
- Clean up previous state if necessary
- No side effects from multiple runs

Example:
```bash
# Clone only if not already cloned
if [ ! -d "$TARGET_DIR" ]; then
    git clone "$REPO_URL" "$TARGET_DIR"
else
    echo "Repository already exists, skipping..."
fi
```

### 4. Configuration via Environment

All configuration through environment variables:
- **Defaults** for zero-config experience
- **Override** for customization
- **Validation** to catch misconfigurations early

```bash
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"
```

---

## Tool Organization

### Makefile as Interface

The Makefile serves as the **unified interface** to all operations:

```makefile
# User-facing command
setup: ## Setup complete development environment
	@./scripts/setup/install-deps.sh
	@./scripts/setup/clone-repos.sh
	@./scripts/setup/install-tools.sh
	@./scripts/setup/init-workspace.sh
```

**Benefits:**
- **Discoverability** - `make help` shows all available commands
- **Documentation** - Help text describes each command
- **Consistency** - Same interface across platforms
- **Composition** - Combine multiple operations

### Shell Scripts as Implementation

Scripts implement the actual logic:

**Standard Script Template:**
```bash
#!/bin/bash
set -e  # Exit on error

# Description: What this script does
# Usage: ./script.sh [options]
# Environment variables:
#   VAR_NAME - Description (default: value)

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "${GREEN}Starting operation...${NC}"

# Validation
if [ condition ]; then
    echo "${RED}Error: Something wrong${NC}"
    exit 1
fi

# Main logic
# ...

echo "${GREEN}✅ Operation complete!${NC}"
```

---

## Docker Compose Architecture

### Service Definition Pattern

Each microservice follows a consistent pattern:

```yaml
service-name:
  image: vhvcorp/service-name:latest
  container_name: service-name
  environment:
    - ENV_VAR=value
  ports:
    - "8080:8080"
  depends_on:
    - mongodb
    - redis
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval: 10s
    timeout: 5s
    retries: 5
  networks:
    - saas-network
  restart: unless-stopped
```

**Key Components:**
- **Health Checks** - Ensure service readiness
- **Dependencies** - Startup ordering
- **Networks** - Service isolation and communication
- **Restart Policy** - Resilience

### Network Architecture

```
┌─────────────────────────────────────────────┐
│          External Network (Bridge)           │
│  - Exposed ports for local development       │
└─────────────────────────────────────────────┘
                    │
┌─────────────────────────────────────────────┐
│        Internal Network (saas-network)       │
│  - Service-to-service communication          │
│  - Database access                           │
│  - Message queue                             │
└─────────────────────────────────────────────┘
```

**Design Benefits:**
- **Isolation** - Services communicate through defined network
- **Security** - Internal services not externally accessible
- **Flexibility** - Easy to modify network topology

---

## Service Interactions

### Request Flow

```
User/Client
    │
    ▼
API Gateway :8080
    │
    ├─────▶ Auth Service :8081 (gRPC :50051)
    │           └───▶ MongoDB
    │           └───▶ Redis (sessions)
    │
    ├─────▶ User Service :8082 (gRPC :50052)
    │           └───▶ MongoDB
    │
    ├─────▶ Tenant Service :8083 (gRPC :50053)
    │           └───▶ MongoDB
    │
    ├─────▶ Notification Service :8084 (gRPC :50054)
    │           └───▶ RabbitMQ
    │           └───▶ MongoDB
    │
    └─────▶ System Config Service :8085 (gRPC :50055)
                └───▶ MongoDB
                └───▶ Redis (cache)
```

### Observability Flow

```
All Services
    │
    ├───▶ Prometheus :9090 (metrics scraping)
    │         └───▶ Grafana :3000 (visualization)
    │
    └───▶ Jaeger :16686 (tracing)
```

### Data Flow

```
Services
    │
    ├───▶ MongoDB :27017 (persistent storage)
    │
    ├───▶ Redis :6379 (caching, sessions)
    │
    └───▶ RabbitMQ :5672 (async messaging)
              └───▶ Management UI :15672
```

---

## Extension Points

### Adding a New Service

**1. Add to docker-compose.yml:**
```yaml
new-service:
  image: vhvcorp/new-service:latest
  container_name: new-service
  environment:
    - CONFIG_VAR=value
  ports:
    - "8086:8080"
  depends_on:
    - mongodb
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  networks:
    - saas-network
```

**2. Update health check script:**
```bash
# scripts/utilities/check-health.sh
check_service "new-service" "http://localhost:8086/health"
```

**3. Add Makefile targets if needed:**
```makefile
logs-new-service: ## View new service logs
	@cd docker && docker-compose logs -f new-service
```

**4. Update documentation:**
- Add to service list in README.md
- Document in TOOLS.md
- Update ARCHITECTURE.md

### Adding a New Script

**1. Create script in appropriate directory:**
```bash
# scripts/utilities/my-new-script.sh
#!/bin/bash
set -e

echo "🔧 Doing something useful..."
# ... implementation ...
echo "✅ Done!"
```

**2. Make executable:**
```bash
chmod +x scripts/utilities/my-new-script.sh
```

**3. Add Makefile target:**
```makefile
my-command: ## Description of what it does
	@./scripts/utilities/my-new-script.sh
```

**4. Document:**
- Add to TOOLS.md with usage examples
- Update README.md if it's a commonly-used command

### Custom Docker Compose Overlay

Create `docker/docker-compose.local.yml`:

```yaml
version: '3.8'

services:
  auth-service:
    environment:
      - DEBUG=true
      - CUSTOM_VAR=custom_value
    volumes:
      - ../custom-configs:/configs
```

Use with:
```bash
docker-compose -f docker-compose.yml -f docker-compose.local.yml up
```

---

## Integration Patterns

### IDE Integration (VS Code)

```
configs/vscode/
├── settings.json               # Workspace settings
├── launch.json                 # Debug configurations
├── tasks.json                  # Task automation
└── extensions.json             # Recommended extensions
```

**Integration Points:**
- Debug configurations for each service
- Tasks for common operations (build, test, deploy)
- Settings for consistent formatting

### CI/CD Integration

The devtools can be used in CI/CD pipelines:

```yaml
# .github/workflows/test.yml
- name: Setup dev environment
  run: |
    cd devtools
    make setup
    make start

- name: Run tests
  run: |
    cd devtools
    make test
```

### Infrastructure as Code Integration

Links with `go-infrastructure` repository:

```
go-infrastructure/
└── kubernetes/
    ├── base/                   # Base K8s manifests
    ├── overlays/
    │   ├── dev/               # Development
    │   └── prod/              # Production
    └── helm/                   # Helm charts
```

Devtools deployment scripts use these manifests.

---

## Development Workflow

### Typical Developer Journey

```
1. Clone and Setup
   make setup
   ↓
2. Start Services
   make start
   ↓
3. Load Test Data
   make db-seed
   ↓
4. Develop
   - Edit code in service repo
   - Hot reload (dev mode) or rebuild
   make rebuild SERVICE=my-service
   ↓
5. Test
   make test-unit
   make test-integration
   ↓
6. Debug
   - View logs: make logs-service
   - Use VS Code debugger
   - Check monitoring: make open-grafana
   ↓
7. Commit
   git commit (hooks run validation)
   ↓
8. Deploy
   make deploy-local  # Test in K8s
```

### Hot Reload Workflow (Development Mode)

```bash
# Start with dev mode
make start-dev

# This mounts source code into containers
# Changes are automatically detected and services reload
```

**Implementation:**
- Uses `air` for Go hot reload
- Mounts source directories as volumes
- Watches for file changes
- Rebuilds and restarts automatically

---

## Design Decisions

### Why Shell Scripts?

**Pros:**
- Universal availability (all Unix-like systems)
- No runtime dependencies
- Easy to read and understand
- Direct system access
- Great for orchestration

**Cons:**
- Limited error handling compared to Python/Go
- Platform differences (mitigated with careful coding)

**Mitigation:**
- Use `set -e` for error handling
- Test on multiple platforms
- Provide clear error messages
- Use POSIX-compatible features when possible

### Why Docker Compose (not Kubernetes for local dev)?

**Rationale:**
- **Simplicity** - Easier to learn and use
- **Resource Efficient** - Lower overhead
- **Fast Startup** - Quicker than K8s for local development
- **Debug Friendly** - Direct container access
- **Production Parity** - K8s deployment via separate scripts

**Trade-off:**
- Doesn't test K8s-specific features locally
- Solution: Provide `make deploy-local` for K8s testing when needed

### Why Makefile as Interface?

**Rationale:**
- **Standard Tool** - Available everywhere
- **Self-Documenting** - `make help` shows commands
- **Shell Independence** - Works regardless of user's shell
- **Composability** - Easy to chain commands
- **Tab Completion** - Supported by shells

---

## Performance Considerations

### Script Performance

- **Parallel Operations** - Multiple services can be processed concurrently
- **Caching** - Go modules cached, Docker layers cached
- **Lazy Loading** - Only start services you need
- **Incremental Builds** - Only rebuild changed services

### Resource Usage

**Default Resource Allocation:**
- Docker: 4 CPUs, 8GB RAM recommended
- Minimal: 2 CPUs, 4GB RAM (reduced functionality)

**Optimization Strategies:**
- Start only needed services
- Use `make stop-keep-data` to preserve state
- Clean unused Docker resources: `make clean`

---

## Security Considerations

### Secrets Management

- **No secrets in git** - .env is git-ignored
- **Example file** - .env.example shows structure without secrets
- **Documentation** - Warn to change default secrets
- **JWT_SECRET** - Must be changed for production

### Container Security

- **Non-root Users** - Services run as non-root when possible
- **Resource Limits** - Memory and CPU limits defined
- **Network Isolation** - Internal network for service communication
- **Health Checks** - Detect and restart unhealthy containers

---

## Future Extensibility

### Planned Extension Points

1. **Plugin System** - Custom scripts discoverable via naming convention
2. **Hooks** - Pre/post hooks for major operations
3. **Profiles** - Different environment profiles (minimal, full, custom)
4. **Remote Development** - Support for remote Docker hosts

### Backward Compatibility

- **Semantic Versioning** - Major version for breaking changes
- **Deprecation Warnings** - Warn before removing features
- **Migration Guides** - Document changes in CHANGELOG.md

---

## See Also

- [DEVELOPMENT.md](DEVELOPMENT.md) - Development practices
- [TOOLS.md](TOOLS.md) - Tool reference
- [SETUP.md](SETUP.md) - Installation guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines

---

**Last Updated:** 2024-01-15  
**Architecture Version:** 1.0
