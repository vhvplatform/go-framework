# Kubernetes Deployment Manifests

This directory contains Kubernetes manifest **templates** and examples for deploying the Go Framework platform.

## ⚠️ Important Note

This directory provides:
- ✅ **Included**: Sample manifests (namespace, configmap, secrets, api-gateway)
- 📝 **To Create**: Additional service manifests following the provided examples

You'll need to create the missing manifest files for infrastructure and microservices by following the examples in the [Kubernetes Deployment Guide](../docs/KUBERNETES_DEPLOYMENT.md).

## Directory Structure (Target)

```
k8s/
├── base/                        # Base Kubernetes manifests
│   ├── namespace.yaml          ✅ Provided
│   ├── configmap.yaml          ✅ Provided
│   ├── secrets.yaml            ✅ Provided (template)
│   ├── api-gateway.yaml        ✅ Provided (example)
│   ├── mongodb.yaml            📝 To create (see guide)
│   ├── redis.yaml              📝 To create (see guide)
│   ├── rabbitmq.yaml           📝 To create (see guide)
│   ├── auth-service.yaml       📝 To create (following api-gateway example)
│   ├── user-service.yaml       📝 To create (following api-gateway example)
│   ├── tenant-service.yaml     📝 To create (following api-gateway example)
│   ├── notification-service.yaml  📝 To create (following api-gateway example)
│   ├── system-config-service.yaml 📝 To create (following api-gateway example)
│   └── ingress.yaml            📝 Optional (see guide)
├── overlays/
│   ├── dev/                    # Development environment overrides
│   └── prod/                   # Production environment overrides
└── README.md                   # This file
```

## Quick Start

**Before deploying**, create the missing manifest files by following the detailed examples in the [Kubernetes Deployment Guide](../docs/KUBERNETES_DEPLOYMENT.md).

### What's Provided

This directory includes:
1. **namespace.yaml** - Namespace definition (ready to use)
2. **configmap.yaml** - Configuration template (customize for your environment)
3. **secrets.yaml** - Secrets template (⚠️ replace with your actual secrets)
4. **api-gateway.yaml** - Complete deployment example (use as template for other services)

### What You Need to Create

Using the guide and the api-gateway.yaml example, create manifests for:
- Infrastructure: mongodb.yaml, redis.yaml, rabbitmq.yaml
- Microservices: auth-service.yaml, user-service.yaml, tenant-service.yaml, notification-service.yaml, system-config-service.yaml
- Optional: ingress.yaml (if using Ingress)

### Basic Deployment (After Creating All Files)

```bash
# 1. Create namespace
kubectl apply -f base/namespace.yaml

# 2. Create configuration
kubectl apply -f base/configmap.yaml
kubectl apply -f base/secrets.yaml

# 3. Deploy infrastructure (create these files first using the guide)
kubectl apply -f base/mongodb.yaml
kubectl apply -f base/redis.yaml
kubectl apply -f base/rabbitmq.yaml

# 4. Deploy microservices (create these files first following api-gateway.yaml example)
kubectl apply -f base/auth-service.yaml
kubectl apply -f base/user-service.yaml
kubectl apply -f base/tenant-service.yaml
kubectl apply -f base/notification-service.yaml
kubectl apply -f base/system-config-service.yaml
kubectl apply -f base/api-gateway.yaml

# Or deploy everything at once (after creating all files)
kubectl apply -f base/
```
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
