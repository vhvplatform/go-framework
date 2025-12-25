# Architecture Documentation

Technical architecture and design documentation for the go-devtools repository and the SaaS platform it supports.

## 📊 Visual Diagrams

For visual learners, we provide PlantUML diagrams showing the system architecture:

- **[System Architecture Diagram](diagrams/system-architecture.puml)** - Complete microservices architecture
- **[Installation Flow Diagram](diagrams/installation-flow.puml)** - Step-by-step setup process
- **[Data Flow Diagram](diagrams/data-flow.puml)** - Request/response sequences

To view these diagrams:
```bash
# Install PlantUML
brew install plantuml  # macOS
sudo apt-get install plantuml  # Linux

# Generate images
cd docs/diagrams
plantuml *.puml

# View the generated PNG files
open *.png  # macOS
xdg-open *.png  # Linux
```

Or view online: Copy the `.puml` file content to [PlantUML Web Server](http://www.plantuml.com/plantuml/uml/)

See [diagrams/README.md](diagrams/README.md) for detailed instructions.

## Table of Contents

- [Visual Diagrams](#-visual-diagrams)
- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Design Philosophy](#design-philosophy)
- [Tool Organization](#tool-organization)
- [Docker Compose Architecture](#docker-compose-architecture)
- [Service Interactions](#service-interactions)
- [Detailed Service Architecture](#detailed-service-architecture)
- [Real-World Scenarios](#real-world-scenarios)
- [Configuration Management](#configuration-management)
- [Performance Optimization](#performance-optimization)
- [Disaster Recovery](#disaster-recovery)
- [Extension Points](#extension-points)
- [Integration Patterns](#integration-patterns)
- [Development Workflow](#development-workflow)

---

## Overview

The go-devtools repository provides a comprehensive development environment for the SaaS Platform microservices. It follows a **tools-as-code** approach where all development operations are scripted, versioned, and automated.

### Quick Start

Use our interactive setup script for easy installation:

```bash
# Clone the repository
git clone https://github.com/vhvcorp/go-devtools.git
cd go-devtools

# Run interactive setup (with prompts)
./scripts/setup/interactive-setup.sh

# Or quick setup (no prompts, all defaults)
./scripts/setup/interactive-setup.sh --quick

# Or with custom options
./scripts/setup/interactive-setup.sh \
  --workspace ~/my-workspace \
  --skip-seed \
  --jwt-secret "my-custom-secret"
```

See [Installation Flow Diagram](diagrams/installation-flow.puml) for the complete setup process visualization.

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

## Detailed Service Architecture

### Microservices Overview

The platform consists of 6 core microservices following a hexagonal (ports and adapters) architecture:

```
┌────────────────────────────────────────────────────────────────┐
│                        API Gateway                              │
│  Port: 8080 (HTTP/REST)                                        │
│  - Authentication middleware                                    │
│  - Request routing and load balancing                          │
│  - Rate limiting and throttling                                │
│  - Response caching                                            │
└────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│ Auth Service │      │ User Service │     │Tenant Service│
│ Port: 8081   │      │ Port: 8082   │     │ Port: 8083   │
│ gRPC: 50051  │      │ gRPC: 50052  │     │ gRPC: 50053  │
└──────────────┘      └──────────────┘     └──────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│Notification  │      │System Config │     │   MongoDB    │
│Service       │      │Service       │     │ Port: 27017  │
│Port: 8084    │      │Port: 8085    │     │              │
│gRPC: 50054   │      │gRPC: 50055   │     └──────────────┘
└──────────────┘      └──────────────┘
        │                     │
        ▼                     ▼
┌──────────────┐      ┌──────────────┐
│  RabbitMQ    │      │    Redis     │
│ Port: 5672   │      │ Port: 6379   │
│ Mgmt: 15672  │      │              │
└──────────────┘      └──────────────┘
```

### Service Responsibilities

#### 1. API Gateway
**Purpose:** Single entry point for all client requests

**Key Functions:**
- HTTP to gRPC protocol translation
- JWT token validation
- Request/response transformation
- Cross-cutting concerns (logging, monitoring, tracing)

**Technology Stack:**
- Go 1.21+
- Gin web framework
- gRPC client connections

**Example Request Flow:**
```go
// Client Request
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

// API Gateway processes:
1. Validates request format
2. Forwards to Auth Service via gRPC
3. Receives gRPC response
4. Transforms to HTTP response
5. Returns to client

// Response
HTTP 200 OK
{
  "token": "eyJhbGc...",
  "user": {
    "id": "user-123",
    "email": "user@example.com"
  }
}
```

#### 2. Auth Service
**Purpose:** Authentication and authorization

**Key Functions:**
- User authentication (login, logout)
- JWT token generation and validation
- Password hashing (bcrypt)
- Session management
- OAuth2 integration (future)

**Data Storage:**
- MongoDB: User credentials, permissions
- Redis: Active sessions, token blacklist

**Example Authentication Flow:**
```
1. Client → API Gateway: POST /api/auth/login
   Body: {"email": "...", "password": "..."}

2. API Gateway → Auth Service: LoginRequest gRPC
   
3. Auth Service:
   a. Fetch user from MongoDB
   b. Verify password with bcrypt
   c. Generate JWT token
   d. Store session in Redis
   e. Return LoginResponse

4. Auth Service → API Gateway: LoginResponse
   Token: eyJhbGc...
   User: {...}

5. API Gateway → Client: HTTP 200
   JSON response with token
```

**Configuration Example:**
```yaml
# auth-service/config.yaml
server:
  http_port: 8081
  grpc_port: 50051
  
jwt:
  secret: ${JWT_SECRET}
  expiration: 24h
  issuer: "saas-platform"
  
database:
  mongodb_uri: "mongodb://mongodb:27017"
  database_name: "go_dev"
  
redis:
  url: "redis://redis:6379/0"
  session_ttl: 86400  # 24 hours
```

#### 3. User Service
**Purpose:** User profile and management

**Key Functions:**
- User CRUD operations
- Profile management
- User search and filtering
- Role assignment
- Activity logging

**Data Model:**
```go
type User struct {
    ID        string    `bson:"_id" json:"id"`
    Email     string    `bson:"email" json:"email"`
    Name      string    `bson:"name" json:"name"`
    Avatar    string    `bson:"avatar" json:"avatar"`
    TenantID  string    `bson:"tenant_id" json:"tenant_id"`
    Roles     []string  `bson:"roles" json:"roles"`
    Status    string    `bson:"status" json:"status"`
    CreatedAt time.Time `bson:"created_at" json:"created_at"`
    UpdatedAt time.Time `bson:"updated_at" json:"updated_at"`
}
```

**API Examples:**
```bash
# Get user by ID
grpcurl -d '{"user_id": "user-123"}' \
  localhost:50052 user.UserService/GetUser

# Update user profile
grpcurl -d '{
  "user_id": "user-123",
  "name": "New Name",
  "avatar": "https://..."
}' localhost:50052 user.UserService/UpdateUser

# List users with pagination
grpcurl -d '{
  "tenant_id": "tenant-1",
  "page": 1,
  "page_size": 20
}' localhost:50052 user.UserService/ListUsers
```

#### 4. Tenant Service
**Purpose:** Multi-tenancy management

**Key Functions:**
- Tenant creation and configuration
- Subscription management
- Feature flags per tenant
- Tenant isolation
- Billing integration (future)

**Data Model:**
```go
type Tenant struct {
    ID          string            `bson:"_id" json:"id"`
    Name        string            `bson:"name" json:"name"`
    Slug        string            `bson:"slug" json:"slug"`
    Plan        string            `bson:"plan" json:"plan"`
    Status      string            `bson:"status" json:"status"`
    Settings    map[string]string `bson:"settings" json:"settings"`
    Features    []string          `bson:"features" json:"features"`
    MaxUsers    int               `bson:"max_users" json:"max_users"`
    CreatedAt   time.Time         `bson:"created_at" json:"created_at"`
}
```

**Tenant Isolation Strategy:**
```
Database Level:
- Separate MongoDB collections per tenant
- Tenant ID in every query
- Database indexes on tenant_id

Application Level:
- Tenant context in every request
- Middleware validates tenant access
- Cross-tenant queries prevented

Example Query:
db.users.find({
  "tenant_id": "tenant-123",
  "status": "active"
})
```

#### 5. Notification Service
**Purpose:** Asynchronous notification delivery

**Key Functions:**
- Email notifications
- SMS notifications (future)
- Push notifications (future)
- Notification templates
- Delivery tracking
- Retry logic

**Architecture Pattern:** Event-driven with message queue

**Flow Diagram:**
```
Service A                Notification Service
   │                            │
   │  Publish Event             │
   ├───────────────────────────▶│
   │  UserCreated               │
   │                            │
   │                     RabbitMQ Queue
   │                            │
   │                      ┌─────▼─────┐
   │                      │  Consumer  │
   │                      │  Workers   │
   │                      └─────┬─────┘
   │                            │
   │                      Process Event
   │                            │
   │                      Generate Email
   │                            │
   │                      Send via SMTP
   │                            │
   │                      Store in DB
   │                            ▼
```

**Event Example:**
```json
{
  "event_type": "user.created",
  "tenant_id": "tenant-123",
  "user_id": "user-456",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "email": "newuser@example.com",
    "name": "New User"
  },
  "notification_template": "welcome_email"
}
```

**RabbitMQ Configuration:**
```yaml
# Queues
queues:
  - name: notifications.email
    durable: true
    auto_delete: false
    
  - name: notifications.sms
    durable: true
    auto_delete: false

# Exchanges
exchanges:
  - name: notifications
    type: topic
    durable: true

# Bindings
bindings:
  - exchange: notifications
    queue: notifications.email
    routing_key: "email.*"
```

#### 6. System Config Service
**Purpose:** Centralized configuration management

**Key Functions:**
- Application settings
- Feature flags
- A/B testing configuration
- Cache management
- Configuration versioning

**Caching Strategy:**
```
Request Flow:
1. Client requests config
2. Check Redis cache
   - If hit: Return cached value (fast)
   - If miss: Fetch from MongoDB
3. Store in Redis with TTL
4. Return to client

Cache Keys:
- config:tenant:{tenant_id}:{key}
- config:global:{key}
- features:{tenant_id}

TTL Strategy:
- Global configs: 1 hour
- Tenant configs: 30 minutes
- Feature flags: 5 minutes
```

**Example Configs:**
```json
// Global Configuration
{
  "key": "smtp.settings",
  "value": {
    "host": "smtp.example.com",
    "port": 587,
    "from": "noreply@example.com"
  },
  "scope": "global"
}

// Tenant Configuration
{
  "key": "max_file_upload_size",
  "value": "10MB",
  "tenant_id": "tenant-123",
  "scope": "tenant"
}

// Feature Flag
{
  "key": "feature.new_dashboard",
  "value": true,
  "tenant_id": "tenant-123",
  "scope": "feature"
}
```

### Infrastructure Services

#### MongoDB
**Purpose:** Primary data store

**Collections:**
```
go_dev/
├── users           # User profiles
├── tenants         # Tenant information
├── sessions        # User sessions (temporary)
├── notifications   # Notification history
├── configs         # System configurations
├── audit_logs      # Activity audit trail
└── migrations      # Database version tracking
```

**Indexes:**
```javascript
// users collection
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "tenant_id": 1, "status": 1 })
db.users.createIndex({ "created_at": -1 })

// tenants collection
db.tenants.createIndex({ "slug": 1 }, { unique: true })
db.tenants.createIndex({ "status": 1 })

// audit_logs collection
db.audit_logs.createIndex({ "tenant_id": 1, "created_at": -1 })
db.audit_logs.createIndex({ "user_id": 1, "action": 1 })
```

**Backup Strategy:**
```bash
# Automated daily backups
0 2 * * * /scripts/database/backup.sh

# Retention policy
- Daily backups: 7 days
- Weekly backups: 4 weeks
- Monthly backups: 12 months
```

#### Redis
**Purpose:** Caching and session storage

**Key Patterns:**
```
# Session keys
session:{session_id} → User session data
TTL: 24 hours

# Token blacklist
blacklist:token:{token_id} → "revoked"
TTL: Token expiration time

# Cache keys
cache:user:{user_id} → User object
cache:config:{key} → Config value
TTL: 30 minutes

# Rate limiting
ratelimit:{ip}:{endpoint} → Request count
TTL: 1 minute
```

**Memory Management:**
```
# Redis configuration
maxmemory 2gb
maxmemory-policy allkeys-lru

# Eviction strategy
- LRU eviction when memory limit reached
- Prioritize session data over cache
- Monitor memory usage via metrics
```

#### RabbitMQ
**Purpose:** Asynchronous message queue

**Queue Structure:**
```
Exchange: notifications (topic)
    │
    ├─→ notifications.email (queue)
    │   └─ Routing key: email.*
    │
    ├─→ notifications.sms (queue)
    │   └─ Routing key: sms.*
    │
    └─→ notifications.push (queue)
        └─ Routing key: push.*

Exchange: events (fanout)
    │
    ├─→ audit.logs (queue)
    ├─→ analytics.events (queue)
    └─→ webhooks.dispatch (queue)
```

**Message Format:**
```json
{
  "message_id": "msg-uuid-123",
  "timestamp": "2024-01-15T10:30:00Z",
  "type": "user.created",
  "tenant_id": "tenant-123",
  "payload": {
    "user_id": "user-456",
    "email": "user@example.com"
  },
  "metadata": {
    "source": "user-service",
    "correlation_id": "req-123"
  }
}
```

**Consumer Configuration:**
```yaml
# Consumer settings
prefetch_count: 10        # Process 10 messages at a time
auto_ack: false          # Manual acknowledgment
requeue_on_error: true   # Retry failed messages

# Dead letter exchange
dead_letter_exchange: dlx
dead_letter_routing_key: failed

# Max retries: 3
# Retry backoff: exponential (1s, 2s, 4s)
```

### Observability Stack

#### Prometheus
**Purpose:** Metrics collection and alerting

**Metrics Collected:**
```
# HTTP metrics
http_requests_total
http_request_duration_seconds
http_response_size_bytes

# gRPC metrics
grpc_server_handled_total
grpc_server_handling_seconds

# Business metrics
user_registrations_total
login_attempts_total
notifications_sent_total

# System metrics
go_goroutines
go_memstats_alloc_bytes
process_cpu_seconds_total
```

**Scrape Configuration:**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
    
  - job_name: 'auth-service'
    static_configs:
      - targets: ['auth-service:8081']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

**Alert Rules:**
```yaml
# alerts.yml
groups:
  - name: service_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          
      - alert: ServiceDown
        expr: up{job="api-gateway"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "API Gateway is down"
```

#### Grafana
**Purpose:** Metrics visualization

**Pre-configured Dashboards:**

1. **Service Overview Dashboard**
```
- Request rate (req/s)
- Response time (p50, p95, p99)
- Error rate (%)
- Active connections
- Service health status
```

2. **Resource Usage Dashboard**
```
- CPU usage per service
- Memory usage per service
- Goroutine count
- GC pause time
- Network I/O
```

3. **Business Metrics Dashboard**
```
- User registrations (daily)
- Active users
- API calls per endpoint
- Notification delivery rate
- Tenant growth
```

#### Jaeger
**Purpose:** Distributed tracing

**Trace Example:**
```
Trace ID: abc123
Duration: 245ms
Spans: 8

┌─ HTTP GET /api/users/123 (API Gateway) [245ms]
│  ├─ Validate JWT (API Gateway) [5ms]
│  ├─ gRPC GetUser (User Service) [220ms]
│  │  ├─ MongoDB Find Query [200ms]
│  │  │  └─ Index Scan: users.email [195ms]
│  │  └─ Object Mapping [20ms]
│  └─ Response Serialization [20ms]
```

**Trace Context Propagation:**
```go
// API Gateway injects trace context
ctx = context.WithValue(ctx, "trace_id", traceID)
ctx = context.WithValue(ctx, "span_id", spanID)

// User Service extracts trace context
traceID := ctx.Value("trace_id").(string)
parentSpanID := ctx.Value("span_id").(string)

// Creates child span
childSpan := tracer.StartSpan(
    "GetUser",
    opentracing.ChildOf(parentSpanID),
)
```

## Real-World Scenarios

### Scenario 1: User Registration Flow

**Complete Request Flow:**
```
1. Client → API Gateway
   POST /api/auth/register
   {
     "email": "new@example.com",
     "password": "secure123",
     "name": "New User",
     "tenant_id": "tenant-123"
   }

2. API Gateway → Auth Service (gRPC)
   RegisterRequest {
     email: "new@example.com"
     password_hash: "$2a$10$..." (bcrypt)
     name: "New User"
     tenant_id: "tenant-123"
   }

3. Auth Service → MongoDB
   - Check email uniqueness
   - Create user document
   - Generate activation token

4. Auth Service → RabbitMQ
   Publish event: {
     type: "user.created",
     user_id: "user-789",
     email: "new@example.com"
   }

5. Notification Service ← RabbitMQ
   - Consume event
   - Generate welcome email
   - Send via SMTP
   - Update delivery status

6. Auth Service → API Gateway
   RegisterResponse {
     user_id: "user-789",
     status: "pending_activation"
   }

7. API Gateway → Client
   HTTP 201 Created
   {
     "user_id": "user-789",
     "message": "Check email for activation"
   }

Total Duration: ~300ms
- Registration: 50ms
- Email queued: 5ms
- Email delivery: async (2-5s)
```

### Scenario 2: Authenticated API Call

**Request with JWT:**
```
1. Client → API Gateway
   GET /api/users/profile
   Authorization: Bearer eyJhbGc...

2. API Gateway Middleware
   - Extract JWT from header
   - Validate signature
   - Check expiration
   - Extract user_id, tenant_id
   - Check Redis for token blacklist
   Duration: 5ms

3. API Gateway → User Service (gRPC)
   GetUserRequest {
     user_id: "user-123",
     tenant_id: "tenant-456"
   }

4. User Service → Redis
   - Check cache: cache:user:user-123
   - Cache HIT: Return cached data
   Duration: 2ms

5. User Service → API Gateway
   UserResponse {
     user: {...}
   }

6. API Gateway → Client
   HTTP 200 OK
   {
     "user": {
       "id": "user-123",
       "email": "user@example.com",
       "name": "User Name"
     }
   }

Total Duration: ~10ms (with cache)
Without cache: ~50ms (MongoDB query)
```

### Scenario 3: Multi-Service Transaction

**Creating Tenant with Admin User:**
```
1. Client → API Gateway
   POST /api/tenants
   {
     "name": "Acme Corp",
     "slug": "acme",
     "plan": "enterprise",
     "admin_email": "admin@acme.com"
   }

2. API Gateway → Tenant Service
   - Create tenant record
   - Set default configuration
   - Initialize feature flags
   Duration: 30ms

3. Tenant Service → User Service
   - Create admin user
   - Assign admin role
   - Link to tenant
   Duration: 40ms

4. Tenant Service → System Config Service
   - Create tenant-specific configs
   - Initialize settings
   Duration: 20ms

5. Tenant Service → RabbitMQ
   - Publish tenant.created event
   - Publish user.created event

6. Multiple Consumers Process Events:
   - Notification: Send welcome email
   - Audit: Log tenant creation
   - Analytics: Track new signup
   - Webhooks: Notify integrations

7. Response to Client
   HTTP 201 Created
   {
     "tenant_id": "tenant-789",
     "admin_user_id": "user-999",
     "status": "active"
   }

Total Duration: ~100ms (synchronous)
Async processing: 2-10s
```

## Configuration Management

### Environment Variables

**Complete .env Example:**
```bash
# Application
ENVIRONMENT=development
LOG_LEVEL=debug
APP_NAME=saas-platform

# API Gateway
API_GATEWAY_PORT=8080
API_GATEWAY_TIMEOUT=30s
API_GATEWAY_MAX_BODY_SIZE=10MB

# Service URLs (gRPC)
AUTH_SERVICE_URL=auth-service:50051
USER_SERVICE_URL=user-service:50052
TENANT_SERVICE_URL=tenant-service:50053
NOTIFICATION_SERVICE_URL=notification-service:50054
SYSTEM_CONFIG_SERVICE_URL=system-config-service:50055

# JWT Configuration
JWT_SECRET=change-this-in-production-very-important
JWT_EXPIRATION=24h
JWT_ISSUER=saas-platform
JWT_ALGORITHM=HS256

# MongoDB
MONGODB_URI=mongodb://mongodb:27017
MONGODB_DATABASE=go_dev
MONGODB_MAX_POOL_SIZE=100
MONGODB_MIN_POOL_SIZE=10
MONGODB_MAX_IDLE_TIME=60s

# Redis
REDIS_URL=redis://redis:6379/0
REDIS_PASSWORD=
REDIS_MAX_RETRIES=3
REDIS_POOL_SIZE=10

# RabbitMQ
RABBITMQ_URL=******rabbitmq:5672/
RABBITMQ_USERNAME=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_VHOST=/
RABBITMQ_PREFETCH=10

# SMTP (for notifications)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=notifications@example.com
SMTP_PASSWORD=smtp-password
SMTP_FROM=noreply@example.com
SMTP_TLS=true

# Observability
PROMETHEUS_PORT=9090
PROMETHEUS_SCRAPE_INTERVAL=15s
GRAFANA_PORT=3000
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin
JAEGER_AGENT_HOST=jaeger
JAEGER_AGENT_PORT=6831
JAEGER_SAMPLER_TYPE=const
JAEGER_SAMPLER_PARAM=1

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60s
RATE_LIMIT_BURST=20

# Feature Flags
FEATURE_NEW_DASHBOARD=true
FEATURE_ADVANCED_ANALYTICS=false
FEATURE_SSO=false

# Security
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://app.example.com
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization
CORS_MAX_AGE=3600

# Session Management
SESSION_TIMEOUT=1800s  # 30 minutes
SESSION_COOKIE_SECURE=false  # true in production
SESSION_COOKIE_SAME_SITE=lax
```

### Configuration Precedence

```
1. Command-line flags (highest priority)
2. Environment variables
3. Configuration files (.env, config.yaml)
4. System Config Service (runtime)
5. Default values (lowest priority)
```

**Example:**
```bash
# Default in code
timeout := 30 * time.Second

# Overridden by config file
timeout = config.Get("timeout")  # 60s

# Overridden by environment variable
timeout = os.Getenv("TIMEOUT")  # 120s

# Final: 120s
```

## Performance Optimization

### Database Query Optimization

**Before Optimization:**
```javascript
// Slow query - full collection scan
db.users.find({
  "email": "user@example.com"
})
// Execution time: 500ms (100k documents)
```

**After Optimization:**
```javascript
// Create index
db.users.createIndex({ "email": 1 }, { unique: true })

// Fast query - index scan
db.users.find({
  "email": "user@example.com"
})
// Execution time: 2ms (index lookup)
```

### Caching Strategy

**Multi-level Caching:**
```
Request → API Gateway Cache (1s TTL)
          ↓ (miss)
          Redis Cache (5min TTL)
          ↓ (miss)
          Database (persistent)
          ↓
          Cache result in Redis
          ↓
          Return to client

Response Time:
- API Gateway cache hit: <1ms
- Redis cache hit: 2-5ms
- Database query: 20-100ms
```

### Connection Pooling

**MongoDB Connection Pool:**
```go
// Pool configuration
clientOptions := options.Client().
    SetMaxPoolSize(100).
    SetMinPoolSize(10).
    SetMaxConnIdleTime(60 * time.Second)

// Connection reuse
// - New request: Grab connection from pool (fast)
// - After request: Return connection to pool
// - No repeated TCP handshake overhead
```

**Performance Improvement:**
```
Without pooling: 50-100ms per request (new connection)
With pooling: 5-10ms per request (reused connection)
Improvement: 5-10x faster
```

## Disaster Recovery

### Backup Strategy

**Automated Backups:**
```bash
# Daily full backup (2 AM)
0 2 * * * /scripts/database/backup.sh

# Hourly incremental (business hours)
0 9-18 * * * /scripts/database/backup-incremental.sh

# Backup verification
0 3 * * * /scripts/database/verify-backup.sh
```

**Backup Locations:**
```
Local: /backups/
  ├── daily/
  │   ├── mongodb-2024-01-15.tar.gz
  │   └── mongodb-2024-01-14.tar.gz
  ├── weekly/
  │   └── mongodb-week-03.tar.gz
  └── monthly/
      └── mongodb-2024-01.tar.gz

Remote: S3/Cloud Storage
  └── backups/
      ├── daily/ (7 days retention)
      ├── weekly/ (4 weeks retention)
      └── monthly/ (12 months retention)
```

### Recovery Procedures

**Scenario: Data Corruption**
```bash
# 1. Stop services
make stop

# 2. Verify backup integrity
tar -tzf backups/mongodb-latest.tar.gz

# 3. Restore from backup
make db-restore FILE=backups/mongodb-latest.tar.gz

# 4. Verify data integrity
docker exec mongodb mongosh --eval "db.users.count()"

# 5. Start services
make start

# 6. Monitor logs
make logs

# Recovery time: ~5-10 minutes
```

**Scenario: Service Failure**
```bash
# 1. Check health
make status

# 2. View logs
make logs-service SERVICE=failed-service

# 3. Restart service
make restart-service SERVICE=failed-service

# 4. If restart fails, rebuild
make rebuild SERVICE=failed-service

# 5. Verify recovery
curl http://localhost:8080/health

# Recovery time: ~30 seconds
```

---

## See Also

- [DEVELOPMENT.md](DEVELOPMENT.md) - Development practices
- [TOOLS.md](TOOLS.md) - Tool reference
- [SETUP.md](SETUP.md) - Installation guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines

---

**Last Updated:** 2024-12-25  
**Architecture Version:** 1.1
