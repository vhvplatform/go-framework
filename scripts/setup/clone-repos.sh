#!/bin/bash
#
# Script: clone-repos.sh
# Description: Clone all microservice repositories to workspace
# Usage: ./clone-repos.sh
#
# This script clones all required repositories for the SaaS Platform:
#   - go-shared-go: Shared library code
#   - go-api-gateway: API Gateway service
#   - go-auth-service: Authentication service
#   - go-user-service: User management service
#   - go-tenant-service: Multi-tenancy service
#   - go-notification-service: Notification service
#   - go-system-config-service: System configuration service
#   - go-infrastructure: Infrastructure as code
#
# Environment Variables:
#   WORKSPACE_DIR - Target directory (default: $HOME/workspace/go-platform)
#   GITHUB_ORG - GitHub organization (default: vhvcorp)
#
# Requirements:
#   - Git must be installed
#   - GitHub access (may need SSH keys configured)
#   - Internet connection
#
# Examples:
#   ./clone-repos.sh
#   WORKSPACE_DIR=/custom/path ./clone-repos.sh
#   make setup-repos
#
# Notes:
#   - Skips repositories that already exist
#   - Creates WORKSPACE_DIR if it doesn't exist
#   - Clones from vhvcorp GitHub organization
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
