#!/bin/bash
set -e

GITHUB_ORG="${GITHUB_ORG:-vhvcorp}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"

echo "📂 Cloning repositories to ${WORKSPACE_DIR}..."
mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

# List of all service repositories
repos=(
    "go-shared-go"
    "go-api-gateway"
    "go-auth-service"
    "go-user-service"
    "go-tenant-service"
    "go-notification-service"
    "go-system-config-service"
    "go-infrastructure"
    "go-devtools"
)

echo "Cloning from GitHub organization: ${GITHUB_ORG}"
echo ""

for repo in "${repos[@]}"; do
    if [ -d "$repo" ]; then
        echo "⏭️  ${repo} already exists, skipping..."
        cd "${repo}"
        echo "   📍 $(git remote get-url origin)"
        cd ..
    else
        echo "📥 Cloning ${repo}..."
        git clone "https://github.com/${GITHUB_ORG}/${repo}.git" || {
            echo "⚠️  Failed to clone ${repo}, it might not exist yet"
        }
    fi
done

echo ""
echo "✅ Repository cloning complete!"
echo ""
echo "Workspace structure:"
tree -L 1 "${WORKSPACE_DIR}" 2>/dev/null || ls -la "${WORKSPACE_DIR}"
echo ""
echo "To navigate to workspace: cd ${WORKSPACE_DIR}"
