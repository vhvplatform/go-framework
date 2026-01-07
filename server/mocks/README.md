# Mock Services

This directory contains minimal mock implementations of the SaaS Platform microservices. These mocks are used for testing and CI/CD environments where the full service repositories are not available.

## Purpose

The docker-compose.yml configuration in this repository expects service repositories to be cloned as sibling directories (e.g., `../../go-api-gateway`). In CI/CD pipelines and testing environments where these repositories don't exist, these mock services provide a fallback that allows the framework to be tested independently.

## Services

Each mock service provides:
- A simple HTTP server that responds to `/health` endpoints
- Minimal Go implementation with no external dependencies
- Docker support for containerized deployment

### Included Mock Services

1. **api-gateway** - Port 8080
2. **auth-service** - Port 8081, gRPC 50051
3. **user-service** - Port 8082, gRPC 50052
4. **tenant-service** - Port 8083, gRPC 50053
5. **notification-service** - Port 8084, gRPC 50054
6. **system-config-service** - Port 8085, gRPC 50055

## Usage

These mock services are automatically used by docker-compose.yml when the full service repositories are not available in their expected locations.

### Local Development

For local development with full services:
```bash
cd /path/to/workspace
make setup-repos  # Clone all service repositories
make start        # Uses full services from sibling directories
```

### CI/Testing

In CI or testing environments:
```bash
make start  # Automatically uses mock services when full services aren't available
```

## Health Check Response

Each mock service returns a simple health check response:

```json
{
  "status": "healthy",
  "service": "service-name"
}
```

## Implementation

Each mock service is a minimal Go application with:
- `main.go` - HTTP server with /health endpoint
- `go.mod` - Go module definition
- `Dockerfile` - Multi-stage Docker build

The services use standard library only and have no external dependencies, making them fast to build and deploy.

## Limitations

These are **mock services only** and do not implement any business logic. They are suitable for:
- ✅ Framework testing
- ✅ CI/CD pipelines
- ✅ Infrastructure validation
- ✅ Health check testing

They are **not suitable** for:
- ❌ Functional testing
- ❌ Integration testing
- ❌ Performance testing
- ❌ Production use

For full functionality, use the complete service repositories from the vhvplatform organization.
