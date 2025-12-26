# Development Guide

Guide for developing and extending the go-framework repository and the SaaS platform services.

## Table of Contents

- [Development Environment](#development-environment)
- [Adding New Tools](#adding-new-tools)
- [Shell Script Standards](#shell-script-standards)
- [Makefile Conventions](#makefile-conventions)
- [Testing Strategy](#testing-strategy)
- [CI/CD Integration](#cicd-integration)
- [Local Development Workflow](#local-development-workflow)
- [Best Practices](#best-practices)

---

## Development Environment

### Prerequisites

Before developing on go-framework:

```bash
# Clone the repository
git clone https://github.com/vhvcorp/go-framework.git
cd go-framework

# Setup your environment
make setup
```

### Development Tools

Recommended tools for developing go-framework:

- **Text Editor/IDE:** VS Code, Vim, or your preferred editor
- **Shell:** Bash 4.0+ (pre-installed on most systems)
- **ShellCheck:** Linting tool for shell scripts
- **Docker Desktop:** For testing changes
- **Git:** Version control

Install ShellCheck for script validation:

```bash
# macOS
brew install shellcheck

# Linux (Ubuntu/Debian)
sudo apt-get install shellcheck

# Linux (Fedora)
sudo dnf install shellcheck
```

---

## Adding New Tools

### Step-by-Step Guide

#### 1. Identify the Category

Determine which category your tool belongs to:
- **setup/** - One-time installation/configuration
- **dev/** - Daily development operations
- **database/** - Database management
- **testing/** - Test automation
- **build/** - Build operations
- **deployment/** - Deployment automation
- **monitoring/** - Monitoring and observability
- **utilities/** - General-purpose utilities

#### 2. Create the Script

```bash
# Create script in appropriate directory
touch scripts/utilities/my-new-tool.sh

# Make it executable
chmod +x scripts/utilities/my-new-tool.sh
```

#### 3. Use the Standard Template

```bash
#!/bin/bash
# Description: Brief description of what this tool does
# Usage: ./my-new-tool.sh [OPTIONS]
# 
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
#
# Environment Variables:
#   MY_VAR - Description of variable (default: default_value)
#
# Examples:
#   ./my-new-tool.sh
#   MY_VAR=custom ./my-new-tool.sh
#   ./my-new-tool.sh --verbose

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration with defaults
MY_VAR="${MY_VAR:-default_value}"
VERBOSE="${VERBOSE:-false}"

# Functions
show_help() {
    grep '^#' "$0" | tail -n +2 | cut -c 3-
    exit 0
}

log_info() {
    echo -e "${GREEN}ℹ${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# Validation
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 1
fi

# Main logic
main() {
    log_info "Starting my new tool..."
    
    # Do work here
    
    log_info "✅ Done!"
}

# Execute main function
main "$@"
```

#### 4. Add Makefile Target

Edit `Makefile` and add your new command:

```makefile
## Utility Commands  # Section header

my-command: ## Brief description of what it does
	@./scripts/utilities/my-new-tool.sh

my-command-verbose: ## Run my command with verbose output
	@VERBOSE=true ./scripts/utilities/my-new-tool.sh
```

**Important:** 
- Use `##` for help text that appears in `make help`
- Use `@` prefix to suppress command echo
- Group related commands together

#### 5. Document the Tool

Add documentation to `docs/TOOLS.md`:

```markdown
### my-new-tool.sh

**Purpose:** Brief description

**Location:** `scripts/utilities/my-new-tool.sh`

**Usage:**
\`\`\`bash
./scripts/utilities/my-new-tool.sh
# or
make my-command
\`\`\`

**Options:**
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help message

**Environment Variables:**
- `MY_VAR` - Description (default: `default_value`)

**Examples:**
\`\`\`bash
# Basic usage
make my-command

# With custom variable
MY_VAR=custom make my-command

# Verbose mode
make my-command-verbose
\`\`\`

**Troubleshooting:**
- Common issue and solution
```

#### 6. Test Your Tool

```bash
# Test the script directly
./scripts/utilities/my-new-tool.sh

# Test via Makefile
make my-command

# Test with different options
./scripts/utilities/my-new-tool.sh --help
./scripts/utilities/my-new-tool.sh --verbose

# Test with environment variables
MY_VAR=test ./scripts/utilities/my-new-tool.sh
```

#### 7. Lint and Validate

```bash
# Lint the script
shellcheck scripts/utilities/my-new-tool.sh

# Check for common issues
bash -n scripts/utilities/my-new-tool.sh

# Test on different platforms if possible
```

#### 8. Submit Pull Request

```bash
# Create feature branch
git checkout -b feature/add-my-new-tool

# Commit changes
git add scripts/utilities/my-new-tool.sh
git add Makefile
git add docs/TOOLS.md
git commit -m "feat(utilities): add my-new-tool for XYZ

- Add script for doing XYZ
- Add Makefile target 'my-command'
- Add documentation to TOOLS.md

Closes #123"

# Push and create PR
git push origin feature/add-my-new-tool
```

---

## Shell Script Standards

### Coding Style

#### Shebang and Options

```bash
#!/bin/bash
set -e          # Exit on error
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipe failure
```

#### Variable Naming

```bash
# Constants: UPPER_SNAKE_CASE
readonly MAX_RETRIES=3
readonly DEFAULT_TIMEOUT=30

# Environment variables: UPPER_SNAKE_CASE
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace}"

# Local variables: lower_snake_case
local service_name="auth-service"
local retry_count=0
```

#### Function Naming

```bash
# Use lowercase with underscores
check_prerequisites() {
    # ...
}

validate_environment() {
    # ...
}

# Prefix with underscore for private functions
_internal_helper() {
    # ...
}
```

#### Quoting

```bash
# Always quote variables
echo "$variable"
echo "${WORKSPACE_DIR}/path"

# Quote command substitutions
current_dir="$(pwd)"
file_count=$(find . -type f | wc -l)

# Use arrays for multiple items
services=("auth" "user" "tenant")
for service in "${services[@]}"; do
    echo "$service"
done
```

#### Error Handling

```bash
# Check command success
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found"
    exit 1
fi

# Check file existence
if [[ ! -f "$config_file" ]]; then
    echo "Error: Config file not found: $config_file"
    exit 1
fi

# Check directory
if [[ ! -d "$workspace_dir" ]]; then
    mkdir -p "$workspace_dir"
fi

# Trap errors
cleanup() {
    echo "Cleaning up..."
    # Cleanup code
}
trap cleanup EXIT ERR
```

#### Output Messages

```bash
# Use colors for different message types
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Info messages
echo -e "${GREEN}✓${NC} Operation successful"

# Warning messages
echo -e "${YELLOW}⚠${NC} Warning: Something to note"

# Error messages
echo -e "${RED}✗${NC} Error: Something failed" >&2

# Use emojis for visibility (optional, but consistent)
echo "🚀 Starting deployment..."
echo "✅ Deployment complete!"
echo "⚠️  Warning: Resource limit reached"
echo "❌ Error: Connection failed"
```

### Script Structure

Standard script structure:

```bash
#!/bin/bash
set -euo pipefail

# 1. Header comment (description, usage, examples)
# Description: ...
# Usage: ...
# Examples: ...

# 2. Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 3. Default configuration
DEFAULT_TIMEOUT=30
VERBOSE="${VERBOSE:-false}"

# 4. Color codes
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# 5. Helper functions
log_info() { echo -e "${GREEN}$*${NC}"; }
log_error() { echo -e "${RED}$*${NC}" >&2; }

# 6. Validation functions
check_prerequisites() {
    # ...
}

# 7. Main business logic functions
do_something() {
    # ...
}

# 8. Main function
main() {
    check_prerequisites
    do_something
    log_info "✅ Complete"
}

# 9. Script execution
main "$@"
```

### Common Patterns

#### Retry Logic

```bash
retry_command() {
    local max_attempts=3
    local timeout=5
    local attempt=1
    
    while (( attempt <= max_attempts )); do
        if command_to_retry; then
            return 0
        fi
        
        echo "Attempt $attempt failed. Retrying in ${timeout}s..."
        sleep "$timeout"
        ((attempt++))
    done
    
    echo "Command failed after $max_attempts attempts"
    return 1
}
```

#### Progress Indicator

```bash
show_progress() {
    local duration=$1
    local interval=1
    local elapsed=0
    
    while (( elapsed < duration )); do
        echo -n "."
        sleep "$interval"
        ((elapsed += interval))
    done
    echo ""
}
```

#### Confirmation Prompt

```bash
confirm() {
    local prompt="$1"
    local response
    
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Usage
if confirm "Are you sure?"; then
    echo "Proceeding..."
else
    echo "Cancelled"
    exit 0
fi
```

---

## Makefile Conventions

### Structure

```makefile
.PHONY: help target1 target2

# Colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RED    := $(shell tput -Txterm setaf 1)
RESET  := $(shell tput -Txterm sgr0)

# Variables
WORKSPACE_DIR ?= $(HOME)/workspace/go-platform

# Default target
.DEFAULT_GOAL := help

help: ## Show this help
	@echo 'Available commands:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?##/ { \
		printf "  ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2 \
	}' $(MAKEFILE_LIST)

## Section Header

target1: ## Description of target1
	@echo "${GREEN}Running target1${RESET}"
	@./scripts/category/script1.sh

target2: dependency1 dependency2 ## Target with dependencies
	@./scripts/category/script2.sh
```

### Best Practices

1. **Use `.PHONY`** - Mark targets that don't create files
2. **Add Help Text** - Use `## Comment` for help
3. **Group Related Targets** - Use section headers
4. **Use `@` for Clean Output** - Suppress command echo
5. **Validate Variables** - Check required variables exist
6. **Provide Defaults** - Use `?=` for overridable variables

Example with validation:

```makefile
restart-service: ## Restart specific service (SERVICE=name)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${RED}Error: SERVICE variable required${RESET}"; \
		echo "Usage: make restart-service SERVICE=auth-service"; \
		exit 1; \
	fi
	@./scripts/dev/restart-service.sh $(SERVICE)
```

---

## Testing Strategy

### Script Testing

#### 1. Syntax Checking

```bash
# Check syntax without executing
bash -n scripts/utilities/my-script.sh

# Lint with ShellCheck
shellcheck scripts/utilities/my-script.sh
```

#### 2. Unit Testing (bats-core)

Install bats-core:

```bash
# macOS
brew install bats-core

# Linux
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

Create test file `tests/my-script.bats`:

```bash
#!/usr/bin/env bats

setup() {
    # Setup before each test
    export TEST_DIR="$(mktemp -d)"
}

teardown() {
    # Cleanup after each test
    rm -rf "$TEST_DIR"
}

@test "script exists and is executable" {
    [ -x "scripts/utilities/my-script.sh" ]
}

@test "script shows help with --help" {
    run scripts/utilities/my-script.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "script fails with invalid option" {
    run scripts/utilities/my-script.sh --invalid
    [ "$status" -ne 0 ]
}
```

Run tests:

```bash
bats tests/my-script.bats
```

#### 3. Integration Testing

Test complete workflows:

```bash
# tests/integration/setup-workflow.sh
#!/bin/bash
set -e

echo "Testing setup workflow..."

# Test setup
make setup-tools
make setup-repos

# Verify
if [[ ! -d "$HOME/workspace/go-platform" ]]; then
    echo "Error: Workspace not created"
    exit 1
fi

echo "✓ Setup workflow passed"
```

#### 4. Manual Testing

Create a testing checklist:

```markdown
- [ ] Script runs without errors
- [ ] Help text is clear and accurate
- [ ] Error messages are helpful
- [ ] Works with default values
- [ ] Works with custom environment variables
- [ ] Handles edge cases (missing files, invalid input)
- [ ] Idempotent (safe to run multiple times)
- [ ] Works on macOS
- [ ] Works on Linux
- [ ] Works in CI environment
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Test DevTools

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      
      - name: Lint shell scripts
        run: |
          find scripts -name "*.sh" -exec shellcheck {} \;
  
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup environment
        run: |
          make setup-tools
      
      - name: Run tests
        run: |
          make test
```

### Pre-commit Hooks

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Lint shell scripts
echo "Linting shell scripts..."
for script in $(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$'); do
    if [[ -f "$script" ]]; then
        shellcheck "$script"
    fi
done

# Check Makefile syntax
if git diff --cached --name-only | grep -q '^Makefile$'; then
    echo "Checking Makefile..."
    make -n help > /dev/null
fi

echo "✓ Pre-commit checks passed"
```

Make executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

## Local Development Workflow

### Daily Development

```bash
# 1. Start your day
cd go-framework
make start

# 2. Work on services
cd ../go-auth-service
# ... make changes ...

# 3. Test changes
cd ../go-framework
make rebuild SERVICE=auth-service
make test-integration

# 4. Debug if needed
make logs-service SERVICE=auth-service
make shell SERVICE=auth-service

# 5. End of day
make stop-keep-data  # Preserve data for tomorrow
```

### Making Changes to Framework

```bash
# 1. Create feature branch
git checkout -b feature/my-improvement

# 2. Make changes
# Edit scripts, Makefile, docs, etc.

# 3. Test locally
./scripts/utilities/my-new-script.sh
make my-new-command

# 4. Lint
shellcheck scripts/utilities/my-new-script.sh

# 5. Update documentation
# Edit docs/TOOLS.md, README.md, etc.

# 6. Commit
git add .
git commit -m "feat: add my improvement"

# 7. Push and create PR
git push origin feature/my-improvement
```

---

## Best Practices

### Code Review Checklist

- [ ] Script follows standard template
- [ ] Proper error handling (`set -e`, validation)
- [ ] Clear, helpful error messages
- [ ] Documented in TOOLS.md
- [ ] Makefile target added (if applicable)
- [ ] Tested manually
- [ ] Linted with ShellCheck
- [ ] Works on multiple platforms (if possible)
- [ ] Idempotent (safe to run multiple times)
- [ ] No hardcoded secrets or sensitive data
- [ ] Proper use of colors and emojis for output

### Performance Tips

1. **Avoid Unnecessary Subshells**
   ```bash
   # Slow
   count=$(cat file.txt | wc -l)
   
   # Fast
   count=$(wc -l < file.txt)
   ```

2. **Use Built-ins When Possible**
   ```bash
   # Slow (external commands)
   basename "$path"
   dirname "$path"
   
   # Fast (parameter expansion)
   "${path##*/}"  # basename
   "${path%/*}"   # dirname
   ```

3. **Parallel Operations**
   ```bash
   # Sequential
   for service in "${services[@]}"; do
       build_service "$service"
   done
   
   # Parallel
   for service in "${services[@]}"; do
       build_service "$service" &
   done
   wait
   ```

### Security Best Practices

1. **Never Commit Secrets**
   - Use .env files (git-ignored)
   - Use environment variables
   - Document required secrets

2. **Validate User Input**
   ```bash
   # Sanitize input
   service_name="${1//[^a-zA-Z0-9_-]/}"
   
   # Validate against whitelist
   valid_services=("auth" "user" "tenant")
   if [[ ! " ${valid_services[*]} " =~ " ${service_name} " ]]; then
       echo "Invalid service name"
       exit 1
   fi
   ```

3. **Use Principle of Least Privilege**
   - Don't require root unless necessary
   - Check permissions before operations
   - Use sudo only when needed

4. **Secure Temporary Files**
   ```bash
   # Secure temp file
   temp_file=$(mktemp)
   chmod 600 "$temp_file"
   
   # Cleanup on exit
   trap 'rm -f "$temp_file"' EXIT
   ```

---

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [TOOLS.md](TOOLS.md) - Tool reference
- [TESTING.md](TESTING.md) - Testing guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines

---

**Last Updated:** 2024-01-15
