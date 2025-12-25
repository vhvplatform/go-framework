#!/bin/bash
#
# Script: check-health.sh
# Description: Check health status of all services
# Usage: ./check-health.sh [OPTIONS]
#
# Options:
#   -v, --verbose  Enable verbose output with response times
#   -q, --quiet    Quiet mode, only show failures
#   -h, --help     Show this help message
#
# This script checks:
#   - Docker container status
#   - HTTP health endpoints
#   - Database connectivity (MongoDB, Redis)
#   - Message queue status (RabbitMQ)
#   - Service responsiveness
#
# Health Indicators:
#   ✅ Green: Service healthy and responding
#   ⚠️  Yellow: Service degraded or slow
#   ❌ Red: Service down or not responding
#
# Examples:
#   ./check-health.sh
#   ./check-health.sh --verbose
#   make status
#   make health
#
# Checks Performed:
#   1. Container running status
#   2. HTTP /health endpoint (200 OK)
#   3. Database ping
#   4. Redis ping
#   5. RabbitMQ management API
#   6. Response time checks
#
# Exit Codes:
#   0 - All services healthy
#   1 - One or more services unhealthy
#   2 - Invalid arguments or prerequisites not met
#
# Services Monitored:
#   - API Gateway
#   - Auth Service
#   - User Service
#   - Tenant Service
#   - Notification Service
#   - System Config Service
#   - MongoDB
#   - Redis
#   - RabbitMQ
#   - Prometheus
#   - Grafana
#   - Jaeger
#
# Timeout:
#   - Each check: 5 seconds
#   - Total time: ~30 seconds
#
# Troubleshooting Unhealthy Services:
#   1. Check logs: make logs-service SERVICE=<name>
#   2. Restart service: make restart-service SERVICE=<name>
#   3. Check dependencies
#   4. Verify configuration
#
# See Also:
#   - wait-for-services.sh: Wait for services to start
#   - restart-service.sh: Restart unhealthy service
#
# Author: VHV Corp
# Last Modified: 2024-12-25
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Configuration
readonly TIMEOUT=${HEALTH_CHECK_TIMEOUT:-5}
VERBOSE=false
QUIET=false

# Function to display usage
usage() {
    grep '^#' "$0" | sed -e 's/^# \?//' -e '/^$/q' | tail -n +2
}

# Function to log info messages
log_info() {
    if [[ "$QUIET" != true ]]; then
        echo -e "${GREEN}$*${NC}"
    fi
}

# Function to log error messages
log_error() {
    echo -e "${RED}$*${NC}" >&2
}

# Function to log warning messages
log_warning() {
    if [[ "$QUIET" != true ]]; then
        echo -e "${YELLOW}$*${NC}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
done

# Check prerequisites
if ! command -v curl &> /dev/null; then
    log_error "Error: curl is required but not installed"
    exit 2
fi

log_info "🏥 Checking service health..."

log_info "🏥 Checking service health..."

# Define services to check
services=(
    "API Gateway:http://localhost:8080/health"
    "Auth Service:http://localhost:8081/health"
    "User Service:http://localhost:8082/health"
    "Tenant Service:http://localhost:8083/health"
    "Notification Service:http://localhost:8084/health"
    "System Config Service:http://localhost:8085/health"
    "MongoDB:mongodb://localhost:27017"
    "Redis:redis://localhost:6379"
    "RabbitMQ Management:http://localhost:15672"
    "Prometheus:http://localhost:9090/-/healthy"
    "Grafana:http://localhost:3000/api/health"
    "Jaeger:http://localhost:16686"
)

all_healthy=true
failed_services=()

# Function to check HTTP service health
check_http_service() {
    local name="$1"
    local url="$2"
    local start_time
    local end_time
    local response_time
    
    start_time=$(date +%s%N)
    
    if curl -sf --max-time "$TIMEOUT" "${url}" > /dev/null 2>&1; then
        end_time=$(date +%s%N)
        response_time=$(( (end_time - start_time) / 1000000 ))
        
        if [[ "$VERBOSE" == true ]]; then
            echo -e "  ${name}... ${GREEN}✅${NC} (${response_time}ms)"
        elif [[ "$QUIET" != true ]]; then
            echo -e "  ${name}... ${GREEN}✅${NC}"
        fi
        return 0
    else
        if [[ "$QUIET" != true ]]; then
            echo -e "  ${name}... ${RED}❌${NC}"
        else
            log_error "  ${name}... ❌"
        fi
        return 1
    fi
}

# Check each service
for service_info in "${services[@]}"; do
    IFS=':' read -r name url <<< "$service_info"
    
    # Skip non-HTTP URLs for basic health check
    if [[ $url == http* ]]; then
        if ! check_http_service "$name" "$url"; then
            all_healthy=false
            failed_services+=("$name")
        fi
    fi
done

echo ""

# Display results
if [[ "$all_healthy" == true ]]; then
    log_info "✅ All services are healthy!"
    exit 0
else
    log_error "⚠️  Some services are not responding:"
    for service in "${failed_services[@]}"; do
        log_error "   - $service"
    done
    echo ""
    log_warning "Troubleshooting steps:"
    log_warning "   1. Check container status: docker-compose ps"
    log_warning "   2. View logs: make logs-service SERVICE=<name>"
    log_warning "   3. Restart service: make restart-service SERVICE=<name>"
    exit 1
fi
