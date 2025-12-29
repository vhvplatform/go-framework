#!/bin/bash

echo "🔌 Setting up port forwarding..."

NAMESPACE="${NAMESPACE:-go-dev}"

# Port forward API Gateway
echo "Forwarding API Gateway (8080)..."
kubectl port-forward -n ${NAMESPACE} svc/api-gateway 8080:8080 &

# Port forward Grafana
echo "Forwarding Grafana (3000)..."
kubectl port-forward -n ${NAMESPACE} svc/grafana 3000:3000 &

# Port forward Prometheus
echo "Forwarding Prometheus (9090)..."
kubectl port-forward -n ${NAMESPACE} svc/prometheus 9090:9090 &

# Port forward Jaeger
echo "Forwarding Jaeger (16686)..."
kubectl port-forward -n ${NAMESPACE} svc/jaeger 16686:16686 &

echo ""
echo "✅ Port forwarding setup complete!"
echo ""
echo "Services available at:"
echo "  API Gateway:  http://localhost:8080"
echo "  Grafana:      http://localhost:3000"
echo "  Prometheus:   http://localhost:9090"
echo "  Jaeger:       http://localhost:16686"
echo ""
echo "Press Ctrl+C to stop all port forwards"

# Wait for all background jobs
wait
