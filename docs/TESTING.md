# Testing Guide

Comprehensive guide for testing the SaaS Platform microservices.

## Table of Contents

- [Overview](#overview)
- [Testing Strategy](#testing-strategy)
- [Unit Testing](#unit-testing)
- [Integration Testing](#integration-testing)
- [End-to-End Testing](#end-to-end-testing)
- [Load Testing](#load-testing)
- [Test Data Management](#test-data-management)
- [Mocking and Stubbing](#mocking-and-stubbing)
- [CI/CD Testing](#cicd-testing)
- [Best Practices](#best-practices)

---

## Overview

The SaaS Platform uses a comprehensive testing strategy covering multiple levels:

```
┌─────────────────────────────────────────┐
│         End-to-End Tests (E2E)          │
│   (Full user workflows, UI to database) │
└─────────────────────────────────────────┘
                  ▲
┌─────────────────────────────────────────┐
│       Integration Tests                  │
│   (Service interactions, database, API)  │
└─────────────────────────────────────────┘
                  ▲
┌─────────────────────────────────────────┐
│          Unit Tests                      │
│   (Individual functions, pure logic)     │
└─────────────────────────────────────────┘
```

---

## Testing Strategy

### Test Pyramid

Our testing follows the test pyramid approach:

- **70% Unit Tests** - Fast, isolated, numerous
- **20% Integration Tests** - Service interactions
- **10% E2E Tests** - Critical user journeys

### Test Coverage Goals

- **Unit Tests:** 80%+ code coverage
- **Integration Tests:** All API endpoints
- **E2E Tests:** Critical user workflows

---

## Unit Testing

Unit tests verify individual functions and methods in isolation.

### Running Unit Tests

```bash
# Run all unit tests
make test-unit

# Run tests for specific service
cd ~/workspace/go-platform/go-auth-service
go test ./...

# Run specific package
go test ./internal/handlers

# Run with coverage
go test -cover ./...

# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html
open coverage.html

# Run with verbose output
go test -v ./...

# Run specific test
go test -run TestLoginHandler ./internal/handlers
```

---

### Writing Unit Tests

#### Basic Test Structure

```go
package handlers

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

func TestUserHandler_CreateUser(t *testing.T) {
    // Arrange
    mockRepo := new(MockUserRepository)
    handler := NewUserHandler(mockRepo)
    
    user := &User{
        Email: "test@example.com",
        Name:  "Test User",
    }
    
    mockRepo.On("Create", mock.Anything, user).Return(nil)
    
    // Act
    err := handler.CreateUser(context.Background(), user)
    
    // Assert
    assert.NoError(t, err)
    mockRepo.AssertExpectations(t)
}
```

---

#### Table-Driven Tests

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"missing @", "userexample.com", true},
        {"missing domain", "user@", true},
        {"empty", "", true},
        {"valid with subdomain", "user@mail.example.com", false},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

---

#### Testing with Mocks

```go
// Mock interface
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) Create(ctx context.Context, user *User) error {
    args := m.Called(ctx, user)
    return args.Error(0)
}

func (m *MockUserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
    args := m.Called(ctx, email)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*User), args.Error(1)
}

// Usage in test
func TestLoginHandler(t *testing.T) {
    mockRepo := new(MockUserRepository)
    mockAuth := new(MockAuthService)
    handler := NewLoginHandler(mockRepo, mockAuth)
    
    user := &User{
        ID:       "123",
        Email:    "test@example.com",
        Password: "hashed_password",
    }
    
    mockRepo.On("FindByEmail", mock.Anything, "test@example.com").
        Return(user, nil)
    mockAuth.On("ValidatePassword", "password123", "hashed_password").
        Return(true)
    mockAuth.On("GenerateToken", user).
        Return("token123", nil)
    
    token, err := handler.Login(context.Background(), "test@example.com", "password123")
    
    assert.NoError(t, err)
    assert.Equal(t, "token123", token)
    mockRepo.AssertExpectations(t)
    mockAuth.AssertExpectations(t)
}
```

---

### Test Helpers

Create reusable test helpers:

```go
// testutil/helpers.go
package testutil

func CreateTestUser(t *testing.T) *User {
    return &User{
        ID:    "test-user-" + uuid.New().String(),
        Email: "test@example.com",
        Name:  "Test User",
    }
}

func SetupTestDB(t *testing.T) *mongo.Database {
    client, err := mongo.Connect(context.Background(), options.Client().ApplyURI("mongodb://localhost:27017"))
    require.NoError(t, err)
    
    db := client.Database("test_" + uuid.New().String())
    
    t.Cleanup(func() {
        db.Drop(context.Background())
        client.Disconnect(context.Background())
    })
    
    return db
}
```

---

## Integration Testing

Integration tests verify that different components work together correctly.

### Running Integration Tests

```bash
# Ensure services are running
make start

# Run integration tests
make test-integration

# Run for specific service
cd ~/workspace/go-platform/go-auth-service
go test -tags=integration ./test/integration/...

# With verbose output
go test -tags=integration -v ./test/integration/...
```

---

### Writing Integration Tests

#### API Integration Test

```go
// +build integration

package integration

import (
    "net/http"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestAuthAPI_Login(t *testing.T) {
    // Setup
    client := &http.Client{}
    baseURL := "http://localhost:8081"
    
    // Prepare request
    loginData := `{"email":"admin@example.com","password":"admin123"}`
    req, err := http.NewRequest("POST", baseURL+"/auth/login", 
        strings.NewReader(loginData))
    require.NoError(t, err)
    req.Header.Set("Content-Type", "application/json")
    
    // Execute
    resp, err := client.Do(req)
    require.NoError(t, err)
    defer resp.Body.Close()
    
    // Assert
    assert.Equal(t, http.StatusOK, resp.StatusCode)
    
    var result map[string]interface{}
    err = json.NewDecoder(resp.Body).Decode(&result)
    require.NoError(t, err)
    
    assert.Contains(t, result, "token")
    assert.NotEmpty(t, result["token"])
}
```

---

#### Database Integration Test

```go
func TestUserRepository_Create(t *testing.T) {
    // Setup test database
    db := testutil.SetupTestDB(t)
    repo := NewUserRepository(db)
    
    // Test data
    user := &User{
        Email: "test@example.com",
        Name:  "Test User",
    }
    
    // Execute
    err := repo.Create(context.Background(), user)
    require.NoError(t, err)
    assert.NotEmpty(t, user.ID)
    
    // Verify in database
    found, err := repo.FindByID(context.Background(), user.ID)
    require.NoError(t, err)
    assert.Equal(t, user.Email, found.Email)
    assert.Equal(t, user.Name, found.Name)
}
```

---

#### gRPC Integration Test

```go
func TestUserServiceGRPC_CreateUser(t *testing.T) {
    // Setup gRPC connection
    conn, err := grpc.Dial("localhost:50052", 
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    require.NoError(t, err)
    defer conn.Close()
    
    client := userpb.NewUserServiceClient(conn)
    
    // Execute
    resp, err := client.CreateUser(context.Background(), &userpb.CreateUserRequest{
        Email: "test@example.com",
        Name:  "Test User",
    })
    
    // Assert
    require.NoError(t, err)
    assert.NotEmpty(t, resp.UserId)
    assert.Equal(t, "test@example.com", resp.User.Email)
}
```

---

## End-to-End Testing

E2E tests verify complete user workflows from API to database.

### Running E2E Tests

```bash
# Ensure all services are running
make start

# Ensure test data is loaded
make db-seed

# Run E2E tests
make test-e2e

# Run with verbose output
E2E_VERBOSE=true make test-e2e
```

---

### Writing E2E Tests

#### User Registration and Login Flow

```go
func TestE2E_UserRegistrationAndLogin(t *testing.T) {
    client := &http.Client{}
    baseURL := "http://localhost:8080"
    
    // Step 1: Register new user
    registerData := `{
        "email": "newuser@example.com",
        "password": "SecurePass123!",
        "name": "New User"
    }`
    
    resp := makeRequest(t, client, "POST", baseURL+"/api/auth/register", registerData)
    assert.Equal(t, http.StatusCreated, resp.StatusCode)
    
    var registerResult map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&registerResult)
    userID := registerResult["user_id"].(string)
    
    // Step 2: Login
    loginData := `{
        "email": "newuser@example.com",
        "password": "SecurePass123!"
    }`
    
    resp = makeRequest(t, client, "POST", baseURL+"/api/auth/login", loginData)
    assert.Equal(t, http.StatusOK, resp.StatusCode)
    
    var loginResult map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&loginResult)
    token := loginResult["token"].(string)
    assert.NotEmpty(t, token)
    
    // Step 3: Get user profile
    req, _ := http.NewRequest("GET", baseURL+"/api/users/"+userID, nil)
    req.Header.Set("Authorization", "Bearer "+token)
    
    resp, err := client.Do(req)
    require.NoError(t, err)
    assert.Equal(t, http.StatusOK, resp.StatusCode)
    
    var userResult map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&userResult)
    assert.Equal(t, "newuser@example.com", userResult["email"])
    assert.Equal(t, "New User", userResult["name"])
}
```

---

#### Multi-Service Workflow

```go
func TestE2E_TenantCreationWorkflow(t *testing.T) {
    client := &http.Client{}
    baseURL := "http://localhost:8080"
    
    // Login as admin
    token := loginAsAdmin(t, client, baseURL)
    
    // Create tenant
    tenantData := `{
        "name": "Test Company",
        "slug": "test-company",
        "plan": "enterprise"
    }`
    
    req, _ := http.NewRequest("POST", baseURL+"/api/tenants", 
        strings.NewReader(tenantData))
    req.Header.Set("Authorization", "Bearer "+token)
    req.Header.Set("Content-Type", "application/json")
    
    resp, err := client.Do(req)
    require.NoError(t, err)
    assert.Equal(t, http.StatusCreated, resp.StatusCode)
    
    var tenantResult map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&tenantResult)
    tenantID := tenantResult["id"].(string)
    
    // Verify tenant in database
    // Verify notification was sent
    // Verify audit log was created
    
    // This test verifies:
    // - API Gateway routing
    // - Authentication
    // - Tenant Service
    // - Database persistence
    // - Notification Service
    // - Audit logging
}
```

---

## Load Testing

Load tests verify system performance under stress.

### Running Load Tests

```bash
# Run default load test (10 users, 30 seconds)
make test-load

# Custom load test
USERS=50 DURATION=60 RATE=200 make test-load

# Specific endpoint
ENDPOINT="/api/auth/login" make test-load
```

---

### Load Testing with Hey

```bash
# Install hey
go install github.com/rakyll/hey@latest

# Basic load test
hey -n 1000 -c 10 http://localhost:8080/health

# With authentication
hey -n 1000 -c 10 \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/users

# POST requests
hey -n 1000 -c 10 \
  -m POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  http://localhost:8080/api/auth/login
```

---

### Load Testing with k6

Create `scripts/testing/load-test.js`:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up
    { duration: '1m', target: 50 },   // Stay at 50 users
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],   // Error rate under 1%
  },
};

export default function () {
  // Login
  let loginRes = http.post('http://localhost:8080/api/auth/login', 
    JSON.stringify({
      email: 'test@example.com',
      password: 'test123',
    }), {
      headers: { 'Content-Type': 'application/json' },
    }
  );
  
  check(loginRes, {
    'login successful': (r) => r.status === 200,
    'got token': (r) => r.json('token') !== '',
  });
  
  let token = loginRes.json('token');
  
  // Get user profile
  let profileRes = http.get('http://localhost:8080/api/users/me', {
    headers: { 'Authorization': `Bearer ${token}` },
  });
  
  check(profileRes, {
    'profile retrieved': (r) => r.status === 200,
  });
  
  sleep(1);
}
```

Run with:

```bash
k6 run scripts/testing/load-test.js
```

---

## Test Data Management

### Loading Test Data

```bash
# Load predefined test data
make db-seed

# Generate custom test data
make test-data

# Generate specific amount
USERS=100 TENANTS=20 make test-data
```

---

### Test Fixtures

Create JSON fixtures for consistent test data:

```json
// fixtures/users.json
[
  {
    "id": "user-1",
    "email": "admin@example.com",
    "name": "Admin User",
    "role": "admin"
  },
  {
    "id": "user-2",
    "email": "user@example.com",
    "name": "Regular User",
    "role": "user"
  }
]
```

Load in tests:

```go
func LoadTestFixture(t *testing.T, filename string) []byte {
    data, err := os.ReadFile(filepath.Join("fixtures", filename))
    require.NoError(t, err)
    return data
}

func TestWithFixture(t *testing.T) {
    data := LoadTestFixture(t, "users.json")
    var users []User
    err := json.Unmarshal(data, &users)
    require.NoError(t, err)
    
    // Use users in test
}
```

---

### Database Seeding

```go
// testutil/seed.go
func SeedTestData(t *testing.T, db *mongo.Database) {
    ctx := context.Background()
    
    // Create users
    users := []interface{}{
        User{ID: "user-1", Email: "admin@example.com", Role: "admin"},
        User{ID: "user-2", Email: "user@example.com", Role: "user"},
    }
    _, err := db.Collection("users").InsertMany(ctx, users)
    require.NoError(t, err)
    
    // Create tenants
    tenants := []interface{}{
        Tenant{ID: "tenant-1", Name: "Test Tenant", Slug: "test"},
    }
    _, err = db.Collection("tenants").InsertMany(ctx, tenants)
    require.NoError(t, err)
}
```

---

## Mocking and Stubbing

### Using testify/mock

```go
// Generate mocks
//go:generate mockery --name=UserRepository --output=mocks

type UserRepository interface {
    Create(ctx context.Context, user *User) error
    FindByID(ctx context.Context, id string) (*User, error)
}

// Mock is auto-generated in mocks/UserRepository.go

// Usage in test
func TestUserService_CreateUser(t *testing.T) {
    mockRepo := new(mocks.UserRepository)
    service := NewUserService(mockRepo)
    
    user := &User{Email: "test@example.com"}
    mockRepo.On("Create", mock.Anything, user).Return(nil)
    
    err := service.CreateUser(context.Background(), user)
    
    assert.NoError(t, err)
    mockRepo.AssertExpectations(t)
}
```

---

### HTTP Mocking with httptest

```go
func TestHTTPHandler(t *testing.T) {
    handler := NewUserHandler()
    
    req := httptest.NewRequest("GET", "/users/123", nil)
    w := httptest.NewRecorder()
    
    handler.ServeHTTP(w, req)
    
    resp := w.Result()
    assert.Equal(t, http.StatusOK, resp.StatusCode)
    
    body, _ := io.ReadAll(resp.Body)
    assert.Contains(t, string(body), "test@example.com")
}
```

---

## CI/CD Testing

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Run unit tests
        run: go test -v -cover ./...
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.out
  
  integration-tests:
    runs-on: ubuntu-latest
    services:
      mongodb:
        image: mongo:7
        ports:
          - 27017:27017
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Run integration tests
        run: go test -tags=integration -v ./test/integration/...
```

---

## Best Practices

### Test Organization

```
service/
├── internal/
│   ├── handlers/
│   │   ├── user_handler.go
│   │   └── user_handler_test.go
│   └── repository/
│       ├── user_repository.go
│       └── user_repository_test.go
├── test/
│   ├── integration/
│   │   └── user_api_test.go
│   └── e2e/
│       └── user_workflow_test.go
└── testutil/
    ├── helpers.go
    └── fixtures.go
```

---

### Testing Guidelines

1. **Test Naming:** Use descriptive names
   ```go
   func TestUserHandler_CreateUser_WithValidData_ReturnsSuccess(t *testing.T)
   ```

2. **Arrange-Act-Assert:** Structure tests clearly
   ```go
   // Arrange
   user := &User{Email: "test@example.com"}
   
   // Act
   err := handler.CreateUser(ctx, user)
   
   // Assert
   assert.NoError(t, err)
   ```

3. **Test Independence:** Tests should not depend on each other

4. **Clean Up:** Use `t.Cleanup()` for teardown

5. **Test Data:** Use realistic but simple test data

6. **Error Cases:** Test both success and failure paths

7. **Coverage:** Aim for 80%+ but focus on critical paths

---

## See Also

- [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) - Development workflow
- [DEBUGGING.md](DEBUGGING.md) - Debugging techniques
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide

---

**Last Updated:** 2024-01-15
