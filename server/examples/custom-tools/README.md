# Custom Tools Example

This example demonstrates how to add custom tools and scripts to extend go-framework.

## Adding a Custom Script

### 1. Create Your Script

```bash
# scripts/utilities/my-custom-tool.sh
#!/bin/bash
#
# Script: my-custom-tool.sh
# Description: Custom tool for [your specific purpose]
# Usage: ./my-custom-tool.sh [OPTIONS]
#
# Options:
#   -h, --help     Show help message
#   -v, --verbose  Enable verbose output
#
# Environment Variables:
#   MY_VAR - Description (default: default_value)
#
# Examples:
#   ./my-custom-tool.sh
#   MY_VAR=custom ./my-custom-tool.sh --verbose

set -e

# Configuration
MY_VAR="${MY_VAR:-default_value}"
VERBOSE="${VERBOSE:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

# Validation
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 1
fi

# Main logic
main() {
    log_info "Running custom tool..."
    
    # Your custom logic here
    
    log_info "Done!"
}

main "$@"
```

### 2. Make It Executable

```bash
chmod +x scripts/utilities/my-custom-tool.sh
```

### 3. Add Makefile Target

Edit `Makefile`:

```makefile
## Custom Tools

my-custom-command: ## Description of what it does
	@./scripts/utilities/my-custom-tool.sh

my-custom-command-verbose: ## Run with verbose output
	@VERBOSE=true ./scripts/utilities/my-custom-tool.sh
```

### 4. Test Your Script

```bash
# Test directly
./scripts/utilities/my-custom-tool.sh

# Test via Makefile
make my-custom-command

# Test with options
MY_VAR=test make my-custom-command
```

### 5. Document Your Tool

Add to `docs/TOOLS.md`:

````markdown
### my-custom-tool.sh

**Purpose:** Brief description

**Location:** `scripts/utilities/my-custom-tool.sh`

**Usage:**
```bash
./scripts/utilities/my-custom-tool.sh
# or
make my-custom-command
```

**Options:**
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
make my-custom-command
MY_VAR=custom make my-custom-command
```
````

## Example: Database Snapshot Tool

```bash
# scripts/database/snapshot.sh
#!/bin/bash
set -e

SNAPSHOT_NAME="${SNAPSHOT_NAME:-$(date +%Y%m%d-%H%M%S)}"
SNAPSHOT_DIR="snapshots"

mkdir -p "$SNAPSHOT_DIR"

echo "📸 Creating database snapshot: $SNAPSHOT_NAME"

docker exec mongodb mongodump \
    --archive="$SNAPSHOT_DIR/$SNAPSHOT_NAME.archive" \
    --gzip

echo "✅ Snapshot created: $SNAPSHOT_DIR/$SNAPSHOT_NAME.archive"
```

Add to Makefile:

```makefile
db-snapshot: ## Create quick database snapshot
	@./scripts/database/snapshot.sh
```

## Example: Service Status Dashboard

```bash
# scripts/utilities/dashboard.sh
#!/bin/bash

echo "╔════════════════════════════════════════╗"
echo "║       Service Status Dashboard         ║"
echo "╚════════════════════════════════════════╝"
echo ""

services=("api-gateway" "auth-service" "user-service")

for service in "${services[@]}"; do
    if docker ps | grep -q "$service"; then
        status="✅ Running"
    else
        status="❌ Stopped"
    fi
    printf "%-20s %s\n" "$service" "$status"
done
```

## Example: Custom Deployment Script

```bash
# scripts/deployment/deploy-staging.sh
#!/bin/bash
set -e

NAMESPACE="staging"
CLUSTER="staging-cluster"

echo "🚀 Deploying to staging..."

# Configure kubectl
kubectl config use-context "$CLUSTER"

# Deploy services
kubectl apply -f k8s/staging/ -n "$NAMESPACE"

# Wait for rollout
kubectl rollout status deployment/api-gateway -n "$NAMESPACE"

echo "✅ Deployment complete!"
```

## Example: Log Analyzer

```bash
# scripts/monitoring/analyze-logs.sh
#!/bin/bash

SERVICE="${1:-auth-service}"
TIMEFRAME="${2:-1h}"

echo "📊 Analyzing logs for $SERVICE (last $TIMEFRAME)..."

docker logs "$SERVICE" --since="$TIMEFRAME" | \
    grep -E "ERROR|WARN" | \
    sort | uniq -c | sort -rn

echo ""
echo "Top errors:"
docker logs "$SERVICE" --since="$TIMEFRAME" | \
    grep "ERROR" | \
    awk '{print $NF}' | \
    sort | uniq -c | sort -rn | head -5
```

## Example: Performance Benchmark

```bash
# scripts/testing/benchmark.sh
#!/bin/bash

ENDPOINT="${1:-http://localhost:8080/api/health}"
REQUESTS="${2:-1000}"
CONCURRENCY="${3:-10}"

echo "⚡ Running benchmark..."
echo "Endpoint: $ENDPOINT"
echo "Requests: $REQUESTS"
echo "Concurrency: $CONCURRENCY"
echo ""

hey -n "$REQUESTS" -c "$CONCURRENCY" "$ENDPOINT"
```

## Best Practices for Custom Tools

### 1. Follow Naming Conventions

- Use lowercase with hyphens: `my-custom-tool.sh`
- Use descriptive names: `analyze-performance.sh`
- Group by function: `scripts/utilities/`, `scripts/monitoring/`

### 2. Include Standard Headers

```bash
#!/bin/bash
#
# Script: tool-name.sh
# Description: What it does
# Usage: ./tool-name.sh [args]
#
# Requirements, examples, etc.
```

### 3. Use Consistent Error Handling

```bash
set -e  # Exit on error

if [ condition ]; then
    echo "Error: ..." >&2
    exit 1
fi
```

### 4. Provide Help Text

```bash
show_help() {
    grep '^#' "$0" | tail -n +2 | cut -c 3-
}

case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
esac
```

### 5. Make It Configurable

```bash
# Allow environment variable overrides
TIMEOUT="${TIMEOUT:-30}"
RETRIES="${RETRIES:-3}"
```

### 6. Add Color Output

```bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Success${NC}"
echo -e "${RED}Error${NC}"
```

### 7. Validate Prerequisites

```bash
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found"
    exit 1
fi
```

### 8. Test Thoroughly

```bash
# Test with different inputs
./my-tool.sh
./my-tool.sh arg1
MY_VAR=test ./my-tool.sh

# Test error cases
./my-tool.sh invalid-input
```

## Integration with Existing Tools

### Calling Other Scripts

```bash
# From your custom script
./scripts/database/backup.sh
./scripts/utilities/check-health.sh
```

### Using Makefile Targets

```bash
# From your custom script
make db-backup
make status
```

### Chaining Operations

```bash
make db-backup && \
    make db-reset && \
    make db-seed && \
    ./scripts/custom/my-import.sh
```

## See Also

- [DEVELOPMENT.md](../../docs/DEVELOPMENT.md) - Development guide
- [TOOLS.md](../../docs/TOOLS.md) - Tool reference
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
