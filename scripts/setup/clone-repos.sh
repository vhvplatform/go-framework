#!/bin/bash
#
# Script: clone-repos.sh
# Description: Clone all microservice repositories to workspace
# Usage: ./clone-repos.sh
#
# This script clones all required repositories for the SaaS Platform:
#   - go-shared: Shared library code
#   - go-api-gateway: API Gateway service
#   - go-auth-service: Authentication service
#   - go-user-service: User management service
#   - go-tenant-service: Multi-tenancy service
#   - go-notification-service: Notification service
#   - go-system-config-service: System configuration service
#   - go-infrastructure: Infrastructure as code
#   - go-framework: Development tools and scripts
#
# Directory Structure:
#   Service repositories are cloned into a go/ subdirectory:
#   workspace/
#   ├── go-framework/
#   ├── go-infrastructure/
#   └── go/
#       ├── go-shared/
#       ├── go-api-gateway/
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
#
# Author: VHV Corp
# Last Modified: 2024-12-29
#

set -e

GITHUB_ORG="${GITHUB_ORG:-vhvplatform}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace/go-platform}"
GO_DIR="${WORKSPACE_DIR}/go"

echo "📂 Cloning repositories to ${WORKSPACE_DIR}..."
mkdir -p "${WORKSPACE_DIR}"
mkdir -p "${GO_DIR}"

# Clone go-framework at workspace root if not already there
if [ ! -d "${WORKSPACE_DIR}/go-framework" ]; then
    echo "📥 Cloning go-framework to ${WORKSPACE_DIR}..."
    cd "${WORKSPACE_DIR}"
    git clone "https://github.com/${GITHUB_ORG}/go-framework.git" || {
        echo "⚠️  Failed to clone go-framework"
    }
fi

# Clone infrastructure repo at workspace root if not already there
if [ ! -d "${WORKSPACE_DIR}/go-infrastructure" ]; then
    echo "📥 Cloning go-infrastructure to ${WORKSPACE_DIR}..."
    cd "${WORKSPACE_DIR}"
    git clone "https://github.com/${GITHUB_ORG}/go-infrastructure.git" || {
        echo "⚠️  Failed to clone go-infrastructure"
    }
fi

# List of service repositories to clone into go/ subdirectory
service_repos=(
    "go-shared"
    "go-api-gateway"
    "go-auth-service"
    "go-user-service"
    "go-tenant-service"
    "go-notification-service"
    "go-system-config-service"
)

echo "Cloning service repositories to ${GO_DIR}..."
echo "GitHub organization: ${GITHUB_ORG}"
echo ""

cd "${GO_DIR}"

for repo in "${service_repos[@]}"; do
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
tree -L 2 "${WORKSPACE_DIR}" 2>/dev/null || {
    echo "├── go-framework/"
    echo "├── go-infrastructure/"
    echo "└── go/"
    if [ -d "${GO_DIR}" ] && [ "$(ls -A "${GO_DIR}" 2>/dev/null)" ]; then
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
