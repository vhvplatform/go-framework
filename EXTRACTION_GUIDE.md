# Developer Tools Repository Extraction Guide

This guide explains how to extract the `framework/` directory from the monorepo into its own separate repository (`go-framework`).

## Why Extract?

- **Separation of Concerns** - Developer tools are independent of service code
- **Independent Versioning** - Tools can be versioned separately
- **Easier Maintenance** - Focused repository for tooling
- **Reusability** - Can be used across multiple projects

## Prerequisites

- Git 2.24+ (for `git filter-repo`)
- Python 3+ (required by git-filter-repo)
- Clean working directory (commit or stash changes)

## Step 1: Install git-filter-repo

### macOS
```bash
brew install git-filter-repo
```

### Linux
```bash
pip3 install git-filter-repo
```

### Windows (WSL)
```bash
pip3 install git-filter-repo
```

## Step 2: Create New Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `go-framework`
3. Description: "Developer tools and utilities for Go Platform"
4. Visibility: Public (or Private if preferred)
5. Don't initialize with README (we're bringing history)
6. Click "Create repository"

## Step 3: Clone Monorepo

```bash
# Clone fresh copy of monorepo
git clone https://github.com/vhvcorp/go-framework-go.git go-framework-temp
cd go-framework-temp
```

## Step 4: Extract framework Directory

```bash
# Filter repository to only include framework/ directory
git filter-repo --path framework/ --path-rename framework/:

# This rewrites Git history to only include commits touching framework/
# The --path-rename moves files from framework/ to root
```

**Warning:** This command rewrites Git history. Only do this on a fresh clone, not your working repository!

## Step 5: Set New Remote

```bash
# Remove old remote
git remote remove origin

# Add new remote for go-framework repository
git remote add origin https://github.com/vhvcorp/go-framework.git
```

## Step 6: Push to New Repository

```bash
# Push all branches and tags
git push -u origin --all
git push -u origin --tags
```

## Step 7: Update Docker Compose References

After extraction, update Docker Compose files to reference published images instead of local builds.

### Before (monorepo)
```yaml
auth-service:
  build:
    context: ../..
    dockerfile: services/auth-service/Dockerfile
```

### After (separate repo)
```yaml
auth-service:
  image: ghcr.io/vhvcorp/go-auth-service:dev
```

Update `docker/docker-compose.yml`:

```bash
cd docker

# Replace build contexts with image references
# For each service, change from:
#   build: ...
# To:
#   image: ghcr.io/vhvcorp/go-<service>:dev
```

## Step 8: Update Documentation

Update references to repository structure:

1. **README.md** - Update clone instructions
   ```bash
   # Old
   git clone https://github.com/vhvcorp/go-framework-go.git
   cd go-framework-go/framework
   
   # New
   git clone https://github.com/vhvcorp/go-framework.git
   cd go-framework
   ```

2. **scripts/setup/clone-repos.sh** - Already clones repos separately, no changes needed

3. **CONTRIBUTING.md** - Update repository URLs

## Step 9: Test Everything

```bash
# From extracted repository
cd go-framework

# Setup should work
make setup

# Start services
make start

# Check status
make status

# Run tests
make test
```

## Step 10: Update Original Monorepo

In the original monorepo, update README to point to new framework repo:

```markdown
## Developer Tools

Developer tools have been extracted to a separate repository for easier maintenance.

**Repository:** https://github.com/vhvcorp/go-framework

**Quick Start:**
\```bash
git clone https://github.com/vhvcorp/go-framework.git
cd go-framework
make setup
make start
\```

See the [framework README](https://github.com/vhvcorp/go-framework) for complete documentation.
```

## Step 11: Archive framework in Monorepo (Optional)

Optionally remove framework/ from monorepo after extraction:

```bash
cd go-framework-go
git rm -r framework/
git commit -m "docs: extract framework to separate repository

Framework have been extracted to:
https://github.com/vhvcorp/go-framework

See that repository for development tools and scripts."
git push
```

## Verification Checklist

After extraction, verify:

- [ ] New repository is accessible
- [ ] Git history is preserved
- [ ] All files are present in root directory
- [ ] `make setup` works
- [ ] `make start` launches services
- [ ] `make status` shows healthy services
- [ ] All scripts are executable
- [ ] Documentation links are updated
- [ ] Docker Compose uses published images
- [ ] Postman collections work
- [ ] VS Code configurations work

## Rollback

If extraction fails:

```bash
# Simply delete the temp directory
rm -rf go-framework-temp

# And try again from Step 3
```

The original monorepo is untouched.

## Benefits After Extraction

✅ Independent versioning  
✅ Focused development  
✅ Cleaner repository structure  
✅ Reusable across projects  
✅ Faster CI/CD  
✅ Smaller clone size  

## Maintenance After Extraction

### Updating Tools

```bash
cd go-framework
git checkout -b feature/new-tool
# Make changes
git commit -m "feat(tools): add new utility script"
git push origin feature/new-tool
# Create PR
```

### Syncing Changes

If you make changes in monorepo framework/ before extraction, you can:

1. Copy changes to extracted repo
2. Or re-run extraction (loses extracted repo history)

### Using in Other Projects

```bash
# In any project
git clone https://github.com/vhvcorp/go-framework.git tools
cd tools
make setup
# Customize for your project
```

## Troubleshooting

### git-filter-repo not found
```bash
# Install with pip
pip3 install git-filter-repo

# Or use package manager
brew install git-filter-repo  # macOS
```

### Permission denied when pushing
```bash
# Authenticate with GitHub
gh auth login

# Or configure Git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Services won't start with image references
```bash
# Build and push images first
make docker-build
make docker-push

# Then start services
make start
```

## Questions?

- Open an issue in the new repository
- Check the troubleshooting guide
- Ask in discussions

---

**Last Updated:** 2024-01-01  
**Status:** Ready for extraction after Phase 4 completion
