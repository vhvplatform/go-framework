#!/bin/bash
#
# Script: clone-repos.sh
# Description: Clone all microservice repositories to workspace
# Usage: ./clone-repos.sh
#
# This script clones all required repositories for the SaaS Platform:
#   - go-shared-go (cloned as go-shared): Shared library code
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
#   GITHUB_ORG - GitHub organization (default: vhvplatform)
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
#   - Clones from vhvplatform GitHub organization
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

set -e

GITHUB_ORG="${GITHUB_ORG:-vhvplatform}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"

echo "📂 Cloning repositories to ${WORKSPACE_DIR}..."
mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

# List of all service repositories
# Format: "github-repo-name:local-directory-name" (or just "repo-name" if they match)
repos=(
    "go-shared-go:go-shared"
    "go-api-gateway"
    "go-auth-service"
    "go-user-service"
    "go-tenant-service"
    "go-notification-service"
    "go-system-config-service"
    "go-infrastructure"
    "go-framework"
)

echo "Cloning from GitHub organization: ${GITHUB_ORG}"
echo ""

for repo_entry in "${repos[@]}"; do
    # Parse repo entry (handle both "repo" and "github-repo:local-dir" formats)
    if [[ "$repo_entry" == *":"* ]]; then
        github_repo="${repo_entry%%:*}"
        local_dir="${repo_entry##*:}"
    else
        github_repo="$repo_entry"
        local_dir="$repo_entry"
    fi
    
    if [ -d "$local_dir" ]; then
        echo "⏭️  ${local_dir} already exists, skipping..."
        cd "${local_dir}"
        echo "   📍 $(git remote get-url origin)"
        cd ..
    else
        echo "📥 Cloning ${github_repo}..."
        if [ "$github_repo" != "$local_dir" ]; then
            git clone "https://github.com/${GITHUB_ORG}/${github_repo}.git" "$local_dir" || {
                echo "⚠️  Failed to clone ${github_repo}, it might not exist yet"
            }
        else
            git clone "https://github.com/${GITHUB_ORG}/${github_repo}.git" || {
                echo "⚠️  Failed to clone ${github_repo}, it might not exist yet"
            }
        fi
    fi
done

echo ""
echo "✅ Repository cloning complete!"
echo ""
echo "Workspace structure:"
tree -L 1 "${WORKSPACE_DIR}" 2>/dev/null || ls -la "${WORKSPACE_DIR}"
echo ""
echo "To navigate to workspace: cd ${WORKSPACE_DIR}"
