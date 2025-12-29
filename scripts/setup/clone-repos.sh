#!/bin/bash
#
# Script: clone-repos.sh
# Description: Clone all repositories to workspace/go directory
# Usage: ./clone-repos.sh
#
# This script clones all required repositories for the SaaS Platform into
# a single go/ directory:
#   - go-framework: Development tools and scripts
#   - go-infrastructure: Infrastructure as code
#   - go-shared: Shared library code
#   - go-api-gateway: API Gateway service
#   - go-auth-service: Authentication service
#   - go-user-service: User management service
#   - go-tenant-service: Multi-tenancy service
#   - go-notification-service: Notification service
#   - go-system-config-service: System configuration service
#
# Directory Structure:
#   All repositories are cloned into go/ subdirectory:
#   workspace/
#   └── go/
#       ├── go-framework/
#       ├── go-infrastructure/
#       ├── go-shared/
#       ├── go-api-gateway/
#       ├── go-auth-service/
#       └── ... (other services)
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
#   - Creates WORKSPACE_DIR and go/ subdirectory if they don't exist
#   - Clones from vhvplatform GitHub organization
#   - All repositories are cloned at the same level inside go/
#
# Author: VHV Corp
# Last Modified: 2024-12-29
#

set -e

GITHUB_ORG="${GITHUB_ORG:-vhvplatform}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"
GO_DIR="${WORKSPACE_DIR}/go"

echo "📂 Cloning repositories to ${GO_DIR}..."
mkdir -p "${GO_DIR}"
cd "${GO_DIR}"

# List of all repositories to clone into go/ directory
repos=(
    "go-framework"
    "go-infrastructure"
    "go-shared"
    "go-api-gateway"
    "go-auth-service"
    "go-user-service"
    "go-tenant-service"
    "go-notification-service"
    "go-system-config-service"
)

echo "Cloning repositories to ${GO_DIR}..."
echo "GitHub organization: ${GITHUB_ORG}"
echo ""

for repo in "${repos[@]}"; do
    if [ -d "$repo" ]; then
        echo "⏭️  ${repo} already exists, skipping..."
        cd "${repo}"
        echo "   📍 $(git remote get-url origin)"
        cd "${GO_DIR}"
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
echo "${WORKSPACE_DIR}/"
echo "└── go/"
tree -L 1 "${GO_DIR}" 2>/dev/null || {
    if [ -d "${GO_DIR}" ] && [ "$(ls -A "${GO_DIR}" 2>/dev/null)" ]; then
        # Format directory listing as tree structure:
        # - All items except last get "├──" prefix
        # - Last item gets "└──" prefix
        # awk logic: buffer current line, print previous line with ├──,
        # in END block print last line with └──
        ls -1 "${GO_DIR}" | awk '{
            if (NR > 1) print prev
            prev = "    ├── " $0
        }
        END {
            if (prev != "") print "    └── " substr(prev, 9)
        }'
    else
        echo "    (empty)"
    fi
}
echo ""
echo "To navigate to workspace: cd ${WORKSPACE_DIR}"
