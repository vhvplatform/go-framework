#!/bin/bash

echo "📊 Opening Prometheus..."

URL="http://localhost:9090"

# Check if Prometheus is running
if ! curl -s "${URL}" > /dev/null 2>&1; then
    echo "⚠️  Prometheus is not responding at ${URL}"
    echo "   Start services with: make start"
    exit 1
fi

echo "Opening ${URL}"

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
