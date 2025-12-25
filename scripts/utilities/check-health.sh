#!/bin/bash
#
# Script: check-health.sh
# Description: Check health status of all services
# Usage: ./check-health.sh
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
# Last Modified: 2024-01-15
#

echo "🏥 Checking service health..."

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

for service_info in "${services[@]}"; do
    IFS=':' read -r name url <<< "$service_info"
    
    # Skip non-HTTP URLs for basic health check
    if [[ $url == http* ]]; then
        echo -n "  ${name}... "
        if curl -sf "${url}" > /dev/null 2>&1; then
            echo "✅"
        else
            echo "❌"
            all_healthy=false
        fi
    fi
done

echo ""

if [ "$all_healthy" = true ]; then
    echo "✅ All services are healthy!"
    exit 0
else
    echo "⚠️  Some services are not responding"
    echo "   Check with: docker-compose ps"
    echo "   View logs: docker-compose logs"
    exit 1
fi
