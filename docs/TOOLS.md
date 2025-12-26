# Tools Reference

Complete documentation for all tools and scripts in the go-framework repository.

## Table of Contents

- [Setup Scripts](#setup-scripts)
- [Development Tools](#development-tools)
- [Database Management](#database-management)
- [Testing Tools](#testing-tools)
- [Build Scripts](#build-scripts)
- [Deployment Tools](#deployment-tools)
- [Monitoring Utilities](#monitoring-utilities)
- [General Utilities](#general-utilities)

---

## Setup Scripts

Scripts for initial setup and installation of the development environment.

### install-deps.sh

**Purpose:** Install system dependencies required for development.

**Location:** `scripts/setup/install-deps.sh`

**Usage:**
```bash
./scripts/setup/install-deps.sh
# or
make setup
```

**What it does:**
- Detects operating system (macOS, Linux, Windows/WSL2)
- Installs Docker Desktop
- Installs Go 1.21+
- Installs kubectl for Kubernetes
- Installs Helm for package management
- Installs jq for JSON processing
- Installs other development dependencies

**Supported Platforms:**
- macOS (Intel and Apple Silicon)
- Linux (Ubuntu, Debian, Fedora, RHEL)
- Windows (via WSL2)

**Troubleshooting:**
- If installation fails on macOS, ensure Homebrew is installed
- On Linux, ensure you have sudo privileges
- On Windows, run inside WSL2 terminal

---

### install-tools.sh

**Purpose:** Install Go development tools and utilities.

**Location:** `scripts/setup/install-tools.sh`

**Usage:**
```bash
./scripts/setup/install-tools.sh
# or
make setup-tools
```

**Installs:**
- `protoc-gen-go` - Protocol buffer Go code generator
- `protoc-gen-go-grpc` - gRPC Go code generator
- `golangci-lint` - Go linter
- `air` - Hot reload tool for Go apps
- `mockgen` - Mock generation for testing
- `goimports` - Import formatter
- `swag` - Swagger documentation generator
- `hey` - HTTP load testing tool

**Environment Variables:**
- `GOPATH` - Go workspace (auto-detected if not set)

**Troubleshooting:**
- Ensure `$GOPATH/bin` is in your `$PATH`
- Run `go env GOPATH` to verify GOPATH location
- May require internet access to download packages

---

### clone-repos.sh

**Purpose:** Clone all microservice repositories to workspace.

**Location:** `scripts/setup/clone-repos.sh`

**Usage:**
```bash
./scripts/setup/clone-repos.sh
# or
make setup-repos
```

**Environment Variables:**
- `WORKSPACE_DIR` - Target directory (default: `$HOME/workspace/go-platform`)

**Cloned Repositories:**
- `go-shared-go` - Shared library code
- `go-api-gateway` - API Gateway service
- `go-auth-service` - Authentication service
- `go-user-service` - User management service
- `go-tenant-service` - Multi-tenancy service
- `go-notification-service` - Notification service
- `go-system-config-service` - System configuration service
- `go-infrastructure` - Infrastructure as code

**Advanced Usage:**
```bash
# Clone to custom directory
WORKSPACE_DIR=/custom/path ./scripts/setup/clone-repos.sh

# Skip if already cloned
./scripts/setup/clone-repos.sh --skip-existing
```

**Troubleshooting:**
- Requires git to be installed
- Requires GitHub access (may need SSH keys configured)
- Check network connectivity if cloning fails

---

### init-workspace.sh

**Purpose:** Initialize workspace directory structure.

**Location:** `scripts/setup/init-workspace.sh`

**Usage:**
```bash
./scripts/setup/init-workspace.sh
# or
make setup (includes this step)
```

**What it creates:**
- Workspace directory structure
- Bin directory for compiled binaries
- Log directory for service logs
- Config directory for local configurations

**Environment Variables:**
- `WORKSPACE_DIR` - Target workspace (default: `$HOME/workspace/go-platform`)

---

## Development Tools

Tools for day-to-day development workflow.

### wait-for-services.sh

**Purpose:** Wait for all services to be healthy before proceeding.

**Location:** `scripts/dev/wait-for-services.sh`

**Usage:**
```bash
./scripts/dev/wait-for-services.sh
# Automatically called by 'make start'
```

**Configuration:**
- Timeout: 300 seconds (5 minutes)
- Health check interval: 5 seconds

**Checks:**
- Docker containers are running
- HTTP health endpoints respond
- Database connections are ready
- Message queue is accessible

**Troubleshooting:**
- If timeout occurs, check `make logs` for errors
- Increase timeout if needed on slower machines
- Check individual service health with `make status`

---

### restart-service.sh

**Purpose:** Restart a specific microservice quickly.

**Location:** `scripts/dev/restart-service.sh`

**Usage:**
```bash
./scripts/dev/restart-service.sh <service-name>
# or
make restart-service SERVICE=auth-service
```

**Examples:**
```bash
make restart-service SERVICE=auth-service
make restart-service SERVICE=user-service
make restart-service SERVICE=api-gateway
```

**What it does:**
1. Stops the specified service container
2. Starts it again with existing configuration
3. Waits for health check to pass

**Use Cases:**
- Quick restart after configuration change
- Recover from service crash
- Apply environment variable changes

---

### rebuild.sh

**Purpose:** Rebuild and restart a service with latest code changes.

**Location:** `scripts/dev/rebuild.sh`

**Usage:**
```bash
./scripts/dev/rebuild.sh <service-name>
# or
make rebuild SERVICE=auth-service
```

**What it does:**
1. Stops the service
2. Rebuilds Docker image with latest code
3. Restarts service with new image
4. Waits for health check

**Examples:**
```bash
# After making code changes
cd ../go-auth-service
# ... edit code ...
cd go-framework
make rebuild SERVICE=auth-service
```

---

### shell.sh

**Purpose:** Access a shell inside a running service container.

**Location:** `scripts/dev/shell.sh`

**Usage:**
```bash
./scripts/dev/shell.sh <service-name>
# or
make shell SERVICE=auth-service
```

**Examples:**
```bash
make shell SERVICE=auth-service
# Inside container:
# - Inspect logs
# - Check environment variables
# - Run manual commands
# - Debug issues
```

**Available Commands Inside Shell:**
- Standard Unix tools
- Service binaries
- Go tools
- Environment inspection

---

## Database Management

Tools for managing MongoDB and data.

### seed.sh

**Purpose:** Populate database with test data.

**Location:** `scripts/database/seed.sh`

**Usage:**
```bash
./scripts/database/seed.sh
# or
make db-seed
```

**Test Data Created:**
- 3 test users with different roles
- 2 test tenants
- 3 role definitions (admin, user, viewer)
- Sample notifications
- System configuration entries

**Credentials Created:**
- Admin user: `admin@example.com` / `admin123`
- Regular user: `user@example.com` / `user123`
- Viewer: `viewer@example.com` / `viewer123`

**Use Cases:**
- Initial development setup
- After database reset
- Testing with realistic data
- Demo preparation

---

### reset.sh

**Purpose:** Reset database (delete all data).

**Location:** `scripts/database/reset.sh`

**Usage:**
```bash
./scripts/database/reset.sh
# or
make db-reset
```

**Warning:** This is destructive and deletes all data!

**What it does:**
1. Drops all collections
2. Clears Redis cache
3. Purges RabbitMQ queues
4. Resets to clean state

**Safety:**
- Asks for confirmation (when using make target)
- Use with caution!
- Consider `make db-backup` first

---

### backup.sh

**Purpose:** Create a backup of the database.

**Location:** `scripts/database/backup.sh`

**Usage:**
```bash
./scripts/database/backup.sh
# or
make db-backup
```

**Backup Location:** `backups/mongodb-backup-YYYY-MM-DD-HHMMSS.tar.gz`

**What it backs up:**
- All MongoDB databases
- Compressed with gzip
- Timestamped filename

**Advanced Usage:**
```bash
# Custom backup location
BACKUP_DIR=/custom/path ./scripts/database/backup.sh

# Backup specific database
DB_NAME=mydb ./scripts/database/backup.sh
```

---

### restore.sh

**Purpose:** Restore database from a backup file.

**Location:** `scripts/database/restore.sh`

**Usage:**
```bash
./scripts/database/restore.sh <backup-file>
# or
make db-restore FILE=backups/mongodb-backup-2024-01-15-120000.tar.gz
```

**Examples:**
```bash
# List available backups
ls -la backups/

# Restore specific backup
make db-restore FILE=backups/mongodb-backup-2024-01-15-120000.tar.gz
```

**Warning:** Existing data will be replaced!

---

### migrate.sh

**Purpose:** Run database migrations.

**Location:** `scripts/database/migrate.sh`

**Usage:**
```bash
./scripts/database/migrate.sh
# or
make db-migrate
```

**Migration Types:**
- Schema updates
- Data transformations
- Index creation
- Version upgrades

---

## Testing Tools

Automated testing scripts for different test types.

### run-unit-tests.sh

**Purpose:** Run unit tests across all services.

**Location:** `scripts/testing/run-unit-tests.sh`

**Usage:**
```bash
./scripts/testing/run-unit-tests.sh
# or
make test-unit
```

**What it does:**
- Discovers all service directories
- Runs `go test` for each service
- Generates coverage reports
- Shows test summary

**Coverage Reports:** `coverage/unit-coverage.html`

**Options:**
```bash
# Verbose output
VERBOSE=1 ./scripts/testing/run-unit-tests.sh

# Specific package
PKG=./internal/auth ./scripts/testing/run-unit-tests.sh
```

---

### run-integration-tests.sh

**Purpose:** Run integration tests with live services.

**Location:** `scripts/testing/run-integration-tests.sh`

**Usage:**
```bash
./scripts/testing/run-integration-tests.sh
# or
make test-integration
```

**Prerequisites:**
- All services must be running
- Test database must be available
- Message queue must be accessible

**What it tests:**
- Database operations
- Service-to-service communication
- API endpoints
- gRPC calls
- Message queue integration

**Duration:** ~2-5 minutes

---

### run-e2e-tests.sh

**Purpose:** Run end-to-end tests simulating user workflows.

**Location:** `scripts/testing/run-e2e-tests.sh`

**Usage:**
```bash
./scripts/testing/run-e2e-tests.sh
# or
make test-e2e
```

**Test Scenarios:**
- User registration and login
- Complete CRUD operations
- Multi-tenant scenarios
- Notification workflows
- Error handling paths

**Duration:** ~5-10 minutes

**Configuration:**
- API endpoint: `http://localhost:8080`
- Can be customized with `API_URL` environment variable

---

### run-load-tests.sh

**Purpose:** Run performance and load tests.

**Location:** `scripts/testing/run-load-tests.sh`

**Usage:**
```bash
./scripts/testing/run-load-tests.sh
# or
make test-load
```

**Default Configuration:**
- Concurrent users: 10
- Duration: 30 seconds
- Request rate: 100 req/s

**Advanced Usage:**
```bash
# Custom load test
USERS=50 DURATION=60 RATE=200 ./scripts/testing/run-load-tests.sh
```

**Metrics Generated:**
- Request rate
- Response time (p50, p95, p99)
- Error rate
- Throughput

**Reports:** `reports/load-test-TIMESTAMP.html`

---

### generate-test-data.sh

**Purpose:** Generate realistic test data for development.

**Location:** `scripts/testing/generate-test-data.sh`

**Usage:**
```bash
./scripts/testing/generate-test-data.sh
# or
make test-data
```

**Generated Data:**
- Users (customizable count)
- Tenants with subscriptions
- Sample notifications
- Activity logs
- Configuration entries

**Options:**
```bash
# Generate specific amount
USERS=100 TENANTS=20 ./scripts/testing/generate-test-data.sh
```

---

## Build Scripts

Scripts for building services and Docker images.

### Build tools are handled via Makefile targets:

```bash
make build              # Build all services
make build-service      # Build specific service
make docker-build       # Build Docker images
make docker-push        # Push images to registry
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed build instructions.

---

## Deployment Tools

Tools for deploying to various environments.

### deploy-local.sh

**Purpose:** Deploy to local Kubernetes cluster.

**Location:** `scripts/deployment/deploy-local.sh`

**Usage:**
```bash
./scripts/deployment/deploy-local.sh
# or
make deploy-local
```

**Prerequisites:**
- Local Kubernetes cluster (minikube, kind, or Docker Desktop K8s)
- kubectl configured
- Helm installed

**What it deploys:**
- All microservices
- MongoDB
- Redis
- RabbitMQ
- Observability stack

**Duration:** ~3-5 minutes

---

### deploy-dev.sh

**Purpose:** Deploy to development environment.

**Location:** `scripts/deployment/deploy-dev.sh`

**Usage:**
```bash
./scripts/deployment/deploy-dev.sh
# or
make deploy-dev
```

**Prerequisites:**
- kubectl configured for dev cluster
- Appropriate credentials/permissions
- Images built and pushed to registry

**Environment Variables:**
- `KUBE_CONTEXT` - Kubernetes context to use
- `NAMESPACE` - Target namespace (default: `development`)

---

### port-forward.sh

**Purpose:** Setup port forwarding to Kubernetes services.

**Location:** `scripts/deployment/port-forward.sh`

**Usage:**
```bash
./scripts/deployment/port-forward.sh
# or
make port-forward
```

**Forwards Ports:**
- API Gateway: 8080
- Grafana: 3000
- Prometheus: 9090
- Jaeger: 16686

**Running in Background:**
```bash
./scripts/deployment/port-forward.sh &
# Stop with: pkill -f "kubectl port-forward"
```

---

### tunnel.sh

**Purpose:** Create secure tunnel to remote cluster.

**Location:** `scripts/deployment/tunnel.sh`

**Usage:**
```bash
./scripts/deployment/tunnel.sh
# or
make tunnel
```

**Use Cases:**
- Access remote services locally
- Debug production issues
- Temporary access for testing

---

## Monitoring Utilities

Tools for accessing monitoring and observability platforms.

### open-grafana.sh

**Purpose:** Open Grafana dashboard in browser.

**Location:** `scripts/monitoring/open-grafana.sh`

**Usage:**
```bash
./scripts/monitoring/open-grafana.sh
# or
make open-grafana
```

**Opens:** `http://localhost:3000`

**Default Credentials:**
- Username: `admin`
- Password: `admin` (change on first login)

**Available Dashboards:**
- Service metrics
- Request rates and latency
- Error rates
- Resource usage (CPU, memory)
- Database metrics

---

### open-prometheus.sh

**Purpose:** Open Prometheus UI in browser.

**Location:** `scripts/monitoring/open-prometheus.sh`

**Usage:**
```bash
./scripts/monitoring/open-prometheus.sh
# or
make open-prometheus
```

**Opens:** `http://localhost:9090`

**Use For:**
- Raw metrics queries
- Alert configuration
- Metrics exploration
- Debugging metric collection

---

### open-jaeger.sh

**Purpose:** Open Jaeger tracing UI in browser.

**Location:** `scripts/monitoring/open-jaeger.sh`

**Usage:**
```bash
./scripts/monitoring/open-jaeger.sh
# or
make open-jaeger
```

**Opens:** `http://localhost:16686`

**Features:**
- Distributed trace visualization
- Service dependency graphs
- Performance analysis
- Error tracking

---

### tail-logs.sh

**Purpose:** Tail logs from all services in real-time.

**Location:** `scripts/monitoring/tail-logs.sh`

**Usage:**
```bash
./scripts/monitoring/tail-logs.sh
# or
make tail-logs
```

**Features:**
- Color-coded by service
- Filters by log level
- Real-time streaming

**Advanced Usage:**
```bash
# Filter by service
SERVICE=auth-service ./scripts/monitoring/tail-logs.sh

# Filter by log level
LEVEL=ERROR ./scripts/monitoring/tail-logs.sh
```

---

## General Utilities

Miscellaneous utility scripts.

### check-health.sh

**Purpose:** Check health status of all services.

**Location:** `scripts/utilities/check-health.sh`

**Usage:**
```bash
./scripts/utilities/check-health.sh
# or
make status
```

**Checks:**
- Container status
- HTTP health endpoints
- Database connectivity
- Message queue status
- Redis connectivity

**Output:**
- ✅ Green: Service healthy
- ⚠️  Yellow: Service degraded
- ❌ Red: Service down

---

### cleanup.sh

**Purpose:** Clean up Docker resources.

**Location:** `scripts/utilities/cleanup.sh`

**Usage:**
```bash
./scripts/utilities/cleanup.sh
# or
make clean
```

**What it cleans:**
- Stopped containers
- Dangling images
- Unused volumes (optional)
- Build cache

**Safe Cleanup:**
- Does not remove running containers
- Preserves data volumes by default

**Deep Clean:**
```bash
# Remove everything including data
make clean-all
```

---

### validate-env.sh

**Purpose:** Validate environment configuration.

**Location:** `scripts/utilities/validate-env.sh`

**Usage:**
```bash
./scripts/utilities/validate-env.sh
# or
make validate-env
```

**Validates:**
- Required environment variables
- Port availability
- Tool dependencies
- Configuration files
- Connectivity

**Exit Codes:**
- 0: All validations passed
- 1: Validation failures detected

---

### generate-jwt.sh

**Purpose:** Generate JWT token for API testing.

**Location:** `scripts/utilities/generate-jwt.sh`

**Usage:**
```bash
./scripts/utilities/generate-jwt.sh
# or
make generate-jwt
```

**Default Values:**
- User ID: `test-user-123`
- Email: `test@example.com`
- Tenant ID: `test-tenant`
- Expiry: 1 hour

**Custom Token:**
```bash
USER_ID=myuser EMAIL=my@email.com ./scripts/utilities/generate-jwt.sh
```

**Environment Variables:**
- `USER_ID` - User identifier
- `EMAIL` - User email
- `TENANT_ID` - Tenant identifier
- `JWT_SECRET` - Signing secret (from .env)

**Output:**
- Prints JWT token to stdout
- Copy and use in Authorization header
- Format: `Bearer <token>`

---

### test-api.sh

**Purpose:** Quick API endpoint testing.

**Location:** `scripts/utilities/test-api.sh`

**Usage:**
```bash
./scripts/utilities/test-api.sh
# or
make test-api
```

**Tests:**
- Health endpoint
- Authentication endpoint
- User management endpoints
- Basic CRUD operations

**Prerequisites:**
- Services must be running
- Database must be seeded

**Output:**
- HTTP status codes
- Response times
- Success/failure indicators

---

## Troubleshooting

### Common Issues

#### Script Permission Denied
```bash
chmod +x scripts/**/*.sh
```

#### Docker Not Running
```bash
# Check Docker status
docker info

# Start Docker
# macOS: Start Docker Desktop
# Linux: sudo systemctl start docker
```

#### Port Conflicts
```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>
```

#### Service Won't Start
```bash
# Check logs
make logs-service SERVICE=<service-name>

# Check health
make status

# Restart service
make restart-service SERVICE=<service-name>
```

### Getting Help

For issues with specific tools:
1. Check script comments and usage
2. View [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. Check service logs: `make logs`
4. Open GitHub issue

---

## See Also

- [DEVELOPMENT.md](DEVELOPMENT.md) - Development workflow
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [TESTING.md](TESTING.md) - Testing guide
- [DEBUGGING.md](DEBUGGING.md) - Debugging techniques

---

**Last Updated:** 2024-01-15
