#!/bin/bash
set -e

WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/saas-platform}"

echo "🔧 Initializing workspace..."

# Create workspace directory if it doesn't exist
mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

# Check if devtools exists
if [ ! -d "saas-devtools" ]; then
    echo "⚠️  saas-devtools not found. Run 'make setup-repos' first."
    exit 1
fi

# Create .env file from example
echo "⚙️  Setting up environment configuration..."
if [ ! -f "saas-devtools/docker/.env" ]; then
    cp "saas-devtools/docker/.env.example" "saas-devtools/docker/.env"
    echo "✅ Created .env file from template"
    echo "   Please edit saas-devtools/docker/.env with your configuration"
else
    echo "✅ .env file already exists"
fi

# Initialize go modules in each service
echo ""
echo "📦 Initializing Go modules..."
for service in saas-api-gateway saas-auth-service saas-user-service saas-tenant-service saas-notification-service saas-system-config-service; do
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
if [ ! -L "devtools" ]; then
    ln -s saas-devtools devtools
    echo "✅ Created 'devtools' symlink"
fi

# Create workspace go.work if it doesn't exist
if [ ! -f "go.work" ]; then
    echo ""
    echo "📝 Creating Go workspace file..."
    go work init || echo "⚠️  go work not supported in this Go version"
    
    # Add all service modules to workspace
    for service in saas-shared-go saas-api-gateway saas-auth-service saas-user-service saas-tenant-service saas-notification-service saas-system-config-service; do
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
echo "  1. Edit devtools/docker/.env with your configuration"
echo "  2. Start services: cd devtools && make start"
echo "  3. Check status: cd devtools && make status"
echo ""
