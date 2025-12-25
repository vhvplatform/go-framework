#!/bin/bash
#
# Script: restart-service.sh
# Description: Restart a specific microservice quickly
# Usage: ./restart-service.sh [OPTIONS] <service-name>
#
# Options:
#   -w, --wait     Wait for service to be healthy after restart
#   -t, --timeout  Timeout in seconds for health check (default: 30)
#   -h, --help     Show this help message
#
# This script:
#   1. Validates service name
#   2. Stops the specified service container
#   3. Starts it again with existing configuration
#   4. Optionally waits for health check to pass
#
# Arguments:
#   service-name   Service name (required)
#                  Examples: auth-service, user-service, api-gateway
#
# Examples:
#   ./restart-service.sh auth-service
#   ./restart-service.sh --wait user-service
#   ./restart-service.sh -w -t 60 api-gateway
#   make restart-service SERVICE=auth-service
#
# Use Cases:
#   - Apply configuration changes
#   - Recover from service crash
#   - Apply environment variable changes
#
# Exit Codes:
#   0 - Success
#   1 - Service not found or restart failed
#   2 - Invalid arguments
#
# Notes:
#   - Does not rebuild the container
#   - Preserves existing data
#   - Quick restart (2-5 seconds)
#
# See Also:
#   - rebuild.sh: For rebuilding with code changes
#   - wait-for-services.sh: Wait for multiple services
#
# Author: VHV Corp
# Last Modified: 2024-12-25
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default values
WAIT_FOR_HEALTH=false
TIMEOUT=30
SERVICE=""

# Function to display usage
usage() {
    grep '^#' "$0" | sed -e 's/^# \?//' -e '/^$/q' | tail -n +2
}

# Function to log info messages
log_info() {
    echo -e "${GREEN}$*${NC}"
}

# Function to log error messages
log_error() {
    echo -e "${RED}$*${NC}" >&2
}

# Function to log warning messages
log_warning() {
    echo -e "${YELLOW}$*${NC}"
}

# Function to log debug messages
log_debug() {
    echo -e "${BLUE}$*${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--wait)
            WAIT_FOR_HEALTH=true
            shift
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 2
            ;;
        *)
            SERVICE="$1"
            shift
            ;;
    esac
done

# Validate service name provided
if [[ -z "$SERVICE" ]]; then
    log_error "Error: Service name is required"
    echo ""
    usage
    exit 2
fi

# Check prerequisites
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    log_error "Error: docker or docker-compose is required but not installed"
    exit 2
fi

# Navigate to docker directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../../docker"

if [[ ! -d "$DOCKER_DIR" ]]; then
    log_error "Error: Docker directory not found: $DOCKER_DIR"
    exit 1
fi

cd "$DOCKER_DIR"

# Check if service exists in docker-compose
if ! docker-compose config --services 2>/dev/null | grep -q "^${SERVICE}$"; then
    log_error "Error: Service '${SERVICE}' not found in docker-compose.yml"
    log_warning "Available services:"
    docker-compose config --services 2>/dev/null | sed 's/^/  - /'
    exit 1
fi

log_info "🔄 Restarting ${SERVICE}..."

# Restart the service
if ! docker-compose restart "${SERVICE}"; then
    log_error "✗ Failed to restart ${SERVICE}"
    exit 1
fi

log_info "✅ ${SERVICE} restarted successfully!"

# Wait for health check if requested
if [[ "$WAIT_FOR_HEALTH" == true ]]; then
    log_debug "Waiting for ${SERVICE} to be healthy (timeout: ${TIMEOUT}s)..."
    
    # Simple health check by checking container status
    elapsed=0
    while [[ $elapsed -lt $TIMEOUT ]]; do
        container_status=$(docker-compose ps -q "${SERVICE}" | xargs docker inspect -f '{{.State.Status}}' 2>/dev/null || echo "unknown")
        
        if [[ "$container_status" == "running" ]]; then
            log_info "✅ ${SERVICE} is healthy!"
            break
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
        
        if [[ $elapsed -ge $TIMEOUT ]]; then
            log_warning "⚠️  Timeout waiting for ${SERVICE} to be healthy"
            log_warning "Check logs with: make logs-service SERVICE=${SERVICE}"
            exit 1
        fi
    done
fi

# Show next steps
echo ""
log_debug "Next steps:"
echo "  View logs:   make logs-service SERVICE=${SERVICE}"
echo "  Check health: make status"
echo "  Shell access: make shell SERVICE=${SERVICE}"
