# SaaS Platform - Docker Development Stack

This directory contains Docker Compose configurations for local development of the SaaS Platform.

## Prerequisites

Before starting services, ensure you have:

1. **Cloned service repositories**: The Docker Compose configuration expects service repositories to be cloned in the workspace directory. Run `make setup-repos` from the go-framework directory to clone all required services.

2. **Workspace structure**: Your workspace should be organized as follows:
   ```
   ~/workspace/go-platform/          # Workspace directory
   ├── go-framework/                 # This repository
   │   └── docker/                   # Docker configs (you are here)
   ├── go-api-gateway/              # Cloned service repo
   ├── go-auth-service/             # Cloned service repo
   ├── go-user-service/             # Cloned service repo
   ├── go-tenant-service/           # Cloned service repo
   ├── go-notification-service/     # Cloned service repo
   └── go-system-config-service/    # Cloned service repo
   ```

## Quick Start

```bash
# From the workspace root, clone all service repositories (first time only)
cd ~/workspace/go-platform/go-framework
make setup-repos

# Copy environment template
cd docker
cp .env.example .env

# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## Configurations

### docker-compose.yml
Main configuration file with:
- Infrastructure services (MongoDB, Redis, RabbitMQ)
- All microservices (API Gateway, Auth, User, Tenant, Notification, System Config)
- Observability stack (Prometheus, Grafana, Jaeger)

### docker-compose.dev.yml
Development overrides with:
- Volume mounts for hot-reload
- Debug logging enabled
- Development-specific environment variables

**Usage:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### docker-compose.test.yml
Testing configuration with:
- Separate test database
- Reduced logging
- Mock SMTP server
- Observability stack disabled by default

**Usage:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d
```

## Services

### Infrastructure
- **MongoDB**: `localhost:27017` - NoSQL database
- **Redis**: `localhost:6379` - Caching and session storage
- **RabbitMQ**: `localhost:5672` (AMQP), `localhost:15672` (Management UI)

### Microservices
- **API Gateway**: `localhost:8080` - Main entry point
- **Auth Service**: `localhost:50051` (gRPC), `localhost:8081` (HTTP)
- **User Service**: `localhost:50052` (gRPC), `localhost:8082` (HTTP)
- **Tenant Service**: `localhost:50053` (gRPC), `localhost:8083` (HTTP)
- **Notification Service**: `localhost:50054` (gRPC), `localhost:8084` (HTTP)
- **System Config Service**: `localhost:50055` (gRPC), `localhost:8085` (HTTP)

### Observability
- **Prometheus**: `localhost:9090` - Metrics collection
- **Grafana**: `localhost:3000` - Metrics visualization (admin/admin)
- **Jaeger**: `localhost:16686` - Distributed tracing

## Environment Variables

Create a `.env` file from `.env.example` and configure:

```env
JWT_SECRET=your-secret-key
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
GRAFANA_PASSWORD=admin
```

## Useful Commands

```bash
# Start specific service
docker-compose up -d mongodb redis

# Rebuild a service
docker-compose build auth-service

# View logs of specific service
docker-compose logs -f api-gateway

# Execute command in service
docker-compose exec auth-service sh

# Clean up everything including volumes
docker-compose down -v

# Scale a service (if needed)
docker-compose up -d --scale user-service=3
```

## Prometheus Configuration

Prometheus configuration is located in `configs/prometheus/prometheus.yml`. It scrapes metrics from:
- All microservices
- MongoDB exporter
- Redis exporter
- RabbitMQ management plugin

## Grafana Dashboards

Grafana dashboards are provisioned automatically from `configs/grafana/dashboards/`.

Access Grafana at `http://localhost:3000` with credentials:
- Username: `admin`
- Password: value from `GRAFANA_PASSWORD` env var (default: `admin`)

## Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs

# Ensure no port conflicts
docker-compose ps
netstat -tulpn | grep -E '8080|27017|6379|5672'
```

### Clean restart
```bash
# Stop and remove everything
docker-compose down -v

# Remove orphaned containers
docker-compose down --remove-orphans

# Restart
docker-compose up -d
```

### Database issues
```bash
# Reset MongoDB
docker-compose exec mongodb mongosh
> use go_dev
> db.dropDatabase()
```

## Health Checks

All services have health checks configured. Check status with:
```bash
docker-compose ps
```

Healthy services will show `Up (healthy)`.

## Networking

All services communicate over the `go-network` bridge network. Service discovery uses Docker DNS:
- Services can reach each other by container name
- Example: `mongodb:27017`, `redis:6379`, `auth-service:50051`

## Volumes

Persistent data is stored in Docker volumes:
- `mongodb_data` - MongoDB database files
- `redis_data` - Redis persistence
- `rabbitmq_data` - RabbitMQ data
- `prometheus_data` - Prometheus metrics
- `grafana_data` - Grafana dashboards and settings

To backup/restore, use Docker volume commands or the scripts in `../scripts/database/`.
