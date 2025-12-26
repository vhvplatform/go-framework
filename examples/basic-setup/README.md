# Basic Setup Example

This example demonstrates a basic setup of the go-framework development environment.

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework

# 2. Run automated setup
make setup

# 3. Start all services
make start

# 4. Verify everything is working
make status
```

## What Gets Installed

- Docker Desktop
- Go 1.21+
- kubectl
- Helm
- Protocol Buffers compiler
- Go development tools
- All microservice repositories

## Directory Structure After Setup

```
~/workspace/go-platform/
├── go-framework/                # This repository
├── go-shared-go/               # Shared library
├── go-api-gateway/             # API Gateway
├── go-auth-service/            # Auth service
├── go-user-service/            # User service
├── go-tenant-service/          # Tenant service
├── go-notification-service/    # Notification service
├── go-system-config-service/   # Config service
└── go-infrastructure/          # Infrastructure code
```

## Environment Configuration

The `.env` file is created from `.env.example`:

```bash
# docker/.env
JWT_SECRET=dev-secret-change-in-production
JWT_EXPIRATION=24h

MONGODB_URI=mongodb://mongodb:27017
MONGODB_DATABASE=saas_platform

REDIS_URL=redis://redis:6379
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/

API_GATEWAY_PORT=8080
AUTH_SERVICE_PORT=8081
USER_SERVICE_PORT=8082
TENANT_SERVICE_PORT=8083
NOTIFICATION_SERVICE_PORT=8084
SYSTEM_CONFIG_SERVICE_PORT=8085
```

## Verification Steps

### 1. Check Docker

```bash
docker ps
```

Expected: All containers running

### 2. Check Service Health

```bash
make status
```

Expected output:
```
✅ API Gateway is healthy
✅ Auth Service is healthy
✅ User Service is healthy
...
```

### 3. Test API

```bash
curl http://localhost:8080/health
```

Expected: `{"status":"healthy"}`

### 4. Load Test Data

```bash
make db-seed
```

### 5. Open Monitoring

```bash
make open-grafana   # http://localhost:3000
make open-jaeger    # http://localhost:16686
```

## Common Issues

### Docker Not Running

```bash
# macOS: Start Docker Desktop
open -a Docker

# Linux: Start Docker service
sudo systemctl start docker
```

### Port Already in Use

```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>
```

### Services Not Starting

```bash
# Check logs
make logs

# Restart specific service
make restart-service SERVICE=auth-service
```

## Next Steps

1. **Test API Endpoints**
   ```bash
   make test-api
   ```

2. **Run Tests**
   ```bash
   make test
   ```

3. **Start Development**
   - See [LOCAL_DEVELOPMENT.md](../../docs/LOCAL_DEVELOPMENT.md)
   - See [DEVELOPMENT.md](../../docs/DEVELOPMENT.md)

4. **Learn More**
   - [TOOLS.md](../../docs/TOOLS.md) - Tool reference
   - [ARCHITECTURE.md](../../docs/ARCHITECTURE.md) - System design
   - [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md) - Common issues

## Support

- [GitHub Issues](https://github.com/vhvplatform/go-framework/issues)
- [Documentation](../../docs/)
- [Contributing Guide](../../CONTRIBUTING.md)
