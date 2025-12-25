#!/bin/bash
set -e

echo "☸️  Deploying to local Kubernetes..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

# Check if a cluster is available
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ No Kubernetes cluster available"
    echo "   Start minikube with: minikube start"
    exit 1
fi

# Check if Helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed"
    exit 1
fi

HELM_DIR="${HELM_DIR:-$HOME/workspace/go-platform/go-infrastructure/helm}"

if [ ! -d "${HELM_DIR}/go-framework" ]; then
    echo "❌ Helm charts not found at ${HELM_DIR}"
    exit 1
fi

echo "📦 Installing with Helm..."
helm upgrade --install go-framework "${HELM_DIR}/go-framework" \
    -f "${HELM_DIR}/go-framework/values-dev.yaml" \
    --create-namespace \
    --namespace go-dev

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Check status:"
echo "  kubectl get pods -n go-dev"
echo "  kubectl get services -n go-dev"
echo ""
echo "Setup port forwarding: make port-forward"
