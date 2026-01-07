#!/bin/bash
#
# Script: deploy-local.sh
# Description: Deploy to local Kubernetes cluster
# Usage: ./deploy-local.sh
#
# This script:
#   - Deploys all microservices to local K8s cluster
#   - Installs MongoDB, Redis, RabbitMQ
#   - Sets up observability stack (Prometheus, Grafana, Jaeger)
#   - Configures networking and ingress
#
# Prerequisites:
#   - Local Kubernetes cluster running (minikube, kind, or Docker Desktop K8s)
#   - kubectl configured and accessible
#   - Helm installed (for chart deployments)
#   - Docker images built (make docker-build)
#
# Environment Variables:
#   KUBE_CONTEXT - Kubernetes context (default: current context)
#   NAMESPACE - Target namespace (default: default)
#
# Examples:
#   ./deploy-local.sh
#   make deploy-local
#   NAMESPACE=dev ./deploy-local.sh
#
# Deployment Includes:
#   - All 6 microservices
#   - MongoDB with persistence
#   - Redis
#   - RabbitMQ with management UI
#   - Prometheus for metrics
#   - Grafana for visualization
#   - Jaeger for tracing
#
# Deployment Time:
#   - Typical: 3-5 minutes
#   - First time: 5-10 minutes (downloading images)
#
# Verification:
#   kubectl get pods
#   kubectl get services
#   make port-forward  # Access services
#
# Accessing Services:
#   make port-forward  # Then access via localhost
#
# Troubleshooting:
#   - Check pod status: kubectl get pods
#   - View logs: kubectl logs <pod-name>
#   - Describe pod: kubectl describe pod <pod-name>
#   - Check events: kubectl get events
#
# Cleanup:
#   kubectl delete namespace <namespace>
#   # Or redeploy: ./deploy-local.sh
#
# See Also:
#   - port-forward.sh: Access deployed services
#   - deploy-dev.sh: Deploy to dev environment
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

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
