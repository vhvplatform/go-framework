# SaaS Platform Developer CLI

A command-line interface tool for managing the SaaS Platform development environment.

## Installation

### From Source

```bash
cd tools/cli
go build -o saas
sudo mv saas /usr/local/bin/
```

### Quick Install

```bash
# From devtools directory
make build-cli
```

## Usage

### Setup Environment

```bash
# Complete setup
saas setup
```

### Manage Services

```bash
# Start all services
saas start

# Start with hot-reload
saas start --dev

# Start specific service
saas start auth

# Stop all services
saas stop

# Stop specific service
saas stop auth
```

### View Logs

```bash
# All logs
saas logs

# Specific service
saas logs auth

# Follow logs
saas logs -f auth
```

### Check Status

```bash
saas status
```

### Run Tests

```bash
# All tests
saas test

# Specific test type
saas test --type=unit
saas test --type=integration
saas test --type=e2e
saas test --type=load
```

### Deploy

```bash
# Deploy to local Kubernetes
saas deploy local

# Deploy to development
saas deploy dev
```

### Help

```bash
# General help
saas --help

# Command-specific help
saas start --help
saas test --help
```

## Commands

- `setup` - Setup development environment
- `start` - Start services
- `stop` - Stop services
- `logs` - View service logs
- `status` - Check service health
- `test` - Run tests
- `deploy` - Deploy to environment
- `version` - Show version

## Examples

### Complete Workflow

```bash
# Setup (one-time)
saas setup

# Start services
saas start

# Check status
saas status

# View logs
saas logs auth

# Run tests
saas test --type=unit

# Stop services
saas stop
```

### Development Workflow

```bash
# Start with hot-reload
saas start --dev

# Make code changes...
# Watch logs
saas logs -f auth

# Test changes
saas test --type=integration

# Deploy to local K8s
saas deploy local
```

## Requirements

- Go 1.21+
- Docker
- Make
- kubectl (for deployment)

## Development

```bash
# Build
go build -o saas

# Test
go run main.go status

# Install locally
go install
```

## Future Enhancements

- [ ] Interactive mode
- [ ] Service dependency management
- [ ] Configuration wizard
- [ ] Performance profiling
- [ ] Database migrations
- [ ] Backup/restore commands
- [ ] Log filtering and search
- [ ] Multi-environment support
- [ ] Health check dashboard
- [ ] Auto-update feature

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](../../LICENSE)
