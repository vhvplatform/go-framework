# Server - Backend Microservices

This directory contains all Golang backend code and infrastructure for the SaaS Platform.

## Directory Structure

```
server/
├── tools/          # Development and management CLI tools
├── mocks/          # Mock services for local development
├── scripts/        # Automation scripts (setup, deployment, testing, etc.)
├── configs/        # Configuration files (linting, git, vscode)
├── docker/         # Docker and docker-compose configurations
├── k8s/            # Kubernetes deployment manifests
├── examples/       # Example implementations and integrations
├── fixtures/       # Test fixtures and sample data
├── postman/        # Postman API collections
├── Makefile        # Build and automation commands
└── .golangci.yml   # Go linting configuration
```

## Quick Start

```bash
# From the server directory
make setup          # Setup development environment
make start          # Start all services
make status         # View service status
make test           # Run tests
```

## Documentation

- See `/docs/guides/` for development guides
- See `/docs/deployment/` for deployment instructions
- See `/docs/architecture/` for system architecture

## Requirements

- Go 1.25+
- Docker Desktop 4.0+
- Make

For more details, see the main [README.md](../README.md) at the repository root.
