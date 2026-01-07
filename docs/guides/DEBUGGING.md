# Debugging Guide

Comprehensive guide for debugging the SaaS Platform microservices.

## Table of Contents

- [Overview](#overview)
- [Debugging Tools](#debugging-tools)
- [VS Code Debugging](#vs-code-debugging)
- [Command Line Debugging](#command-line-debugging)
- [Log Analysis](#log-analysis)
- [Network Debugging](#network-debugging)
- [Database Debugging](#database-debugging)
- [Performance Profiling](#performance-profiling)
- [Distributed Tracing](#distributed-tracing)
- [Common Debugging Scenarios](#common-debugging-scenarios)

---

## Overview

This guide covers tools and techniques for debugging microservices in the SaaS Platform.

### Debugging Philosophy

1. **Start with Logs** - Check service logs first
2. **Use Health Checks** - Verify service status
3. **Isolate the Problem** - Narrow down to specific service/component
4. **Reproduce Consistently** - Create reproducible test case
5. **Use Appropriate Tools** - Choose right tool for the problem

---

## Debugging Tools

### Essential Tools

```bash
# 1. Service Status
make status

# 2. Service Logs
make logs-service SERVICE=auth-service

# 3. Container Shell Access
make shell SERVICE=auth-service

# 4. Health Endpoints
curl http://localhost:8080/health

# 5. Monitoring Dashboards
make open-grafana
make open-jaeger

# 6. Database Access
docker exec -it mongodb mongosh
```

---

### Recommended Tools

**Command Line:**
- `curl` - HTTP requests
- `jq` - JSON processing
- `grpcurl` - gRPC requests
- `mongosh` - MongoDB shell
- `redis-cli` - Redis client

**GUI Tools:**
- **VS Code** - Integrated debugging
- **Postman** - API testing
- **MongoDB Compass** - Database GUI
- **Redis Insight** - Redis GUI
- **Grafana** - Metrics visualization
- **Jaeger** - Distributed tracing

---

## VS Code Debugging

### Setup

VS Code debug configurations are pre-configured in `configs/vscode/launch.json`.

```bash
# Open workspace in VS Code
code ~/workspace/go-platform
```

---

### Debug Configurations

Available debug configurations:

1. **Debug Auth Service** - Debug authentication service
2. **Debug User Service** - Debug user management service
3. **Debug API Gateway** - Debug API gateway
4. **Debug All Services** - Debug multiple services simultaneously
5. **Attach to Running Service** - Attach to already running service

---

### Starting a Debug Session

#### Method 1: Debug Panel

```
1. Open Debug panel (Cmd/Ctrl+Shift+D)
2. Select configuration (e.g., "Debug Auth Service")
3. Press F5 or click green play button
4. Service starts in debug mode
```

#### Method 2: Run and Debug

```
1. Open service file (e.g., cmd/server/main.go)
2. Press F5
3. Select "Debug Auth Service"
4. Service starts in debug mode
```

---

### Using Breakpoints

```go
// Example: internal/handlers/auth_handler.go

func (h *AuthHandler) Login(ctx context.Context, req *LoginRequest) (*LoginResponse, error) {
    // Click left of line number to set breakpoint
    logger.Info("Login attempt", "email", req.Email)  // <- Set breakpoint here
    
    user, err := h.repo.FindByEmail(ctx, req.Email)
    if err != nil {
        return nil, err  // <- Set breakpoint here
    }
    
    // Continue execution: F5
    // Step over: F10
    // Step into: F11
    // Step out: Shift+F11
    
    return &LoginResponse{Token: token}, nil
}
```

---

### Debug Features

#### Variables Panel

View local variables, function arguments, and closure variables.

```
Variables
├── req
│   ├── Email: "test@example.com"
│   └── Password: "password123"
├── user
│   ├── ID: "user-123"
│   ├── Email: "test@example.com"
│   └── Role: "admin"
└── err: nil
```

#### Watch Expressions

Add custom expressions to monitor:

```
Watch
├── user.ID
├── len(users)
├── time.Now()
└── req.Email == "admin@example.com"
```

#### Call Stack

View execution path:

```
Call Stack
├── auth_handler.go:45 Login
├── auth_handler.go:32 validateCredentials
├── user_repository.go:78 FindByEmail
└── mongodb_client.go:123 FindOne
```

#### Debug Console

Execute code during debugging:

```go
// In Debug Console:
> user.ID
"user-123"

> fmt.Printf("%+v", user)
{ID:user-123 Email:test@example.com Name:Test User}

> req.Email == user.Email
true
```

---

### Conditional Breakpoints

Set breakpoints that only trigger under specific conditions:

```
1. Right-click breakpoint
2. Select "Edit Breakpoint"
3. Choose "Conditional Breakpoint"
4. Enter condition:
   - Expression: req.Email == "admin@example.com"
   - Hit Count: 5 (break on 5th hit)
   - Log Message: "Login attempt for {req.Email}"
```

---

### Logpoints

Log messages without stopping execution:

```
1. Right-click in gutter
2. Select "Add Logpoint"
3. Enter message: "User {user.ID} logged in at {time.Now()}"
4. Logs appear in Debug Console without breaking
```

---

### Debugging Tests

```go
// user_service_test.go

func TestUserService_CreateUser(t *testing.T) {
    // Set breakpoint here
    service := NewUserService()
    
    user := &User{Email: "test@example.com"}
    err := service.CreateUser(context.Background(), user)
    
    assert.NoError(t, err)
}
```

**Run test in debug mode:**
```
1. Click "Debug Test" above test function (CodeLens)
2. Or press F5 with test file open
3. Breakpoints in test and application code will trigger
```

---

## Command Line Debugging

### Using Delve (dlv)

Delve is Go's debugger.

#### Installation

```bash
go install github.com/go-delve/delve/cmd/dlv@latest
```

#### Basic Usage

```bash
# Start service with debugger
cd ~/workspace/go-platform/go/go-auth-service
dlv debug cmd/server/main.go

# In dlv prompt:
(dlv) break main.main
(dlv) break internal/handlers.(*AuthHandler).Login
(dlv) continue
(dlv) print user
(dlv) next
(dlv) step
(dlv) locals
(dlv) quit
```

---

### Attach to Running Process

```bash
# Find process ID
ps aux | grep auth-service

# Attach debugger
dlv attach <PID>

# In dlv:
(dlv) break internal/handlers.(*AuthHandler).Login
(dlv) continue
```

---

### Remote Debugging

Debug services running in Docker:

```bash
# In docker-compose.yml, add:
services:
  auth-service:
    command: dlv exec ./auth-service --headless --listen=:2345 --api-version=2
    ports:
      - "2345:2345"

# From local machine:
dlv connect localhost:2345
```

---

## Log Analysis

### Viewing Logs

```bash
# All services
make logs

# Specific service
make logs-service SERVICE=auth-service

# Follow logs (tail -f)
make logs-service SERVICE=auth-service | tail -f

# Last 100 lines
docker logs --tail=100 auth-service

# Since timestamp
docker logs --since="2024-01-15T10:00:00" auth-service

# Filter by level
make logs-service SERVICE=auth-service | grep ERROR
make logs-service SERVICE=auth-service | grep WARN
```

---

### Log Levels

Understanding log levels:

```
DEBUG - Detailed information for debugging
INFO  - General informational messages
WARN  - Warning messages (potential issues)
ERROR - Error messages (something failed)
FATAL - Critical errors (service cannot continue)
```

---

### Structured Logging

Logs are structured JSON for easy parsing:

```json
{
  "level": "info",
  "time": "2024-01-15T10:30:00Z",
  "service": "auth-service",
  "trace_id": "abc123",
  "msg": "User login successful",
  "user_id": "user-123",
  "email": "test@example.com",
  "ip": "192.168.1.100"
}
```

Parse with jq:

```bash
# Extract errors
make logs-service SERVICE=auth-service | jq 'select(.level=="error")'

# Count by level
make logs-service SERVICE=auth-service | jq -r '.level' | sort | uniq -c

# Filter by user
make logs-service SERVICE=auth-service | jq 'select(.user_id=="user-123")'

# Extract trace IDs
make logs-service SERVICE=auth-service | jq -r '.trace_id' | uniq
```

---

### Log Correlation

Trace requests across services using trace_id:

```bash
# Get trace ID from API Gateway logs
TRACE_ID=$(make logs-service SERVICE=api-gateway | jq -r '.trace_id' | head -1)

# Find all logs for this request across all services
make logs | jq "select(.trace_id==\"$TRACE_ID\")"
```

---

## Network Debugging

### Testing Connectivity

```bash
# Test from host
curl -v http://localhost:8080/health

# Test from inside container
docker exec auth-service curl http://user-service:8080/health

# Test DNS resolution
docker exec auth-service nslookup user-service

# Test port accessibility
docker exec auth-service nc -zv user-service 8080
```

---

### Inspecting HTTP Traffic

#### Using curl with verbose output

```bash
curl -v http://localhost:8080/api/users

# Output shows:
# * Connection details
# * Request headers
# * Response headers
# * Response body
```

---

#### Using tcpdump

```bash
# Capture traffic on Docker network
docker run --net=container:auth-service nicolaka/netshoot tcpdump -i any -A

# Capture HTTP traffic
docker exec auth-service tcpdump -i any -A 'tcp port 8080'

# Save to file
docker exec auth-service tcpdump -i any -w /tmp/capture.pcap
# Copy file out
docker cp auth-service:/tmp/capture.pcap .
# Analyze with Wireshark
```

---

### gRPC Debugging

Using grpcurl:

```bash
# List services
grpcurl -plaintext localhost:50051 list

# List methods
grpcurl -plaintext localhost:50051 list auth.AuthService

# Call method
grpcurl -plaintext \
  -d '{"email":"test@example.com","password":"test123"}' \
  localhost:50051 auth.AuthService/Login

# With metadata (headers)
grpcurl -plaintext \
  -H 'authorization: Bearer token123' \
  localhost:50052 user.UserService/GetUser
```

---

### DNS Issues

```bash
# Check DNS configuration
docker exec auth-service cat /etc/resolv.conf

# Test DNS resolution
docker exec auth-service nslookup mongodb
docker exec auth-service dig mongodb

# Check hosts file
docker exec auth-service cat /etc/hosts

# Verify Docker network
docker network inspect go-framework_saas-network
```

---

## Database Debugging

### MongoDB Debugging

```bash
# Access MongoDB shell
docker exec -it mongodb mongosh

# In mongosh:
show dbs
use saas_platform
show collections

# Find documents
db.users.find().pretty()
db.users.findOne({email: "test@example.com"})

# Count documents
db.users.countDocuments()

# Check indexes
db.users.getIndexes()

# Explain query
db.users.find({email: "test@example.com"}).explain("executionStats")

# Check current operations
db.currentOp()

# Kill slow operation
db.killOp(<opid>)

# Check database stats
db.stats()

# Check collection stats
db.users.stats()
```

---

### Slow Query Analysis

```bash
# Enable profiling
db.setProfilingLevel(2)  # Profile all operations

# View slow queries
db.system.profile.find({millis: {$gt: 100}}).sort({millis: -1})

# Disable profiling
db.setProfilingLevel(0)
```

---

### Redis Debugging

```bash
# Access Redis CLI
docker exec -it redis redis-cli

# In redis-cli:
# List all keys
KEYS *

# Get key value
GET session:user-123

# Check key type
TYPE session:user-123

# View list
LRANGE queue:notifications 0 -1

# View hash
HGETALL user:123

# Check memory usage
INFO memory

# Monitor commands
MONITOR

# Check connected clients
CLIENT LIST

# Flush database (WARNING: deletes all data)
FLUSHDB
```

---

## Performance Profiling

### CPU Profiling

```bash
# Enable pprof in your service (already enabled)
import _ "net/http/pprof"

# Capture 30-second CPU profile
curl http://localhost:8081/debug/pprof/profile?seconds=30 > cpu.prof

# Analyze with pprof
go tool pprof cpu.prof

# In pprof:
(pprof) top10          # Show top 10 functions
(pprof) list FunctionName  # Show source code
(pprof) web            # Open in browser (requires graphviz)

# Or open directly in browser
go tool pprof -http=:8082 cpu.prof
```

---

### Memory Profiling

```bash
# Capture heap profile
curl http://localhost:8081/debug/pprof/heap > mem.prof

# Analyze
go tool pprof mem.prof

# In pprof:
(pprof) top10          # Top memory consumers
(pprof) list FunctionName
(pprof) web

# Check for memory leaks
# Capture two profiles with time between
curl http://localhost:8081/debug/pprof/heap > mem1.prof
# ... wait and generate load ...
curl http://localhost:8081/debug/pprof/heap > mem2.prof

# Compare
go tool pprof -base=mem1.prof mem2.prof
```

---

### Goroutine Analysis

```bash
# View goroutine stack traces
curl http://localhost:8081/debug/pprof/goroutine?debug=2

# Or interactive
go tool pprof http://localhost:8081/debug/pprof/goroutine

# Check for goroutine leaks
(pprof) top10
```

---

### Blocking Profile

```bash
# Capture blocking profile
curl http://localhost:8081/debug/pprof/block > block.prof

# Analyze
go tool pprof block.prof
```

---

### Trace Analysis

```bash
# Capture 5-second trace
curl http://localhost:8081/debug/pprof/trace?seconds=5 > trace.out

# View trace
go tool trace trace.out

# Opens browser with:
# - Timeline view
# - Goroutine analysis
# - Network blocking
# - Synchronization blocking
```

---

## Distributed Tracing

### Using Jaeger

```bash
# Open Jaeger UI
make open-jaeger
# Opens: http://localhost:16686
```

---

### Finding Traces

1. **Select Service** - Choose service from dropdown
2. **Set Time Range** - Recent traces or custom range
3. **Add Tags** - Filter by user_id, tenant_id, etc.
4. **Search** - Find specific traces

---

### Analyzing Traces

**Trace View Shows:**
- Request flow across services
- Duration of each service call
- Parallel vs sequential operations
- Errors and exceptions
- Tags and logs

**Example Trace:**
```
API Gateway [200ms]
  └─ Auth Service [50ms]
      └─ MongoDB Query [10ms]
  └─ User Service [30ms]
      └─ MongoDB Query [8ms]
      └─ Redis Get [2ms]
  └─ Notification Service [20ms]
      └─ RabbitMQ Publish [5ms]
```

---

### Adding Custom Spans

```go
import (
    "github.com/opentracing/opentracing-go"
)

func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
    // Start span
    span, ctx := opentracing.StartSpanFromContext(ctx, "GetUser")
    defer span.Finish()
    
    // Add tags
    span.SetTag("user.id", id)
    
    // Business logic
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        span.SetTag("error", true)
        span.LogKV("error", err.Error())
        return nil, err
    }
    
    span.SetTag("user.email", user.Email)
    return user, nil
}
```

---

## Common Debugging Scenarios

### Scenario 1: Service Not Responding

**Symptoms:** HTTP requests timeout

**Debug Steps:**

```bash
# 1. Check if service is running
docker ps | grep auth-service

# 2. Check service logs
make logs-service SERVICE=auth-service

# 3. Check service health
curl -v http://localhost:8081/health

# 4. Check from inside container
docker exec auth-service curl localhost:8080/health

# 5. Check if port is listening
docker exec auth-service netstat -tuln | grep 8080

# 6. Restart service
make restart-service SERVICE=auth-service
```

---

### Scenario 2: Database Connection Issues

**Symptoms:** "Failed to connect to MongoDB"

**Debug Steps:**

```bash
# 1. Check if MongoDB is running
docker ps | grep mongodb

# 2. Check MongoDB logs
docker logs mongodb

# 3. Test connection from service
docker exec auth-service nc -zv mongodb 27017

# 4. Test MongoDB itself
docker exec mongodb mongosh --eval "db.adminCommand('ping')"

# 5. Check connection string
docker exec auth-service env | grep MONGODB

# 6. Restart MongoDB
docker restart mongodb
```

---

### Scenario 3: Memory Leak

**Symptoms:** Memory usage keeps increasing

**Debug Steps:**

```bash
# 1. Monitor memory usage
docker stats auth-service

# 2. Capture heap profile over time
curl http://localhost:8081/debug/pprof/heap > mem1.prof
# Wait 5 minutes
curl http://localhost:8081/debug/pprof/heap > mem2.prof

# 3. Compare profiles
go tool pprof -base=mem1.prof mem2.prof

# 4. Look for growing allocations
(pprof) top10

# 5. Investigate specific functions
(pprof) list SuspectFunction

# 6. Check for goroutine leaks
curl http://localhost:8081/debug/pprof/goroutine?debug=2 > goroutines.txt
# Check if count keeps growing
```

---

### Scenario 4: Slow API Responses

**Symptoms:** High response times

**Debug Steps:**

```bash
# 1. Check Grafana metrics
make open-grafana

# 2. View distributed traces
make open-jaeger

# 3. Profile CPU usage
curl http://localhost:8081/debug/pprof/profile?seconds=30 > cpu.prof
go tool pprof -http=:8082 cpu.prof

# 4. Check for slow database queries
docker exec mongodb mongosh
db.setProfilingLevel(2)
db.system.profile.find({millis: {$gt: 100}})

# 5. Check for blocking operations
curl http://localhost:8081/debug/pprof/block > block.prof
go tool pprof block.prof
```

---

### Scenario 5: Authentication Failures

**Symptoms:** "Unauthorized" errors

**Debug Steps:**

```bash
# 1. Check token format
echo "Bearer token123" | base64 -d

# 2. Generate test token
make generate-jwt

# 3. Verify token manually
TOKEN="your-token"
curl http://localhost:8081/auth/verify \
  -H "Authorization: Bearer $TOKEN"

# 4. Check Auth service logs
make logs-service SERVICE=auth-service | grep -i auth

# 5. Check JWT secret
docker exec auth-service env | grep JWT_SECRET

# 6. Test with known good credentials
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'
```

---

## See Also

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) - Development workflow
- [TESTING.md](TESTING.md) - Testing guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture

---

**Last Updated:** 2024-01-15  
**Happy Debugging! 🐛**
