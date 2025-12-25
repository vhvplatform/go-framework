#!/bin/bash
set -e

echo "⏳ Waiting for services to be healthy..."

DOCKER_DIR="$(dirname "$0")/../../docker"
MAX_WAIT=120  # Maximum wait time in seconds
SLEEP_INTERVAL=5

services=(
    "mongodb:27017"
    "redis:6379"
    "rabbitmq:5672"
)

wait_for_service() {
    local host=$1
    local port=$2
    local max_attempts=$((MAX_WAIT / SLEEP_INTERVAL))
    local attempt=1
    
    echo -n "  Waiting for ${host}:${port}... "
    
    while [ $attempt -le $max_attempts ]; do
        if timeout 1 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" 2>/dev/null; then
            echo "✅"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep $SLEEP_INTERVAL
    done
    
    echo "❌ (timeout)"
    return 1
}

cd "${DOCKER_DIR}"

# Wait for infrastructure services first
echo "Infrastructure services:"
for service_addr in "${services[@]}"; do
    IFS=':' read -r host port <<< "$service_addr"
    wait_for_service "$host" "$port" || true
done

# Wait a bit more for services to fully initialize
echo ""
echo "⏳ Waiting for microservices to initialize..."
sleep 10

# Check if services are responding
echo ""
echo "Microservices health check:"
check_http() {
    local name=$1
    local url=$2
    echo -n "  ${name}... "
    if curl -s -f "${url}" > /dev/null 2>&1; then
        echo "✅"
    else
        echo "⚠️  (not responding yet)"
    fi
}

check_http "API Gateway" "http://localhost:8080/health"
check_http "Auth Service" "http://localhost:8081/health"
check_http "User Service" "http://localhost:8082/health"
check_http "Tenant Service" "http://localhost:8083/health"
check_http "Notification Service" "http://localhost:8084/health"
check_http "System Config Service" "http://localhost:8085/health"

echo ""
echo "✅ Services are starting up. They may take a few more seconds to be fully ready."
echo ""
