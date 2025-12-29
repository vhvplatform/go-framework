# Dockerfile Templates

This directory contains Dockerfile templates for microservices in the go-platform ecosystem.

## Overview

There are two types of Dockerfile templates provided:

1. **Dockerfile.service-with-shared** - For services that depend on the `go-shared` library
2. **Dockerfile.service-standalone** - For standalone services without shared dependencies

## Which Template to Use?

### Use `Dockerfile.service-with-shared` when:
- Your service imports packages from `go-shared` (e.g., `github.com/vhvplatform/go-shared/...`)
- Your service needs shared utilities, models, or middleware
- Examples: auth-service, user-service, tenant-service

### Use `Dockerfile.service-standalone` when:
- Your service doesn't depend on `go-shared`
- Your service is completely self-contained
- Examples: simple API gateways, independent workers

## Usage Instructions

### For Services with go-shared Dependency

1. **Copy the Dockerfile to your service repository:**
   ```bash
   cp docker/templates/Dockerfile.service-with-shared ../go-auth-service/Dockerfile
   ```

2. **Copy the .dockerignore file:**
   ```bash
   cp docker/templates/.dockerignore ../go-auth-service/.dockerignore
   ```

3. **Customize the Dockerfile** (if needed):
   - Update service name in COPY commands (replace `go-auth-service` with your service name)
   - Adjust exposed ports if different from default (50051 for gRPC, 8081 for HTTP)
   - Modify health check endpoint if your service uses a different path

4. **Update docker-compose.yml:**
   The docker-compose.yml in this repository is already configured to use workspace-level build context:
   ```yaml
   auth-service:
     build:
       context: ../..              # Workspace root
       dockerfile: go-auth-service/Dockerfile
   ```

### For Standalone Services

1. **Copy the Dockerfile to your service repository:**
   ```bash
   cp docker/templates/Dockerfile.service-standalone ../go-my-service/Dockerfile
   ```

2. **Copy the .dockerignore file:**
   ```bash
   cp docker/templates/.dockerignore ../go-my-service/.dockerignore
   ```

3. **Customize the Dockerfile** (if needed):
   - Adjust exposed ports
   - Modify health check endpoint

4. **Use service-level build context in docker-compose.yml:**
   ```yaml
   my-service:
     build:
       context: ../../go-my-service  # Service root
       dockerfile: Dockerfile
   ```

## Build Context Explained

### Workspace-Level Build Context (for services with go-shared)

When using `Dockerfile.service-with-shared`, the build context is the workspace root:

```
~/workspace/go-platform/          # Build context root
├── go-framework/
├── go-shared/                    # Accessible as: COPY go-shared/ ./go-shared/
├── go-auth-service/              # Accessible as: COPY go-auth-service/ ./go-auth-service/
└── ...
```

Docker build command:
```bash
cd ~/workspace/go-platform
docker build -f go-auth-service/Dockerfile -t auth-service .
```

Docker Compose configuration:
```yaml
build:
  context: ../..                  # From docker/ directory, this is workspace root
  dockerfile: go-auth-service/Dockerfile
```

### Service-Level Build Context (for standalone services)

When using `Dockerfile.service-standalone`, the build context is the service directory:

```
~/workspace/go-platform/go-my-service/  # Build context root
├── cmd/
├── internal/
├── go.mod
├── go.sum
└── Dockerfile
```

Docker build command:
```bash
cd ~/workspace/go-platform/go-my-service
docker build -t my-service .
```

Docker Compose configuration:
```yaml
build:
  context: ../../go-my-service    # Service directory
  dockerfile: Dockerfile
```

## Customization Guide

### Changing Service Name

In `Dockerfile.service-with-shared`, replace all instances of `go-auth-service` with your service name:

```dockerfile
# Before
COPY go-auth-service/go.mod go-auth-service/go.sum ./go-auth-service/

# After (for user-service)
COPY go-user-service/go.mod go-user-service/go.sum ./go-user-service/
```

### Changing Ports

Update the EXPOSE and HEALTHCHECK instructions:

```dockerfile
# For a service on ports 50055 (gRPC) and 8085 (HTTP)
EXPOSE 50055 8085

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8085/health || exit 1
```

### Adding Build Arguments

You can add build arguments for configuration:

```dockerfile
# In Dockerfile
ARG SERVICE_VERSION=dev
ARG BUILD_TIME
RUN echo "Building version ${SERVICE_VERSION} at ${BUILD_TIME}"

# In docker-compose.yml
build:
  context: ../..
  dockerfile: go-auth-service/Dockerfile
  args:
    SERVICE_VERSION: "1.0.0"
    BUILD_TIME: "2024-01-15"
```

### Multi-stage Build Optimization

The provided templates use multi-stage builds to minimize image size:
- **builder stage**: Contains Go compiler and dependencies (~1GB)
- **final stage**: Contains only the compiled binary and runtime dependencies (~20MB)

## Troubleshooting

### Error: "COPY failed: file not found: go-shared/go.mod"

**Cause:** Build context is incorrect. The build context needs to be the workspace root, not the service directory.

**Solution:** Check your docker-compose.yml or build command uses workspace-level context:
```yaml
build:
  context: ../..                  # Should point to workspace root
  dockerfile: go-auth-service/Dockerfile
```

### Error: "COPY failed: file not found: go.mod"

**Cause:** Build context is pointing to workspace root, but Dockerfile expects service-level context.

**Solution:** Use the correct Dockerfile template:
- If service depends on go-shared: Use `Dockerfile.service-with-shared` with workspace context
- If service is standalone: Use `Dockerfile.service-standalone` with service context

### Build is Very Slow

**Cause:** Docker is copying unnecessary files due to missing .dockerignore.

**Solution:** 
1. Copy `.dockerignore` template to your service root
2. Verify it excludes large directories like `vendor/`, `node_modules/`, `.git/`

### Health Check Fails

**Cause:** Health check URL is incorrect or service doesn't expose HTTP endpoint.

**Solution:**
1. Verify your service has a `/health` endpoint on the HTTP port
2. Update HEALTHCHECK command to use correct port and path
3. Or remove HEALTHCHECK if not needed

## Best Practices

1. **Always use .dockerignore:** Speeds up builds and reduces context size
2. **Use multi-stage builds:** Keeps final images small
3. **Pin base image versions:** Use `golang:1.21-alpine` not `golang:latest`
4. **Add health checks:** Enables Docker and Kubernetes to monitor service health
5. **Run as non-root:** Add a dedicated user in the final stage for security
6. **Use BuildKit:** Enable with `DOCKER_BUILDKIT=1` for faster builds

## Example: Setting Up auth-service

```bash
# 1. Navigate to workspace
cd ~/workspace/go-platform

# 2. Copy Dockerfile template (auth-service depends on go-shared)
cp go-framework/docker/templates/Dockerfile.service-with-shared go-auth-service/Dockerfile

# 3. Copy .dockerignore
cp go-framework/docker/templates/.dockerignore go-auth-service/.dockerignore

# 4. Customize Dockerfile (service name is already correct for auth-service)
# No changes needed if using default ports (50051, 8081)

# 5. Build using docker-compose (from go-framework/docker directory)
cd go-framework/docker
docker-compose build auth-service

# 6. Or build directly
cd ~/workspace/go-platform
docker build -f go-auth-service/Dockerfile -t auth-service .
```

## Updating Existing Services

If you have services with old Dockerfiles that are failing to build:

1. **Backup existing Dockerfile:**
   ```bash
   cd ~/workspace/go-platform/go-auth-service
   mv Dockerfile Dockerfile.old
   ```

2. **Copy new template:**
   ```bash
   cp ../go-framework/docker/templates/Dockerfile.service-with-shared Dockerfile
   ```

3. **Port any custom configurations from old Dockerfile**

4. **Test build:**
   ```bash
   cd ../go-framework/docker
   docker-compose build auth-service
   ```

5. **Remove backup if successful:**
   ```bash
   rm go-auth-service/Dockerfile.old
   ```

## Related Documentation

- [Docker Setup Guide](../README.md)
- [Development Workflow](../../docs/LOCAL_DEVELOPMENT.md)
- [Service Creation Guide](../../docs/NEW_SERVICE_GUIDE.md)

## Support

For issues or questions:
- Open an issue: https://github.com/vhvplatform/go-framework/issues
- Check troubleshooting: [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md)
