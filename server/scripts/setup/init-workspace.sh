#!/bin/bash
#
# Script: init-workspace.sh
# Description: Initialize workspace directory structure
# Usage: ./init-workspace.sh
#
# This script creates the required directory structure for development:
#   - bin/: Compiled binaries
#   - logs/: Service logs
#   - data/: Persistent data
#   - backups/: Database backups
#
# Environment Variables:
#   WORKSPACE_DIR - Target workspace (default: $HOME/workspace/go-platform)
#
# Examples:
#   ./init-workspace.sh
#   WORKSPACE_DIR=/custom/path ./init-workspace.sh
#   make setup  # Includes this step
#
# Notes:
#   - Safe to run multiple times (idempotent)
#   - Creates directories only if they don't exist
#   - Sets appropriate permissions
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

set -e

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"

echo "🔧 Initializing workspace..."

# Create workspace directory if it doesn't exist
mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

# Check if framework exists
if [ ! -d "go-framework" ]; then
    echo "⚠️  go-framework not found. Run 'make setup-repos' first."
    exit 1
fi

# Create .env file from example
echo "⚙️  Setting up environment configuration..."
if [ ! -f "go-framework/docker/.env" ]; then
    cp "go-framework/docker/.env.example" "go-framework/docker/.env"
    echo "✅ Created .env file from template"
    echo "   Please edit go-framework/docker/.env with your configuration"
else
    echo "✅ .env file already exists"
fi

# Initialize go modules in each service
echo ""
echo "📦 Initializing Go modules..."
for service in go-api-gateway go-auth-service go-user-service go-tenant-service go-notification-service go-system-config-service; do
    if [ -d "$service" ]; then
        echo "  Initializing ${service}..."
        cd "${service}"
        if [ -f "go.mod" ]; then
            go mod download || echo "    ⚠️  Failed to download dependencies"
        fi
        cd ..
    fi
done

# Create helpful symlinks
echo ""
echo "🔗 Creating helpful symlinks..."
if [ ! -L "framework" ]; then
    ln -s go-framework framework
    echo "✅ Created 'framework' symlink"
fi

# Create workspace go.work if it doesn't exist
if [ ! -f "go.work" ]; then
    echo ""
    echo "📝 Creating Go workspace file..."
    go work init || echo "⚠️  go work not supported in this Go version"
    
    # Add all service modules to workspace
    for service in go-shared-go go-api-gateway go-auth-service go-user-service go-tenant-service go-notification-service go-system-config-service; do
        if [ -d "$service" ] && [ -f "$service/go.mod" ]; then
            go work use "./$service" 2>/dev/null || true
        fi
    done
fi

echo ""
echo "✅ Workspace initialization complete!"
echo ""
echo "Workspace location: ${WORKSPACE_DIR}"
echo ""
echo "Next steps:"
echo "  1. Edit framework/docker/.env with your configuration"
echo "  2. Start services: cd framework && make start"
echo "  3. Check status: cd framework && make status"
echo ""
