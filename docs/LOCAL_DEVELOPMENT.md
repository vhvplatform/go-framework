# Local Development Guide

Complete guide for daily local development workflow with the SaaS Platform.

## Table of Contents

- [Overview](#overview)
- [Daily Workflow](#daily-workflow)
- [Development Modes](#development-modes)
- [Working with Services](#working-with-services)
- [Database Operations](#database-operations)
- [API Testing](#api-testing)
- [Hot Reload Development](#hot-reload-development)
- [Debugging](#debugging)
- [Git Workflow](#git-workflow)
- [IDE Setup](#ide-setup)
- [Tips and Tricks](#tips-and-tricks)

---

## Overview

This guide covers the typical workflows and operations you'll use during local development of the SaaS Platform microservices.

### Prerequisites

Ensure you have completed the initial setup:
- See [GETTING_STARTED.md](GETTING_STARTED.md) for first-time setup
- See [SETUP.md](SETUP.md) for detailed installation

### Workspace Structure

```
~/workspace/go-platform/
├── go-framework/                # This repository (development tools)
├── go-shared-go/               # Shared library
├── go-api-gateway/             # API Gateway service
├── go-auth-service/            # Authentication service
├── go-user-service/            # User management
├── go-tenant-service/          # Multi-tenancy
├── go-notification-service/    # Notifications
├── go-system-config-service/   # Configuration
└── go-infrastructure/          # Infrastructure code
```

---

## Daily Workflow

### Starting Your Day

```bash
# 1. Navigate to framework
cd ~/workspace/go-platform/go-framework

# 2. Pull latest changes
git pull

# 3. Start all services
make start

# 4. Check status
make status

# 5. View service URLs
make info

# Services are now running and ready for development
```

**Expected Output:**
```
✅ All services are healthy!

Service URLs:
- API Gateway: http://localhost:8080
- Auth Service: http://localhost:8081
- User Service: http://localhost:8082
...
```

---

### Making Changes to a Service

#### Example: Modifying Auth Service

```bash
# 1. Navigate to service repository
cd ~/workspace/go-platform/go-auth-service

# 2. Create feature branch
git checkout -b feature/add-oauth-support

# 3. Make your changes
vim internal/handlers/auth_handler.go

# 4. Rebuild and restart service
cd ~/workspace/go-platform/go-framework
make rebuild SERVICE=auth-service

# 5. Test your changes
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# 6. Check logs if needed
make logs-service SERVICE=auth-service

# 7. Run tests
cd ~/workspace/go-platform/go-auth-service
go test ./...

# 8. Commit your changes
git add .
git commit -m "feat(auth): add OAuth support"

# 9. Push and create PR
git push origin feature/add-oauth-support
```

---

### Ending Your Day

```bash
# Option 1: Stop everything (preserves data)
cd ~/workspace/go-platform/go-framework
make stop-keep-data

# Option 2: Stop and clean up (removes data)
make stop

# Option 3: Keep running in background
# (Services will auto-restart on system reboot if Docker Desktop is configured)
```

**Recommendation:** Use `make stop-keep-data` to preserve your test data for tomorrow.

---

## Development Modes

### Standard Mode (Default)

Services run as Docker containers with fixed code:

```bash
make start
```

**Use When:**
- Testing existing functionality
- Running integration tests
- Stable development

**Pros:**
- Fast startup
- Consistent environment
- Production-like

**Cons:**
- Requires rebuild to see code changes

---

### Development Mode (Hot Reload)

Services automatically reload when code changes:

```bash
make start-dev
```

**What it does:**
- Mounts source code as volumes
- Uses `air` for auto-reload
- Watches for file changes
- Rebuilds and restarts automatically

**Use When:**
- Active development
- Frequent code changes
- Rapid iteration

**Pros:**
- Instant feedback
- No manual rebuilds
- Fast iteration

**Cons:**
- Slower initial startup
- More resource intensive

**Example Workflow:**
```bash
# 1. Start in dev mode
make start-dev

# 2. Edit code
cd ~/workspace/go-platform/go-auth-service
vim internal/handlers/auth_handler.go

# 3. Save file
# Service automatically reloads in 2-3 seconds

# 4. Test immediately
curl http://localhost:8081/health
```

---

### Minimal Mode (Selective Services)

Start only services you need:

```bash
# Start just infrastructure
cd docker
docker-compose up -d mongodb redis rabbitmq

# Start specific services
docker-compose up -d api-gateway auth-service user-service
```

**Use When:**
- Limited system resources
- Working on specific services
- Faster startup needed

---

## Working with Services

### Quick Service Operations

```bash
# Restart a service
make restart-service SERVICE=auth-service

# Rebuild and restart
make rebuild SERVICE=auth-service

# View logs
make logs-service SERVICE=auth-service

# Follow logs in real-time
make tail-logs SERVICE=auth-service

# Access service shell
make shell SERVICE=auth-service

# Check service health
curl http://localhost:8081/health
```

---

### Service-Specific Commands

#### API Gateway

```bash
# View routing configuration
docker exec api-gateway cat /app/config/routes.yaml

# Test health
curl http://localhost:8080/health

# View metrics
curl http://localhost:8080/metrics
```

#### Auth Service

```bash
# Generate test JWT
make generate-jwt

# Test login
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'

# Verify token
TOKEN="your-jwt-token"
curl http://localhost:8081/auth/verify \
  -H "Authorization: Bearer $TOKEN"
```

#### User Service

```bash
# Create user
curl -X POST http://localhost:8082/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"email":"new@example.com","name":"New User"}'

# Get user
curl http://localhost:8082/users/123 \
  -H "Authorization: Bearer $TOKEN"
```

---

### Building Services

```bash
# Build all services
make build

# Build specific service
make build-service SERVICE=auth-service

# Build Docker images
make docker-build

# Build and push images
make docker-build
make docker-push
```

---

## Database Operations

### Loading Test Data

```bash
# Load predefined test data
make db-seed

# Generate custom test data
make test-data

# Generate specific amount
USERS=100 TENANTS=20 make test-data
```

---

### Inspecting Data

```bash
# Access MongoDB shell
docker exec -it mongodb mongosh

# In MongoDB shell:
show dbs
use saas_platform
show collections
db.users.find().pretty()
db.users.countDocuments()
```

---

### Data Management

```bash
# Backup database
make db-backup
# Creates: backups/mongodb-backup-YYYY-MM-DD-HHMMSS.tar.gz

# List backups
ls -lh backups/

# Restore from backup
make db-restore FILE=backups/mongodb-backup-2024-01-15-120000.tar.gz

# Reset database (WARNING: deletes all data)
make db-reset

# After reset, reload test data
make db-seed
```

---

### Database Migrations

```bash
# Run migrations
make db-migrate

# Check migration status
docker exec mongodb mongosh --eval "db.migrations.find().pretty()"
```

---

## API Testing

### Using cURL

```bash
# Health check
curl http://localhost:8080/health

# Login and get token
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  | jq -r '.token')

# Use token for authenticated requests
curl http://localhost:8080/api/users \
  -H "Authorization: Bearer $TOKEN"

# Create resource
curl -X POST http://localhost:8080/api/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"new@example.com","name":"New User"}'
```

---

### Using Postman

```bash
# Import collections
# 1. Open Postman
# 2. Import > File > Select postman/SaaS-Platform.postman_collection.json
# 3. Import environment > postman/Development.postman_environment.json

# Collections include:
# - Authentication (login, register, verify)
# - User Management (CRUD operations)
# - Tenant Management
# - Notifications
# - System Configuration
```

**Pro Tip:** Environment variables in Postman auto-populate from responses (e.g., login automatically sets `{{token}}`).

---

### Automated API Testing

```bash
# Quick API test
make test-api

# Run specific endpoint tests
cd ~/workspace/go-platform/go-auth-service
go test ./test/integration/...
```

---

## Hot Reload Development

### Setup for Go Services

Hot reload is pre-configured using `air`:

```bash
# 1. Start in dev mode
make start-dev

# 2. Edit any .go file
cd ~/workspace/go-platform/go-auth-service
vim internal/handlers/auth_handler.go

# 3. Save the file

# 4. Watch the logs - service auto-reloads
make logs-service SERVICE=auth-service

# You should see:
# "Building..."
# "Build finished"
# "Restarting..."
# "Server started on :8080"
```

---

### Hot Reload Configuration

Configuration file: `.air.toml` in each service repository

```toml
# Example configuration
[build]
  cmd = "go build -o ./tmp/main ."
  bin = "tmp/main"
  include_ext = ["go"]
  exclude_dir = ["tmp", "vendor"]
  delay = 1000

[log]
  time = true
```

**Customize as needed** for your development style.

---

## Debugging

### Viewing Logs

```bash
# All services
make logs

# Specific service
make logs-service SERVICE=auth-service

# Follow logs (tail -f)
make tail-logs

# Filter logs
make logs-service SERVICE=auth-service | grep ERROR

# Last 100 lines
docker-compose logs --tail=100 auth-service
```

---

### Interactive Debugging

```bash
# Access container shell
make shell SERVICE=auth-service

# Inside container:
# - Check environment
env | grep JWT

# - Check connectivity
ping mongodb
curl http://user-service:8080/health

# - Check files
ls -la /app
cat /app/config/app.yaml

# - Check processes
ps aux
netstat -tuln
```

---

### Using VS Code Debugger

See [DEBUGGING.md](DEBUGGING.md) for detailed VS Code debugging setup.

Quick start:

```bash
# 1. Open VS Code
code ~/workspace/go-platform

# 2. Open Debug panel (Cmd/Ctrl+Shift+D)

# 3. Select configuration (e.g., "Debug Auth Service")

# 4. Set breakpoints in code

# 5. Press F5 to start debugging

# 6. Make API calls - breakpoints will hit
```

---

### Performance Profiling

```bash
# CPU profiling
curl http://localhost:8081/debug/pprof/profile?seconds=30 > cpu.prof
go tool pprof -http=:8082 cpu.prof

# Memory profiling
curl http://localhost:8081/debug/pprof/heap > mem.prof
go tool pprof -http=:8082 mem.prof

# Goroutine profiling
curl http://localhost:8081/debug/pprof/goroutine > goroutine.prof
go tool pprof -http=:8082 goroutine.prof
```

---

## Git Workflow

### Feature Development

```bash
# 1. Create feature branch
cd ~/workspace/go-platform/go-auth-service
git checkout main
git pull origin main
git checkout -b feature/add-new-feature

# 2. Make changes and commit
git add .
git commit -m "feat(auth): add new feature"

# 3. Run tests
go test ./...

# 4. Push and create PR
git push origin feature/add-new-feature

# 5. Create PR on GitHub
```

---

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `refactor` - Code refactoring
- `test` - Tests
- `chore` - Maintenance

**Examples:**
```
feat(auth): add OAuth2 support

Implement OAuth2 authentication flow with Google and GitHub providers.
Includes token validation and user profile mapping.

Closes #123

---

fix(user): resolve duplicate email validation

Fixed race condition in email uniqueness check.

Fixes #456
```

---

### Git Hooks

Pre-commit hooks are configured automatically:

```bash
# Hooks run on commit:
# - Linting (golangci-lint)
# - Formatting (gofmt, goimports)
# - Tests (go test ./...)

# To skip hooks (not recommended):
git commit --no-verify
```

---

## IDE Setup

### VS Code

Configuration is included in `configs/vscode/`:

```bash
# Open workspace
code ~/workspace/go-platform

# VS Code will:
# - Load recommended extensions
# - Apply workspace settings
# - Load debug configurations
# - Configure tasks
```

**Recommended Extensions:**
- Go (golang.go)
- Docker (ms-azuretools.vscode-docker)
- GitLens (eamodio.gitlens)
- Rest Client (humao.rest-client)
- YAML (redhat.vscode-yaml)

---

### GoLand / IntelliJ IDEA

```bash
# Open project
# File > Open > ~/workspace/go-platform

# Configure Go SDK
# Preferences > Go > GOROOT

# Configure Docker
# Preferences > Build, Execution, Deployment > Docker

# Enable Go Modules
# Preferences > Go > Go Modules > Enable Go modules integration
```

---

## Tips and Tricks

### Quick Commands

```bash
# Restart specific service quickly
alias authrs="cd ~/workspace/go-platform/go-framework && make restart-service SERVICE=auth-service"
alias authlogs="cd ~/workspace/go-platform/go-framework && make logs-service SERVICE=auth-service"

# Add to ~/.bashrc or ~/.zshrc
```

---

### Working with Multiple Services

```bash
# Open multiple terminals with tmux or iTerm2

# Terminal 1: Logs
make tail-logs

# Terminal 2: Development
cd ~/workspace/go-platform/go-auth-service
# ... make changes ...

# Terminal 3: Testing
cd ~/workspace/go-platform/go-auth-service
go test -watch ./...

# Terminal 4: Database
docker exec -it mongodb mongosh
```

---

### Quickly Testing Changes

```bash
# Method 1: Rebuild specific service
make rebuild SERVICE=auth-service

# Method 2: Use dev mode for instant reload
make start-dev

# Method 3: Run service locally (outside Docker)
cd ~/workspace/go-platform/go-auth-service
go run cmd/server/main.go
# Configure to connect to Docker MongoDB/Redis
```

---

### Efficient Database Testing

```bash
# Create database snapshot
make db-backup

# Experiment with data
# ... make changes ...

# Restore to clean state
make db-restore FILE=backups/latest.tar.gz

# Or quick reset
make db-reset
make db-seed
```

---

### Network Request Inspection

```bash
# Monitor all HTTP requests
docker exec api-gateway tail -f /var/log/access.log

# Use Jaeger for distributed tracing
make open-jaeger
# View request flow across all services
```

---

### Resource Monitoring

```bash
# Watch resource usage
watch docker stats

# Check specific service
docker stats auth-service

# Open Grafana for detailed metrics
make open-grafana
```

---

### Shell Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# DevTools shortcuts
alias dt='cd ~/workspace/go-platform/go-framework'
alias dstart='dt && make start'
alias dstop='dt && make stop'
alias dstatus='dt && make status'
alias dlogs='dt && make logs'

# Service navigation
alias goauth='cd ~/workspace/go-platform/go-auth-service'
alias gouser='cd ~/workspace/go-platform/go-user-service'
alias goapi='cd ~/workspace/go-platform/go-api-gateway'

# Quick operations
alias drebuild='dt && make rebuild'
alias drestart='dt && make restart-service'
```

---

## Next Steps

- **Testing:** See [TESTING.md](TESTING.md) for testing strategies
- **Debugging:** See [DEBUGGING.md](DEBUGGING.md) for debugging techniques
- **Architecture:** See [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- **Troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues

---

**Last Updated:** 2024-01-15  
**Happy Coding! 🚀**
