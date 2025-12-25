#!/bin/bash

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
