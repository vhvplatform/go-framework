# Comprehensive Examples

Real-world examples and scenarios for using the go-framework and SaaS platform.

## Table of Contents

- [Complete Setup Example](#complete-setup-example)
- [Development Workflow Examples](#development-workflow-examples)
- [Testing Scenarios](#testing-scenarios)
- [Deployment Examples](#deployment-examples)
- [Troubleshooting Examples](#troubleshooting-examples)
- [Integration Examples](#integration-examples)

---

## Complete Setup Example

### Scenario: New Developer Onboarding

**Context:** Sarah joins the team and needs to set up her development environment.

**Step-by-Step Process:**

```bash
# Day 1: Initial Setup (30 minutes)

# 1. Clone repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework

# 2. Run automated setup
make setup
# Output:
# 📦 Installing dependencies...
# Detected OS: Mac
# ✅ Homebrew already installed
# Installing development tools...
# ...
# 📂 Cloning repositories...
# ...
# ✅ Setup complete!

# 3. Configure environment
cd docker
cp .env.example .env
nano .env  # Update JWT_SECRET

# 4. Start services
cd ..
make start
# Output:
# 🚀 Starting all services...
# Creating network "go-network"
# Creating go-mongodb ... done
# Creating go-redis ... done
# Creating go-rabbitmq ... done
# ...
# ⏳ Waiting for services to be healthy...
# ✅ All services started!

# 5. Verify setup
make status
# Output:
# ✅ Docker is running
# ✅ API Gateway is healthy
# ✅ Auth Service is healthy
# ✅ User Service is healthy
# ✅ Tenant Service is healthy
# ✅ Notification Service is healthy
# ✅ System Config Service is healthy
# ✅ MongoDB is healthy
# ✅ Redis is healthy
# ✅ RabbitMQ is healthy

# 6. Load test data
make db-seed
# Output:
# 🌱 Seeding database with test data...
# Loading users...
# Loading tenants...
# ✅ Database seeded successfully!

# 7. Test API
curl http://localhost:8080/health
# Response: {"status":"healthy"}

# 8. Open monitoring dashboards
make open-grafana  # Opens http://localhost:3000
make open-jaeger   # Opens http://localhost:16686

# Sarah is now ready to develop!
```

---

## Development Workflow Examples

### Example 1: Implementing a New Feature

**Feature:** Add user profile avatar upload

**Complete Workflow:**

```bash
# Step 1: Create feature branch
cd ~/workspace/go-platform/go-user-service
git checkout -b feature/avatar-upload

# Step 2: Start development mode (hot reload)
cd ~/workspace/go-platform/go-framework
make start-dev

# Step 3: Make code changes
cd ~/workspace/go-platform/go-user-service
```

```go
// internal/handlers/user_handler.go
func (h *UserHandler) UploadAvatar(ctx context.Context, req *UploadAvatarRequest) (*UploadAvatarResponse, error) {
    // Validate file size
    if req.FileSize > 5*1024*1024 {  // 5MB limit
        return nil, errors.New("file too large")
    }
    
    // Validate file type
    if !isValidImageType(req.ContentType) {
        return nil, errors.New("invalid file type")
    }
    
    // Generate unique filename
    filename := fmt.Sprintf("%s-%s.jpg", req.UserID, uuid.New())
    
    // Save file (implement storage logic)
    avatarURL, err := h.storage.SaveAvatar(ctx, filename, req.FileData)
    if err != nil {
        return nil, err
    }
    
    // Update user record
    err = h.repo.UpdateAvatar(ctx, req.UserID, avatarURL)
    if err != nil {
        return nil, err
    }
    
    return &UploadAvatarResponse{
        AvatarURL: avatarURL,
    }, nil
}
```

```bash
# Step 4: Code is automatically reloaded (air detects changes)
# Check logs:
make logs-service SERVICE=user-service
# Output:
# Building...
# Build finished
# Restarting...
# Server started on :8082

# Step 5: Test the feature
# Create test script
cat > test-avatar-upload.sh << 'EOF'
#!/bin/bash
# Get JWT token
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  | jq -r '.token')

# Upload avatar
curl -X POST http://localhost:8080/api/users/avatar \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@test-avatar.jpg" \
  | jq '.'
EOF

chmod +x test-avatar-upload.sh
./test-avatar-upload.sh

# Output:
# {
#   "avatar_url": "https://storage.example.com/avatars/user-123-uuid.jpg"
# }

# Step 6: Write unit tests
```

```go
// internal/handlers/user_handler_test.go
func TestUserHandler_UploadAvatar(t *testing.T) {
    // Test valid upload
    t.Run("valid_upload", func(t *testing.T) {
        handler := setupTestHandler()
        
        req := &UploadAvatarRequest{
            UserID:      "user-123",
            FileData:    testImageData,
            FileSize:    1024 * 500,  // 500KB
            ContentType: "image/jpeg",
        }
        
        resp, err := handler.UploadAvatar(context.Background(), req)
        
        assert.NoError(t, err)
        assert.NotEmpty(t, resp.AvatarURL)
    })
    
    // Test file too large
    t.Run("file_too_large", func(t *testing.T) {
        handler := setupTestHandler()
        
        req := &UploadAvatarRequest{
            UserID:   "user-123",
            FileData: largFileData,
            FileSize: 10 * 1024 * 1024,  // 10MB
        }
        
        _, err := handler.UploadAvatar(context.Background(), req)
        
        assert.Error(t, err)
        assert.Contains(t, err.Error(), "too large")
    })
}
```

```bash
# Run tests
cd ~/workspace/go-platform/go-user-service
go test ./internal/handlers -v

# Step 7: Run all tests from framework
cd ~/workspace/go-platform/go-framework
make test-unit

# Step 8: Commit changes
cd ~/workspace/go-platform/go-user-service
git add .
git commit -m "feat(users): add avatar upload functionality

- Add avatar upload handler with validation
- Implement file size and type checks
- Add unit tests for avatar upload
- Update user model with avatar field

Closes #456"

git push origin feature/avatar-upload

# Step 9: Create pull request on GitHub
# Step 10: After review, merge and deploy
```

### Example 2: Debugging a Production Issue

**Issue:** Users reporting slow login times

**Investigation Process:**

```bash
# Step 1: Check monitoring dashboards
make open-grafana

# Observations:
# - Auth service response time p99: 2.5s (normally 100ms)
# - Database query time increased
# - No errors in logs

# Step 2: Check distributed traces
make open-jaeger

# Find slow login trace:
# Trace ID: abc123xyz
# Total duration: 2800ms
# 
# Breakdown:
# - API Gateway: 50ms
# - Auth Service processing: 100ms
# - MongoDB query: 2600ms  <-- PROBLEM!
# - Token generation: 50ms

# Step 3: Investigate database
docker exec -it mongodb mongosh

# In MongoDB shell:
use go_dev

# Check current operations
db.currentOp({
  "active": true,
  "secs_running": { "$gt": 1 }
})

# Output shows slow query:
# {
#   "op": "query",
#   "ns": "go_dev.users",
#   "command": {
#     "find": "users",
#     "filter": { "email": "user@example.com" }
#   },
#   "planSummary": "COLLSCAN",  <-- Full collection scan!
#   "secs_running": 2.5
# }

# Check indexes
db.users.getIndexes()
# Output: [ { "_id": 1 } ]  <-- Missing email index!

# Step 4: Fix the issue
# Create missing index
db.users.createIndex({ "email": 1 }, { unique: true })

# Output:
# {
#   "createdCollectionAutomatically": false,
#   "numIndexesBefore": 1,
#   "numIndexesAfter": 2,
#   "ok": 1
# }

# Step 5: Test the fix
exit  # Exit MongoDB shell

# Test login performance
time curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'

# Before: 2.5s
# After: 0.08s  <-- 30x faster!

# Step 6: Verify in monitoring
make open-grafana
# Check Auth Service response time:
# p99: 95ms  <-- Back to normal!

# Step 7: Add index to migration script
cd ~/workspace/go-platform/go-user-service
```

```javascript
// migrations/004_add_email_index.js
db.users.createIndex(
    { "email": 1 },
    { 
        unique: true,
        name: "email_unique_idx"
    }
);

print("Email index created successfully");
```

```bash
# Commit the fix
git add migrations/004_add_email_index.js
git commit -m "fix(database): add email index to improve login performance

The email field was missing an index, causing full collection scans
on every login attempt. This resulted in 2+ second login times.

Adding a unique index on email improves query performance from
2.5s to <100ms.

Performance improvement: 25-30x faster
Fixes #789"

# Step 8: Update documentation
cd ~/workspace/go-platform/go-framework
```

---

## Testing Scenarios

### Scenario 1: Testing Authentication Flow

**Complete Test Suite:**

```go
// tests/integration/auth_test.go
package integration_test

import (
    "testing"
    "net/http"
    "encoding/json"
)

func TestAuthenticationFlow(t *testing.T) {
    baseURL := "http://localhost:8080"
    
    // Test 1: Register new user
    t.Run("Register", func(t *testing.T) {
        payload := map[string]string{
            "email":    "testuser@example.com",
            "password": "SecurePass123!",
            "name":     "Test User",
        }
        
        resp, body := makeRequest(t, "POST", baseURL+"/api/auth/register", payload)
        
        assert.Equal(t, http.StatusCreated, resp.StatusCode)
        assert.Contains(t, body, "user_id")
    })
    
    // Test 2: Login with valid credentials
    t.Run("LoginSuccess", func(t *testing.T) {
        payload := map[string]string{
            "email":    "testuser@example.com",
            "password": "SecurePass123!",
        }
        
        resp, body := makeRequest(t, "POST", baseURL+"/api/auth/login", payload)
        
        assert.Equal(t, http.StatusOK, resp.StatusCode)
        
        var result map[string]interface{}
        json.Unmarshal([]byte(body), &result)
        
        token := result["token"].(string)
        assert.NotEmpty(t, token)
        
        // Store token for subsequent tests
        authToken = token
    })
    
    // Test 3: Login with invalid credentials
    t.Run("LoginFailure", func(t *testing.T) {
        payload := map[string]string{
            "email":    "testuser@example.com",
            "password": "WrongPassword",
        }
        
        resp, _ := makeRequest(t, "POST", baseURL+"/api/auth/login", payload)
        
        assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)
    })
    
    // Test 4: Access protected endpoint
    t.Run("AccessWithToken", func(t *testing.T) {
        req, _ := http.NewRequest("GET", baseURL+"/api/users/profile", nil)
        req.Header.Set("Authorization", "Bearer "+authToken)
        
        client := &http.Client{}
        resp, err := client.Do(req)
        
        assert.NoError(t, err)
        assert.Equal(t, http.StatusOK, resp.StatusCode)
    })
    
    // Test 5: Access without token
    t.Run("AccessWithoutToken", func(t *testing.T) {
        resp, _ := http.Get(baseURL + "/api/users/profile")
        
        assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)
    })
    
    // Test 6: Logout
    t.Run("Logout", func(t *testing.T) {
        req, _ := http.NewRequest("POST", baseURL+"/api/auth/logout", nil)
        req.Header.Set("Authorization", "Bearer "+authToken)
        
        client := &http.Client{}
        resp, err := client.Do(req)
        
        assert.NoError(t, err)
        assert.Equal(t, http.StatusOK, resp.StatusCode)
    })
    
    // Test 7: Token is invalidated after logout
    t.Run("TokenInvalidAfterLogout", func(t *testing.T) {
        req, _ := http.NewRequest("GET", baseURL+"/api/users/profile", nil)
        req.Header.Set("Authorization", "Bearer "+authToken)
        
        client := &http.Client{}
        resp, err := client.Do(req)
        
        assert.NoError(t, err)
        assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)
    })
}
```

**Running the Tests:**

```bash
cd ~/workspace/go-platform/go-framework

# Ensure services are running
make start

# Run integration tests
make test-integration

# Output:
# 🧪 Running integration tests...
# === RUN   TestAuthenticationFlow
# === RUN   TestAuthenticationFlow/Register
# === RUN   TestAuthenticationFlow/LoginSuccess
# === RUN   TestAuthenticationFlow/LoginFailure
# === RUN   TestAuthenticationFlow/AccessWithToken
# === RUN   TestAuthenticationFlow/AccessWithoutToken
# === RUN   TestAuthenticationFlow/Logout
# === RUN   TestAuthenticationFlow/TokenInvalidAfterLogout
# --- PASS: TestAuthenticationFlow (2.45s)
#     --- PASS: TestAuthenticationFlow/Register (0.35s)
#     --- PASS: TestAuthenticationFlow/LoginSuccess (0.25s)
#     --- PASS: TestAuthenticationFlow/LoginFailure (0.20s)
#     --- PASS: TestAuthenticationFlow/AccessWithToken (0.15s)
#     --- PASS: TestAuthenticationFlow/AccessWithoutToken (0.10s)
#     --- PASS: TestAuthenticationFlow/Logout (0.20s)
#     --- PASS: TestAuthenticationFlow/TokenInvalidAfterLogout (0.15s)
# PASS
# ok      integration     2.456s
```

### Scenario 2: Load Testing

**Scenario:** Test API performance under load

```bash
# Step 1: Start services
make start

# Step 2: Warm up services
for i in {1..100}; do
  curl -s http://localhost:8080/health > /dev/null
done

# Step 3: Run load test with hey
hey -n 10000 -c 100 -m GET \
  http://localhost:8080/health

# Output:
# Summary:
#   Total:        5.2341 secs
#   Slowest:      0.0523 secs
#   Fastest:      0.0012 secs
#   Average:      0.0052 secs
#   Requests/sec: 1910.5721
#   
# Response time histogram:
#   0.001 [1]     |
#   0.006 [8234]  |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#   0.011 [1523]  |■■■■■■■■
#   0.016 [198]   |■
#   0.021 [32]    |
#   0.026 [8]     |
#   0.031 [2]     |
#   0.036 [1]     |
#   0.041 [0]     |
#   0.047 [0]     |
#   0.052 [1]     |
#
# Latency distribution:
#   10% in 0.0032 secs
#   25% in 0.0041 secs
#   50% in 0.0049 secs
#   75% in 0.0058 secs
#   90% in 0.0072 secs
#   95% in 0.0089 secs
#   99% in 0.0152 secs

# Step 4: Load test authenticated endpoint
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  | jq -r '.token')

hey -n 5000 -c 50 \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/users/profile

# Step 5: Monitor during load test
# In another terminal:
make open-grafana
# Watch metrics:
# - Request rate spikes to ~1900 req/s
# - CPU usage: 60-70%
# - Memory usage: stable at 300MB
# - Response time p99: <100ms
# - Error rate: 0%

# Step 6: Stress test (find breaking point)
hey -n 50000 -c 500 -m GET \
  http://localhost:8080/health

# Observe when performance degrades
# At 500 concurrent users:
# - Request rate: ~3000 req/s
# - Response time p99: 250ms
# - Some timeout errors appear
# 
# Conclusion: System handles ~300 concurrent users well
```

---

## Deployment Examples

### Example: Deploying to Local Kubernetes

```bash
# Step 1: Ensure local Kubernetes is running
# Docker Desktop: Enable Kubernetes in preferences
# Or use minikube:
minikube start --cpus=4 --memory=8192

# Step 2: Build Docker images
cd ~/workspace/go-platform/go-framework
make docker-build

# Output:
# 🐳 Building Docker images...
# Building api-gateway...
# Building auth-service...
# Building user-service...
# ...
# ✅ All images built successfully

# Step 3: Deploy to Kubernetes
make deploy-local

# Output:
# ☸️  Deploying to local Kubernetes...
# namespace/go-platform created
# configmap/app-config created
# secret/app-secrets created
# deployment.apps/mongodb created
# service/mongodb created
# deployment.apps/redis created
# service/redis created
# ...
# deployment.apps/api-gateway created
# service/api-gateway created
# ✅ Deployment complete!

# Step 4: Check deployment status
kubectl get pods -n go-platform

# Output:
# NAME                           READY   STATUS    RESTARTS   AGE
# api-gateway-7d9f8b6c-xyz       1/1     Running   0          2m
# auth-service-5f6d8c9b-abc      1/1     Running   0          2m
# user-service-8c7d9f6e-def      1/1     Running   0          2m
# mongodb-6f8e7d9c-ghi           1/1     Running   0          3m
# redis-5d7c8f9e-jkl             1/1     Running   0          3m

# Step 5: Setup port forwarding
make port-forward

# Or manually:
kubectl port-forward -n go-platform svc/api-gateway 8080:8080 &
kubectl port-forward -n go-platform svc/grafana 3000:3000 &

# Step 6: Test deployment
curl http://localhost:8080/health
# Response: {"status":"healthy"}

# Step 7: View logs
kubectl logs -n go-platform deployment/api-gateway --tail=50 -f

# Step 8: Scale deployment
kubectl scale deployment api-gateway -n go-platform --replicas=3

# Step 9: Update deployment (after code changes)
make docker-build
kubectl set image deployment/api-gateway \
  -n go-platform \
  api-gateway=vhvplatform/api-gateway:latest

kubectl rollout status deployment/api-gateway -n go-platform

# Step 10: Cleanup
kubectl delete namespace go-platform
```

---

## Troubleshooting Examples

### Example 1: Container Won't Start

**Problem:** Auth service container exits immediately

```bash
# Check container status
docker ps -a | grep auth-service

# Output:
# go-auth-service   Exited (1) 5 seconds ago

# Check logs
docker logs go-auth-service

# Output shows:
# Error: Failed to connect to MongoDB
# Error: dial tcp: lookup mongodb on 127.0.0.1:53: no such host

# Diagnosis: DNS resolution issue in Docker network

# Solution 1: Check network
docker network ls
docker network inspect go-network

# Verify auth-service is connected to go-network

# Solution 2: Recreate containers
make stop
make clean
make start

# Verify
make status
# Output: ✅ All services healthy
```

### Example 2: Database Connection Pooling Issue

**Problem:** MongoDB throwing "too many connections" error

```bash
# Symptoms in logs:
make logs-service SERVICE=user-service

# Output:
# Error: MongoError: too many connections
# Current connections: 512/512

# Step 1: Check current connections
docker exec mongodb mongosh --eval "db.serverStatus().connections"

# Output:
# {
#   "current": 512,
#   "available": 0,
#   "totalCreated": 5234
# }

# Step 2: Check connection pool settings
docker exec user-service env | grep MONGO

# Output:
# MONGODB_MAX_POOL_SIZE=100
# Problem: Multiple services with 100 connections each

# Step 3: Adjust pool sizes
# Edit docker/.env
MONGODB_MAX_POOL_SIZE=50  # Reduce per service

# Step 4: Restart services
make restart

# Step 5: Verify
docker exec mongodb mongosh --eval "db.serverStatus().connections"

# Output:
# {
#   "current": 250,  # Much better!
#   "available": 262
# }
```

---

## Integration Examples

### Example: Webhook Integration

**Scenario:** Send webhook when user is created

```go
// internal/webhooks/webhook_client.go
package webhooks

type WebhookClient struct {
    httpClient *http.Client
    baseURL    string
}

func (w *WebhookClient) SendUserCreated(ctx context.Context, user *User) error {
    payload := WebhookPayload{
        Event:     "user.created",
        Timestamp: time.Now(),
        Data: map[string]interface{}{
            "user_id": user.ID,
            "email":   user.Email,
            "name":    user.Name,
        },
    }
    
    body, _ := json.Marshal(payload)
    req, _ := http.NewRequestWithContext(ctx, "POST", w.baseURL+"/webhooks", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("X-Webhook-Signature", w.generateSignature(body))
    
    resp, err := w.httpClient.Do(req)
    if err != nil {
        return fmt.Errorf("webhook failed: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode >= 400 {
        return fmt.Errorf("webhook returned error: %d", resp.StatusCode)
    }
    
    return nil
}
```

**Testing Webhook:**

```bash
# Step 1: Setup webhook receiver (test server)
cat > webhook-test-server.go << 'EOF'
package main

import (
    "fmt"
    "io"
    "net/http"
)

func main() {
    http.HandleFunc("/webhooks", func(w http.ResponseWriter, r *http.Request) {
        body, _ := io.ReadAll(r.Body)
        fmt.Printf("Received webhook: %s\n", string(body))
        fmt.Printf("Signature: %s\n", r.Header.Get("X-Webhook-Signature"))
        w.WriteHeader(http.StatusOK)
    })
    
    fmt.Println("Webhook server listening on :9000")
    http.ListenAndServe(":9000", nil)
}
EOF

go run webhook-test-server.go &

# Step 2: Create user (triggers webhook)
curl -X POST http://localhost:8080/api/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "name": "New User"
  }'

# Step 3: Check webhook server output
# Output:
# Received webhook: {
#   "event": "user.created",
#   "timestamp": "2024-01-15T10:30:00Z",
#   "data": {
#     "user_id": "user-789",
#     "email": "newuser@example.com",
#     "name": "New User"
#   }
# }
# Signature: sha256=abc123...
```

---

**Last Updated:** 2024-12-25  
**Examples Version:** 1.0
