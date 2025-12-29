#!/bin/bash
#
# Script: open-grafana.sh
# Description: Open Grafana dashboard in browser
# Usage: ./open-grafana.sh
#
# This script opens the Grafana web interface in your default browser.
#
# Default URL: http://localhost:3000
#
# Default Credentials:
#   - Username: admin
#   - Password: admin (change on first login)
#
# Available Dashboards:
#   - Service Metrics: Request rates, latency, errors
#   - Resource Usage: CPU, memory, disk
#   - Database Metrics: Query performance, connections
#   - Queue Metrics: Message rates, queue depths
#   - Custom Dashboards: User-created dashboards
#
# Requirements:
#   - Grafana container must be running
#   - Port 3000 accessible
#
# Examples:
#   ./open-grafana.sh
#   make open-grafana
#
# Key Metrics to Monitor:
#   - Request rate (req/s)
#   - Response time (p50, p95, p99)
#   - Error rate (%)
#   - CPU usage (%)
#   - Memory usage (MB)
#   - Active connections
#
# Troubleshooting:
#   - If URL doesn't open: Check Grafana is running
#     docker ps | grep grafana
#   - If login fails: Reset password
#     docker exec grafana grafana-cli admin reset-admin-password newpass
#   - If no data: Check Prometheus connection
#     Configuration > Data Sources > Prometheus
#
# See Also:
#   - open-prometheus.sh: View raw metrics
#   - open-jaeger.sh: View distributed traces
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

echo "📊 Opening Grafana..."

URL="http://localhost:3000"

# Check if Grafana is running
if ! curl -s "${URL}" > /dev/null 2>&1; then
    echo "⚠️  Grafana is not responding at ${URL}"
    echo "   Start services with: make start"
    exit 1
fi

echo "Opening ${URL}"
echo "Default credentials: admin / admin"

# Open in browser
if command -v open &> /dev/null; then
    open "${URL}"
elif command -v xdg-open &> /dev/null; then
    xdg-open "${URL}"
elif command -v wslview &> /dev/null; then
    wslview "${URL}"
else
    echo "Please open ${URL} in your browser"
fi
