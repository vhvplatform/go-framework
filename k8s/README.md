# Kubernetes Deployment Manifests

This directory contains Kubernetes manifests for deploying the Go Framework platform.

## Directory Structure

```
k8s/
├── base/               # Base Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── mongodb.yaml
│   ├── redis.yaml
│   ├── rabbitmq.yaml
│   ├── auth-service.yaml
│   ├── user-service.yaml
│   ├── tenant-service.yaml
│   ├── notification-service.yaml
│   ├── system-config-service.yaml
│   ├── api-gateway.yaml
│   └── ingress.yaml (optional)
├── overlays/
│   ├── dev/          # Development environment overrides
│   └── prod/         # Production environment overrides
└── README.md         # This file
```

## Quick Start

For detailed deployment instructions, please see: [Kubernetes Deployment Guide](../docs/KUBERNETES_DEPLOYMENT.md)

### Basic Deployment

```bash
# 1. Create namespace
kubectl apply -f base/namespace.yaml

# 2. Create configuration
kubectl apply -f base/configmap.yaml
kubectl apply -f base/secrets.yaml

# 3. Deploy infrastructure
kubectl apply -f base/mongodb.yaml
kubectl apply -f base/redis.yaml
kubectl apply -f base/rabbitmq.yaml

# 4. Deploy microservices
kubectl apply -f base/auth-service.yaml
kubectl apply -f base/user-service.yaml
kubectl apply -f base/tenant-service.yaml
kubectl apply -f base/notification-service.yaml
kubectl apply -f base/system-config-service.yaml
kubectl apply -f base/api-gateway.yaml

# Or deploy everything at once
kubectl apply -f base/
```

## Prerequisites

Before deploying, ensure you have:

1. **kubectl** configured and connected to your cluster
2. **Docker images** built and pushed to your registry
3. **Storage class** configured (for PersistentVolumes)
4. **Appropriate permissions** to create resources

See the [Prerequisites section](../docs/KUBERNETES_DEPLOYMENT.md#yêu-cầu-trước-khi-cài-đặt-prerequisites) in the full guide.

## Customization

### Using Your Own Docker Registry

Update the `image:` field in each service YAML file:

```yaml
spec:
  containers:
  - name: auth-service
    image: <your-registry>/go-auth-service:latest  # Update this
```

### Configuring Environment Variables

Edit `base/configmap.yaml` and `base/secrets.yaml` to customize your deployment.

### Resource Limits

Adjust CPU and memory limits in each service manifest:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Example Manifests

The manifests in this directory are templates. You need to:

1. **Replace placeholders** like `<your-registry>` with your actual Docker registry
2. **Update secrets** in `secrets.yaml` with your actual passwords
3. **Adjust resources** based on your cluster capacity

For complete, ready-to-use manifests with detailed explanations, see the [Kubernetes Deployment Guide](../docs/KUBERNETES_DEPLOYMENT.md).

## Verification

After deployment, verify everything is working:

```bash
# Check pods
kubectl get pods -n go-platform

# Check services
kubectl get services -n go-platform

# View logs
kubectl logs -l app=api-gateway -n go-platform

# Port-forward to test
kubectl port-forward -n go-platform svc/api-gateway 8080:8080
curl http://localhost:8080/health
```

## Troubleshooting

If you encounter issues, see the [Troubleshooting section](../docs/KUBERNETES_DEPLOYMENT.md#gỡ-lỗi-cơ-bản-basic-troubleshooting) in the deployment guide.

Common issues:
- Pods not starting: Check logs with `kubectl logs <pod-name> -n go-platform`
- ImagePullBackOff: Verify image name and registry credentials
- Service not accessible: Check endpoints with `kubectl get endpoints -n go-platform`

## Additional Resources

- [Full Kubernetes Deployment Guide](../docs/KUBERNETES_DEPLOYMENT.md)
- [Docker Compose Setup](../docker/README.md)
- [Local Development Guide](../docs/LOCAL_DEVELOPMENT.md)
- [Official Kubernetes Documentation](https://kubernetes.io/docs/)

## Support

For help with deployment:
1. Check the [Kubernetes Deployment Guide](../docs/KUBERNETES_DEPLOYMENT.md)
2. Review [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
3. Open an issue on [GitHub](https://github.com/vhvplatform/go-framework/issues)
