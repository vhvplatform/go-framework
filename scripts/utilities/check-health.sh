#!/bin/bash

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
