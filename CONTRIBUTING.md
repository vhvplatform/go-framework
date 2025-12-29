# Contributing to SaaS Platform Developer Tools

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help others learn and grow

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/vhvplatform/go-framework/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, versions, etc.)
   - Logs or error messages

### Suggesting Features

1. Open an issue with the `feature-request` label
2. Describe the feature and its use case
3. Explain why it would be valuable
4. Include examples if possible

### Submitting Changes

1. **Fork** the repository
2. **Create a branch** for your changes
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following our coding standards
4. **Test your changes** thoroughly
5. **Commit** with clear messages following [Conventional Commits](https://www.conventionalcommits.org/)
6. **Push** to your fork
7. **Create a Pull Request** with:
   - Clear description of changes
   - Link to related issues
   - Screenshots/examples if applicable

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/go-framework.git
cd go-framework

# Add upstream remote
git remote add upstream https://github.com/vhvplatform/go-framework.git

# Install dependencies
make setup
```

### Line Endings (Important for Windows Users)

This repository uses a `.gitattributes` file to ensure all shell scripts, Go files, Makefiles, and other text files always use Unix-style line endings (LF) instead of Windows-style line endings (CRLF). This is critical for shell scripts to execute properly on Unix-like systems.

**On Windows/WSL:**
- Git automatically handles line ending conversion based on `.gitattributes`
- Shell scripts checked out from the repository will have LF line endings
- If you encounter "cannot execute: required file not found" errors, it usually means the file has CRLF line endings

**To fix line ending issues:**
```bash
# Re-checkout files with correct line endings
git rm --cached -r .
git reset --hard

# Or convert individual files if needed
dos2unix scripts/dev/wait-for-services.sh
```

**Git Configuration:**
The repository's `.gitattributes` file automatically manages this, but for reference:
- `*.sh text eol=lf` - Forces LF for shell scripts
- `*.go text eol=lf` - Forces LF for Go files
- `Makefile text eol=lf` - Forces LF for Makefiles

## Coding Standards

### Shell Scripts

#### Basic Requirements

- Use `#!/bin/bash` shebang (must be the first line with no leading whitespace)
- Set executable permissions: `chmod +x script.sh` (Git will track this)
- Use `set -e` for error handling  
- Use `set -u` to catch undefined variables
- Use `set -o pipefail` for pipeline failures
- Add comprehensive header comments
- Include usage examples in headers
- Make scripts idempotent when possible
- Always use Unix line endings (LF) - `.gitattributes` enforces this

#### Script Header Template

```bash
#!/bin/bash
#
# Script: script-name.sh
# Description: What this script does
# Usage: ./script-name.sh [OPTIONS]
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
#
# Environment Variables:
#   VAR_NAME - Description (default: default_value)
#
# Examples:
#   ./script-name.sh
#   VAR_NAME=custom ./script-name.sh --verbose
#
# Requirements:
#   - Docker must be installed
#   - Services must be running
#
# Author: VHV Corp
# Last Modified: YYYY-MM-DD
#

set -e
set -u
set -o pipefail
```

#### Variable Naming

```bash
# Constants: UPPER_SNAKE_CASE
readonly MAX_RETRIES=3
readonly DEFAULT_TIMEOUT=30

# Environment variables: UPPER_SNAKE_CASE with defaults
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace}"

# Local variables: lower_snake_case
local service_name="auth-service"
local retry_count=0
```

#### Error Handling

```bash
# Check command success
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found" >&2
    exit 1
fi

# Check file existence
if [[ ! -f "$config_file" ]]; then
    echo "Error: Config file not found: $config_file" >&2
    exit 1
fi

# Trap errors for cleanup
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
```

#### Quoting Best Practices

```bash
# Always quote variables
echo "$variable"
echo "${WORKSPACE_DIR}/path"

# Quote command substitutions
current_dir="$(pwd)"

# Use arrays for multiple items
services=("auth" "user" "tenant")
for service in "${services[@]}"; do
    echo "$service"
done
```

#### Function Organization

```bash
# Helper functions at top
log_info() {
    echo -e "${GREEN}$*${NC}"
}

log_error() {
    echo -e "${RED}$*${NC}" >&2
}

# Validation functions
check_prerequisites() {
    # Validation logic
}

# Main business logic
do_something() {
    # Main logic
}

# Main function at bottom
main() {
    check_prerequisites
    do_something
    log_info "Complete"
}

# Execute
main "$@"
```

#### Common Patterns

**Retry Logic:**
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
    
    echo "Command failed after $max_attempts attempts" >&2
    return 1
}
```

**User Confirmation:**
```bash
confirm() {
    local prompt="$1"
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

if confirm "Are you sure?"; then
    echo "Proceeding..."
fi
```

#### Testing Scripts

```bash
# 0. Check executable permissions and line endings
ls -la script.sh  # Should show -rwxr-xr-x
file script.sh    # Should show "Bourne-Again shell script" without "CRLF"

# 1. Syntax check
bash -n script.sh

# 2. ShellCheck (install with: brew install shellcheck)
shellcheck script.sh

# 3. Set executable if needed
chmod +x script.sh
git add script.sh  # Git tracks the executable bit

# 4. Manual testing
./script.sh
./script.sh --help
./script.sh --invalid  # Test error handling
```

#### Documentation in Scripts

- Add header with description, usage, and examples
- Document all environment variables
- Explain prerequisites and requirements
- Include troubleshooting tips
- Cross-reference related scripts

Example:
```bash
#!/bin/bash
#
# Script: restart-service.sh
# Description: Restart a specific microservice quickly
#
# See Also:
#   - rebuild.sh: For code changes
#   - wait-for-services.sh: Wait for health
```


### Makefiles

- Use `.PHONY` for targets
- Add help text with `## comment`
- Use color codes for output
- Group related targets

Example:
```makefile
.PHONY: my-target

my-target: ## Description of what this does
	@echo "${GREEN}Running target...${RESET}"
	@./script.sh
```

### Documentation

- Use clear, concise language
- Include code examples
- Add troubleshooting sections
- Keep formatting consistent
- Test all commands before documenting

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks

Examples:
```
feat(scripts): add database backup script

Add script to backup MongoDB with compression
and automatic timestamping.

Closes #123
```

```
fix(docker): resolve port conflict issue

Update docker-compose.yml to use alternative
ports when defaults are unavailable.

Fixes #456
```

## Testing

### Before Submitting

1. **Test scripts**
   ```bash
   # Make executable
   chmod +x your-script.sh
   
   # Test execution
   ./your-script.sh
   ```

2. **Test Docker changes**
   ```bash
   make clean-all
   make start
   make status
   ```

3. **Test Makefile changes**
   ```bash
   make your-new-target
   ```

4. **Test documentation**
   - Read through your docs
   - Test all commands
   - Check formatting

### Automated Tests

Run tests before submitting:
```bash
make test
```

## Pull Request Process

1. **Update Documentation** - Add/update docs for your changes
2. **Update CHANGELOG.md** - Add entry for your changes
3. **Test Thoroughly** - Ensure everything works
4. **Request Review** - Tag relevant maintainers
5. **Address Feedback** - Make requested changes
6. **Squash Commits** - Clean up commit history if requested

## File Organization

```
framework/
├── scripts/
│   ├── setup/       # Setup and installation
│   ├── dev/         # Development utilities
│   ├── database/    # Database management
│   ├── testing/     # Test automation
│   ├── build/       # Build scripts
│   ├── deployment/  # Deployment
│   ├── monitoring/  # Monitoring utilities
│   └── utilities/   # General utilities
├── configs/
│   ├── vscode/      # VS Code configurations
│   ├── git/         # Git hooks and config
│   └── linting/     # Linter configurations
├── docs/            # Documentation
├── docker/          # Docker Compose files
├── fixtures/        # Test data
├── postman/         # API collections
└── tools/           # Developer tools
```

## Adding New Scripts

1. Create script in appropriate directory
2. Make it executable: `chmod +x script.sh`
3. Add to Makefile if it's a common operation
4. Document in README.md or relevant docs
5. Test thoroughly
6. Submit PR

Example:
```bash
# Create script
cat > scripts/utilities/my-script.sh << 'EOF'
#!/bin/bash
set -e
echo "My script"
# ... script content ...
EOF

# Make executable
chmod +x scripts/utilities/my-script.sh

# Add to Makefile
echo 'my-command: ## Description\n\t@./scripts/utilities/my-script.sh' >> Makefile
```

## Adding Documentation

1. Use Markdown format
2. Follow existing structure
3. Include code examples
4. Add table of contents for long docs
5. Link to related docs

## Questions?

- Open an issue for discussion
- Check existing issues and PRs
- Read through documentation
- Ask in pull request

## Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Credited in release notes
- Added to contributors list

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Thank You! 🙏

Your contributions help make this project better for everyone!
