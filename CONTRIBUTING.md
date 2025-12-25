# Contributing to SaaS Platform Developer Tools

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help others learn and grow

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/vhvcorp/go-devtools/issues)
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
git clone https://github.com/YOUR_USERNAME/go-devtools.git
cd go-devtools

# Add upstream remote
git remote add upstream https://github.com/vhvcorp/go-devtools.git

# Install dependencies
make setup
```

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Add helpful echo messages
- Include usage examples in comments
- Make scripts idempotent when possible

Example:
```bash
#!/bin/bash
set -e

echo "🔧 Running my script..."

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

# Do work
echo "✅ Script complete!"
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
devtools/
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
