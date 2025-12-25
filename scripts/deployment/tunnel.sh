#!/bin/bash

echo "🔌 Creating tunnel to cluster..."

# Example for minikube
if command -v minikube &> /dev/null; then
    echo "Starting minikube tunnel..."
    echo "⚠️  This requires sudo access"
    minikube tunnel
elif command -v kubectl &> /dev/null; then
    echo "⚠️  Tunnel setup depends on your cluster type"
    echo ""
    echo "For minikube: minikube tunnel"
    echo "For kind: kubectl port-forward (no tunnel needed)"
    echo "For cloud providers: use load balancers"
else
    echo "❌ kubectl not found"
    exit 1
fi
