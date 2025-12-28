# Hướng Dẫn Triển Khai Kubernetes (Kubernetes Deployment Guide)

Tài liệu này cung cấp hướng dẫn chi tiết để triển khai dự án Go Framework lên một cụm Kubernetes (K8s) có sẵn.

*This document provides detailed instructions for deploying the Go Framework project to an existing Kubernetes (K8s) cluster.*

---

## Mục Lục (Table of Contents)

- [Yêu Cầu Trước Khi Cài Đặt](#yêu-cầu-trước-khi-cài-đặt-prerequisites)
- [Chuẩn Bị Triển Khai](#chuẩn-bị-triển-khai-pre-deployment-preparation)
- [Các Bước Triển Khai](#các-bước-triển-khai-deployment-steps)
- [Kiểm Tra Trạng Thái Triển Khai](#kiểm-tra-trạng-thái-triển-khai-deployment-verification)
- [Truy Cập Dịch Vụ](#truy-cập-dịch-vụ-accessing-services)
- [Gỡ Lỗi Cơ Bản](#gỡ-lỗi-cơ-bản-basic-troubleshooting)
- [Nâng Cấp và Rollback](#nâng-cấp-và-rollback-upgrades-and-rollbacks)
- [Xóa Triển Khai](#xóa-triển-khai-cleanup)

---

## Yêu Cầu Trước Khi Cài Đặt (Prerequisites)

### 1. Cụm Kubernetes Hoạt Động (Working Kubernetes Cluster)

Bạn cần có quyền truy cập vào một cụm Kubernetes đang hoạt động. Cụm này có thể là:

- **Kubernetes trên cloud**: GKE (Google), EKS (AWS), AKS (Azure)
- **Kubernetes tại chỗ (on-premise)**: OpenShift, Rancher, Vanilla K8s
- **Kubernetes cục bộ (local)**: Minikube, Kind, Docker Desktop K8s
- **Kubernetes quản lý khác**: K3s, MicroK8s, etc.

**Kiểm tra kết nối cụm:**

```bash
# Kiểm tra kubectl có thể kết nối với cụm
kubectl cluster-info

# Xem thông tin về cụm
kubectl get nodes

# Kiểm tra phiên bản Kubernetes
kubectl version --short
```

**Yêu cầu tối thiểu:**
- Kubernetes version: 1.20+ (khuyến nghị 1.24+)
- Ít nhất 3 worker nodes (cho môi trường production)
- Ít nhất 8GB RAM và 4 CPU cores tổng cộng
- Storage class khả dụng cho persistent volumes

### 2. Công Cụ kubectl (kubectl CLI Tool)

kubectl là công cụ dòng lệnh để tương tác với Kubernetes.

**Cài đặt kubectl:**

```bash
# macOS (sử dụng Homebrew)
brew install kubectl

# Linux (sử dụng curl)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Windows (sử dụng Chocolatey)
choco install kubernetes-cli

# Hoặc tải từ: https://kubernetes.io/docs/tasks/tools/
```

**Xác minh cài đặt:**

```bash
kubectl version --client
```

### 3. Cấu Hình kubectl (kubectl Configuration)

kubectl cần được cấu hình để truy cập vào cụm của bạn.

**File cấu hình kubeconfig:**

kubectl sử dụng file `~/.kube/config` (hoặc biến môi trường `KUBECONFIG`) để lưu thông tin cụm.

```bash
# Xem cấu hình hiện tại
kubectl config view

# Xem các context khả dụng
kubectl config get-contexts

# Chuyển sang một context cụ thể
kubectl config use-context <context-name>

# Kiểm tra context hiện tại
kubectl config current-context
```

**Lấy kubeconfig từ nhà cung cấp cloud:**

```bash
# Google GKE
gcloud container clusters get-credentials <cluster-name> --zone <zone>

# Amazon EKS
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Azure AKS
az aks get-credentials --resource-group <rg-name> --name <cluster-name>
```

### 4. Quyền Truy Cập (Access Permissions)

Tài khoản của bạn cần có các quyền sau trong Kubernetes:

- **Tạo và quản lý Namespaces**
- **Tạo và quản lý Deployments, Services, ConfigMaps, Secrets**
- **Xem logs và mô tả resources**
- **Port-forward tới pods**

**Kiểm tra quyền:**

```bash
# Kiểm tra quyền của bạn
kubectl auth can-i create deployments
kubectl auth can-i create namespaces
kubectl auth can-i create services
kubectl auth can-i get pods --all-namespaces

# Xem tất cả quyền của bạn (nếu có RBAC)
kubectl auth can-i --list
```

Nếu bạn không có đủ quyền, liên hệ với quản trị viên cụm K8s.

### 5. Docker Registry (Container Registry)

Bạn cần có quyền truy cập vào một Docker registry chứa các image của dự án:

- **Public registries**: Docker Hub, GitHub Container Registry
- **Private registries**: Harbor, Nexus, JFrog Artifactory
- **Cloud registries**: GCR, ECR, ACR

**Build và push images (nếu cần):**

```bash
# Build tất cả images
make docker-build

# Tag images với registry của bạn
docker tag go-api-gateway:latest <your-registry>/go-api-gateway:latest
docker tag go-auth-service:latest <your-registry>/go-auth-service:latest
# ... (cho tất cả services)

# Push lên registry
docker push <your-registry>/go-api-gateway:latest
docker push <your-registry>/go-auth-service:latest
# ... (cho tất cả services)

# Hoặc sử dụng script tự động
make docker-push REGISTRY=<your-registry>
```

**Cấu hình image pull secrets (nếu sử dụng private registry):**

```bash
kubectl create secret docker-registry regcred \
  --docker-server=<your-registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n go-platform
```

### 6. Công Cụ Bổ Sung (Optional Tools)

Các công cụ này không bắt buộc nhưng rất hữu ích:

```bash
# Helm - Package manager cho Kubernetes
brew install helm  # macOS
# Hoặc: https://helm.sh/docs/intro/install/

# k9s - Terminal UI để quản lý Kubernetes
brew install k9s  # macOS
# Hoặc: https://k9scli.io/topics/install/

# kubectx/kubens - Chuyển đổi context và namespace nhanh
brew install kubectx  # macOS

# stern - Multi-pod log tailing
brew install stern  # macOS
```

---

## Chuẩn Bị Triển Khai (Pre-Deployment Preparation)

### 1. Clone Repository

```bash
# Clone repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework
```

### 2. Tạo Kubernetes Manifests

Tạo thư mục cho các file YAML Kubernetes:

```bash
mkdir -p k8s/{base,overlays/dev,overlays/prod}
```

### 3. Xem Lại Cấu Hình

Kiểm tra và điều chỉnh các file cấu hình trong `docker/` để hiểu các biến môi trường cần thiết:

```bash
cat docker/.env.example
cat docker/docker-compose.yml
```

### 4. Chuẩn Bị Storage (nếu cần Persistent Volumes)

Xác định storage class khả dụng trong cụm:

```bash
kubectl get storageclass

# Xem storage class mặc định
kubectl get storageclass | grep default
```

---

## Các Bước Triển Khai (Deployment Steps)

### Bước 1: Tạo Namespace

Namespace giúp tách biệt các resources và quản lý dễ dàng hơn.

**Tạo file `k8s/base/namespace.yaml`:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-platform
  labels:
    name: go-platform
    environment: production
```

**Áp dụng:**

```bash
kubectl apply -f k8s/base/namespace.yaml

# Xác nhận namespace đã được tạo
kubectl get namespace go-platform
```

**Đặt namespace mặc định cho các lệnh tiếp theo:**

```bash
kubectl config set-context --current --namespace=go-platform

# Hoặc sử dụng kubens (nếu đã cài)
kubens go-platform
```

### Bước 2: Tạo ConfigMap

ConfigMap lưu trữ cấu hình không nhạy cảm.

**Tạo file `k8s/base/configmap.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: go-platform-config
  namespace: go-platform
data:
  ENVIRONMENT: "production"
  LOG_LEVEL: "info"
  MONGODB_URI: "mongodb://mongodb-service:27017"
  MONGODB_DATABASE: "go_prod"
  REDIS_URL: "redis://redis-service:6379/0"
  RABBITMQ_URL: "amqp://guest:guest@rabbitmq-service:5672/"
```

**Áp dụng:**

```bash
kubectl apply -f k8s/base/configmap.yaml

# Xem ConfigMap đã tạo
kubectl get configmap go-platform-config -n go-platform
kubectl describe configmap go-platform-config -n go-platform
```

### Bước 3: Tạo Secrets

Secrets lưu trữ thông tin nhạy cảm như passwords, tokens.

**Tạo file `k8s/base/secrets.yaml`:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: go-platform-secrets
  namespace: go-platform
type: Opaque
stringData:
  JWT_SECRET: "your-super-secret-jwt-key-change-this"
  MONGODB_USERNAME: "admin"
  MONGODB_PASSWORD: "secure-password-here"
  REDIS_PASSWORD: "redis-password-here"
  SMTP_PASSWORD: "smtp-password-here"
```

**Lưu ý:** Trong môi trường production, sử dụng tools như Sealed Secrets, External Secrets Operator, hoặc vault.

**Áp dụng:**

```bash
kubectl apply -f k8s/base/secrets.yaml

# Xem Secret (không hiển thị giá trị)
kubectl get secret go-platform-secrets -n go-platform
```

### Bước 4: Triển Khai Infrastructure Services

Triển khai các dịch vụ hạ tầng cần thiết (MongoDB, Redis, RabbitMQ).

**Lưu ý:** Xem các file example YAML đầy đủ trong thư mục `k8s/base/`. Dưới đây là các bước triển khai:

```bash
# Triển khai MongoDB với Persistent Volume
kubectl apply -f k8s/base/mongodb.yaml

# Triển khai Redis
kubectl apply -f k8s/base/redis.yaml

# Triển khai RabbitMQ
kubectl apply -f k8s/base/rabbitmq.yaml

# Kiểm tra trạng thái
kubectl get pods -n go-platform
kubectl get services -n go-platform
```

### Bước 5: Triển Khai Microservices

Triển khai tất cả microservices của ứng dụng.

```bash
# Triển khai từng service
kubectl apply -f k8s/base/auth-service.yaml
kubectl apply -f k8s/base/user-service.yaml
kubectl apply -f k8s/base/tenant-service.yaml
kubectl apply -f k8s/base/notification-service.yaml
kubectl apply -f k8s/base/system-config-service.yaml
kubectl apply -f k8s/base/api-gateway.yaml

# Hoặc áp dụng tất cả cùng lúc
kubectl apply -f k8s/base/

# Kiểm tra deployment
kubectl get deployments -n go-platform
kubectl get pods -n go-platform
```

### Bước 6: Tạo Ingress (Tùy Chọn)

Nếu cụm có Ingress Controller, tạo Ingress resource để expose services ra ngoài.

```bash
kubectl apply -f k8s/base/ingress.yaml
```

---

## Kiểm Tra Trạng Thái Triển Khai (Deployment Verification)

### 1. Kiểm Tra Pods

```bash
# Xem tất cả pods trong namespace
kubectl get pods -n go-platform

# Xem pods với thông tin chi tiết hơn
kubectl get pods -n go-platform -o wide

# Theo dõi trạng thái pods real-time
kubectl get pods -n go-platform --watch

# Kiểm tra pods bằng k9s (nếu đã cài)
k9s -n go-platform
```

**Trạng thái mong đợi:** Tất cả pods nên ở trạng thái `Running` và `READY` là `1/1` hoặc `2/2`.

### 2. Kiểm Tra Services

```bash
# Liệt kê tất cả services
kubectl get services -n go-platform

# Xem chi tiết một service cụ thể
kubectl describe service api-gateway -n go-platform
```

### 3. Xem Logs

```bash
# Xem logs của một pod cụ thể
kubectl logs <pod-name> -n go-platform

# Xem logs và theo dõi real-time
kubectl logs -f <pod-name> -n go-platform

# Xem logs của tất cả pods với label cụ thể
kubectl logs -l app=auth-service -n go-platform

# Sử dụng stern để xem logs từ nhiều pods (nếu đã cài)
stern auth-service -n go-platform
```

### 4. Kiểm Tra Events

```bash
# Xem tất cả events trong namespace
kubectl get events -n go-platform --sort-by='.lastTimestamp'

# Lọc events theo loại
kubectl get events -n go-platform --field-selector type=Warning
```

### 5. Health Checks

```bash
# Port-forward để test từ máy local
kubectl port-forward -n go-platform svc/api-gateway 8080:8080

# Sau đó test trên máy local
curl http://localhost:8080/health
```

### 6. Kiểm Tra Resource Usage

```bash
# Xem CPU và memory usage của pods
kubectl top pods -n go-platform

# Xem usage của nodes
kubectl top nodes
```

---

## Truy Cập Dịch Vụ (Accessing Services)

### Phương Pháp 1: Port Forwarding (Development/Testing)

```bash
# Port-forward API Gateway
kubectl port-forward -n go-platform svc/api-gateway 8080:8080

# Trong terminal khác, test API
curl http://localhost:8080/health

# Port-forward nhiều services (trong các terminal riêng biệt)
kubectl port-forward -n go-platform svc/api-gateway 8080:8080 &
kubectl port-forward -n go-platform svc/rabbitmq-service 15672:15672 &
```

### Phương Pháp 2: NodePort Service

Nếu service type là `NodePort`:

```bash
# Lấy NodePort
kubectl get svc api-gateway -n go-platform

# Lấy node IP
kubectl get nodes -o wide

# Truy cập qua: http://<node-ip>:<node-port>
```

### Phương Pháp 3: LoadBalancer (Cloud Clusters)

Nếu service type là `LoadBalancer`:

```bash
# Lấy External IP
kubectl get svc api-gateway -n go-platform

# Truy cập qua: http://<external-ip>:8080
```

### Phương Pháp 4: Ingress (Production)

Nếu đã cấu hình Ingress:

```bash
# Lấy Ingress address
kubectl get ingress -n go-platform

# Truy cập qua domain đã cấu hình: https://api.yourdomain.com
```

---

## Gỡ Lỗi Cơ Bản (Basic Troubleshooting)

### Vấn Đề 1: Pod Không Khởi Động

**Triệu chứng:** Pod ở trạng thái `Pending`, `CrashLoopBackOff`, hoặc `Error`

**Các bước gỡ lỗi:**

```bash
# 1. Kiểm tra trạng thái pod
kubectl get pod <pod-name> -n go-platform

# 2. Xem mô tả chi tiết (chú ý phần Events)
kubectl describe pod <pod-name> -n go-platform

# 3. Xem logs
kubectl logs <pod-name> -n go-platform

# 4. Xem logs của lần chạy trước (nếu pod đang restart)
kubectl logs <pod-name> -n go-platform --previous
```

**Nguyên nhân thường gặp:**

- **ImagePullBackOff**: Image không tồn tại hoặc không có quyền pull
- **CrashLoopBackOff**: Container khởi động rồi crash - xem logs để tìm lỗi
- **Pending**: Không đủ resources hoặc scheduling constraints

### Vấn Đề 2: Service Không Accessible

**Các bước gỡ lỗi:**

```bash
# 1. Kiểm tra service có tồn tại không
kubectl get svc -n go-platform

# 2. Kiểm tra endpoints của service
kubectl get endpoints <service-name> -n go-platform

# 3. Kiểm tra selector có match với pod labels không
kubectl describe svc <service-name> -n go-platform
kubectl get pods -n go-platform --show-labels
```

### Vấn Đề 3: Environment Variables Không Load

```bash
# Exec vào pod và kiểm tra env vars
kubectl exec -it <pod-name> -n go-platform -- env | grep MONGODB

# Kiểm tra ConfigMap và Secret có tồn tại không
kubectl get configmap go-platform-config -n go-platform
kubectl get secret go-platform-secrets -n go-platform
```

### Script Debug Tổng Hợp

```bash
# Script nhanh để kiểm tra tất cả
kubectl get all -n go-platform
kubectl get events -n go-platform --sort-by='.lastTimestamp' | tail -20
kubectl top pods -n go-platform
kubectl get pvc -n go-platform
```

---

## Nâng Cấp và Rollback (Upgrades and Rollbacks)

### Nâng Cấp Deployment

```bash
# Update image
kubectl set image deployment/auth-service \
  auth-service=<your-registry>/go-auth-service:v2.0 \
  -n go-platform

# Theo dõi quá trình rollout
kubectl rollout status deployment/auth-service -n go-platform

# Xem lịch sử rollout
kubectl rollout history deployment/auth-service -n go-platform
```

### Rollback

```bash
# Rollback về phiên bản trước
kubectl rollout undo deployment/auth-service -n go-platform

# Rollback về phiên bản cụ thể
kubectl rollout undo deployment/auth-service --to-revision=2 -n go-platform
```

### Scaling

```bash
# Scale up
kubectl scale deployment/auth-service --replicas=5 -n go-platform

# Scale down
kubectl scale deployment/auth-service --replicas=2 -n go-platform

# Auto-scaling (HPA)
kubectl autoscale deployment/auth-service \
  --min=2 --max=10 \
  --cpu-percent=70 \
  -n go-platform
```

---

## Xóa Triển Khai (Cleanup)

### Xóa Từng Phần

```bash
# Xóa một deployment cụ thể
kubectl delete deployment auth-service -n go-platform

# Xóa tất cả resources trong một file
kubectl delete -f k8s/base/auth-service.yaml
```

### Xóa Toàn Bộ Namespace

```bash
# Cảnh báo: Lệnh này sẽ xóa TẤT CẢ resources trong namespace
kubectl delete namespace go-platform
```

---

## Best Practices

### 1. Security

- **Không lưu secrets trong Git**: Sử dụng Sealed Secrets hoặc External Secrets
- **Sử dụng RBAC**: Giới hạn quyền truy cập
- **Network Policies**: Giới hạn traffic giữa pods
- **Regular updates**: Cập nhật images thường xuyên

### 2. Resource Management

- **Set resource requests và limits** cho tất cả containers
- **Use namespaces** để tách biệt environments
- **Configure resource quotas** cho namespaces

### 3. High Availability

- **Multiple replicas**: Ít nhất 2-3 replicas cho mỗi service
- **Pod Disruption Budgets**: Đảm bảo availability trong maintenance

### 4. Monitoring

- **Configure liveness và readiness probes**
- **Export metrics** cho Prometheus
- **Centralized logging** (ELK, Loki)

---

## Tài Liệu Tham Khảo (References)

### Official Kubernetes Documentation

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

### Related Project Documentation

- [Docker Compose Setup](../docker/README.md)
- [Local Development Guide](./LOCAL_DEVELOPMENT.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
- [Architecture Documentation](./ARCHITECTURE.md)

### Tools

- [Helm Documentation](https://helm.sh/docs/)
- [k9s - Kubernetes CLI UI](https://k9scli.io/)
- [kubectx/kubens](https://github.com/ahmetb/kubectx)

---

## Hỗ Trợ (Support)

Nếu gặp vấn đề trong quá trình triển khai:

1. **Kiểm tra logs**: `kubectl logs <pod-name> -n go-platform`
2. **Xem events**: `kubectl get events -n go-platform`
3. **Đọc Troubleshooting Guide**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
4. **Mở issue**: [GitHub Issues](https://github.com/vhvplatform/go-framework/issues)

---

## Changelog

- **2024-12-28**: Tạo tài liệu hướng dẫn triển khai Kubernetes chi tiết

---

*Tài liệu được duy trì bởi VHV Platform Team*
