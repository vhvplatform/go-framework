# New Service Development Guide

Complete guide for creating new microservices in the platform.

## Table of Contents

- [Quick Start](#quick-start)
- [Service Generator](#service-generator)
- [Service Structure](#service-structure)
- [Development Workflow](#development-workflow)
- [Integration Checklist](#integration-checklist)
- [Best Practices](#best-practices)
- [Testing Your Service](#testing-your-service)
- [Deployment](#deployment)

---

## Quick Start

### Using the Service Generator (Recommended)

The fastest way to create a new service:

```bash
# Generate a new service with all boilerplate
./scripts/dev/create-service.sh my-service

# Or use make command
make create-service SERVICE=my-service

# With options
./scripts/dev/create-service.sh my-service \
  --port 8080 \
  --database mongodb \
  --with-grpc \
  --with-messaging
```

**What it creates:**
- ✅ Complete Go project structure
- ✅ Docker configuration
- ✅ HTTP server with health endpoints
- ✅ gRPC server (optional)
- ✅ Database connection (MongoDB/PostgreSQL)
- ✅ Redis integration
- ✅ RabbitMQ messaging (optional)
- ✅ Prometheus metrics
- ✅ Jaeger tracing
- ✅ Unit test templates
- ✅ Makefile for common tasks
- ✅ README with documentation

### Manual Creation

If you prefer to create manually, follow the [Service Structure](#service-structure) section.

---

## Service Generator

### Basic Usage

```bash
# Generate service with defaults
./scripts/dev/create-service.sh user-service

# Specify port
./scripts/dev/create-service.sh user-service --port 8085

# With PostgreSQL instead of MongoDB
./scripts/dev/create-service.sh user-service --database postgres

# Full-featured service
./scripts/dev/create-service.sh user-service \
  --port 8085 \
  --database mongodb \
  --with-grpc \
  --with-messaging \
  --with-cache
```

### Available Options

| Option | Description | Default |
|--------|-------------|---------|
| `--port PORT` | HTTP server port | 8080 |
| `--grpc-port PORT` | gRPC server port | 9090 |
| `--database TYPE` | Database type (mongodb/postgres/none) | mongodb |
| `--with-grpc` | Include gRPC server | false |
| `--with-messaging` | Include RabbitMQ messaging | false |
| `--with-cache` | Include Redis caching | true |
| `--no-tests` | Skip test file generation | false |
| `--output DIR` | Output directory | ../services |

### Generated Structure

```
my-service/
├── cmd/
│   └── server/
│       └── main.go              # Application entry point
├── internal/
│   ├── config/
│   │   └── config.go            # Configuration management
│   ├── handler/
│   │   ├── http.go              # HTTP handlers
│   │   └── grpc.go              # gRPC handlers (if enabled)
│   ├── service/
│   │   └── service.go           # Business logic
│   ├── repository/
│   │   └── repository.go        # Data access layer
│   └── model/
│       └── model.go             # Data models
├── pkg/
│   └── client/
│       └── client.go            # Client library for other services
├── api/
│   └── proto/
│       └── service.proto        # Protocol buffers (if gRPC enabled)
├── migrations/
│   └── 001_initial.sql          # Database migrations
├── tests/
│   ├── unit/
│   │   └── service_test.go      # Unit tests
│   └── integration/
│       └── integration_test.go  # Integration tests
├── docker/
│   └── Dockerfile               # Container image
├── configs/
│   ├── config.yaml              # Default configuration
│   └── config.local.yaml        # Local overrides
├── scripts/
│   ├── build.sh                 # Build script
│   ├── test.sh                  # Test runner
│   └── migrate.sh               # Database migrations
├── Makefile                     # Build automation
├── go.mod                       # Go dependencies
├── go.sum
├── README.md                    # Service documentation
└── .env.example                 # Environment variables template
```

---

## Service Structure

### Recommended Architecture

Each service follows **Clean Architecture** principles:

```
┌─────────────────────────────────────┐
│         HTTP/gRPC Handlers          │  ← Presentation Layer
├─────────────────────────────────────┤
│         Service Layer               │  ← Business Logic
├─────────────────────────────────────┤
│         Repository Layer            │  ← Data Access
├─────────────────────────────────────┤
│    Database / External Services     │  ← Infrastructure
└─────────────────────────────────────┘
```

### Key Components

#### 1. Main Entry Point (`cmd/server/main.go`)

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/vhvplatform/my-service/internal/config"
    "github.com/vhvplatform/my-service/internal/handler"
    "github.com/vhvplatform/my-service/internal/repository"
    "github.com/vhvplatform/my-service/internal/service"
)

func main() {
    // Load configuration
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("Failed to load config: %v", err)
    }

    // Initialize repository
    repo, err := repository.New(cfg.Database)
    if err != nil {
        log.Fatalf("Failed to create repository: %v", err)
    }
    defer repo.Close()

    // Initialize service
    svc := service.New(repo, cfg)

    // Initialize HTTP handler
    httpHandler := handler.NewHTTP(svc, cfg)

    // Start server
    log.Printf("Starting server on port %s", cfg.Server.Port)
    if err := httpHandler.Start(); err != nil {
        log.Fatalf("Server failed: %v", err)
    }

    // Graceful shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server...")
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := httpHandler.Shutdown(ctx); err != nil {
        log.Fatalf("Server shutdown failed: %v", err)
    }

    log.Println("Server stopped")
}
```

#### 2. Configuration (`internal/config/config.go`)

```go
package config

import (
    "os"
    "strconv"

    "github.com/joho/godotenv"
)

type Config struct {
    Server   ServerConfig
    Database DatabaseConfig
    Redis    RedisConfig
    RabbitMQ RabbitMQConfig
    Observability ObservabilityConfig
}

type ServerConfig struct {
    Port     string
    GRPCPort string
    Env      string
}

type DatabaseConfig struct {
    Host     string
    Port     int
    Database string
    Username string
    Password string
}

type RedisConfig struct {
    Host     string
    Port     int
    Password string
    DB       int
}

type RabbitMQConfig struct {
    URL      string
    Exchange string
    Queue    string
}

type ObservabilityConfig struct {
    PrometheusPort string
    JaegerEndpoint string
}

func Load() (*Config, error) {
    // Load .env file if exists
    _ = godotenv.Load()

    return &Config{
        Server: ServerConfig{
            Port:     getEnv("PORT", "8080"),
            GRPCPort: getEnv("GRPC_PORT", "9090"),
            Env:      getEnv("ENV", "development"),
        },
        Database: DatabaseConfig{
            Host:     getEnv("DB_HOST", "localhost"),
            Port:     getEnvAsInt("DB_PORT", 27017),
            Database: getEnv("DB_NAME", "myservice"),
            Username: getEnv("DB_USER", ""),
            Password: getEnv("DB_PASSWORD", ""),
        },
        Redis: RedisConfig{
            Host:     getEnv("REDIS_HOST", "localhost"),
            Port:     getEnvAsInt("REDIS_PORT", 6379),
            Password: getEnv("REDIS_PASSWORD", ""),
            DB:       getEnvAsInt("REDIS_DB", 0),
        },
        RabbitMQ: RabbitMQConfig{
            URL:      getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
            Exchange: getEnv("RABBITMQ_EXCHANGE", "events"),
            Queue:    getEnv("RABBITMQ_QUEUE", "my-service-queue"),
        },
        Observability: ObservabilityConfig{
            PrometheusPort: getEnv("PROMETHEUS_PORT", "2112"),
            JaegerEndpoint: getEnv("JAEGER_ENDPOINT", "http://localhost:14268/api/traces"),
        },
    }, nil
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
    valueStr := os.Getenv(key)
    if value, err := strconv.Atoi(valueStr); err == nil {
        return value
    }
    return defaultValue
}
```

#### 3. HTTP Handler (`internal/handler/http.go`)

```go
package handler

import (
    "context"
    "encoding/json"
    "net/http"
    "time"

    "github.com/gorilla/mux"
    "github.com/prometheus/client_golang/prometheus/promhttp"
    "github.com/vhvplatform/my-service/internal/config"
    "github.com/vhvplatform/my-service/internal/service"
)

type HTTPHandler struct {
    service *service.Service
    router  *mux.Router
    server  *http.Server
    config  *config.Config
}

func NewHTTP(svc *service.Service, cfg *config.Config) *HTTPHandler {
    h := &HTTPHandler{
        service: svc,
        router:  mux.NewRouter(),
        config:  cfg,
    }

    h.setupRoutes()
    return h
}

func (h *HTTPHandler) setupRoutes() {
    // Health check endpoints
    h.router.HandleFunc("/health", h.healthCheck).Methods("GET")
    h.router.HandleFunc("/ready", h.readinessCheck).Methods("GET")

    // Metrics endpoint
    h.router.Handle("/metrics", promhttp.Handler())

    // API routes
    api := h.router.PathPrefix("/api/v1").Subrouter()
    
    // Add middleware
    api.Use(h.loggingMiddleware)
    api.Use(h.corsMiddleware)
    
    // Your endpoints here
    api.HandleFunc("/items", h.listItems).Methods("GET")
    api.HandleFunc("/items", h.createItem).Methods("POST")
    api.HandleFunc("/items/{id}", h.getItem).Methods("GET")
    api.HandleFunc("/items/{id}", h.updateItem).Methods("PUT")
    api.HandleFunc("/items/{id}", h.deleteItem).Methods("DELETE")
}

func (h *HTTPHandler) Start() error {
    h.server = &http.Server{
        Addr:         ":" + h.config.Server.Port,
        Handler:      h.router,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    return h.server.ListenAndServe()
}

func (h *HTTPHandler) Shutdown(ctx context.Context) error {
    return h.server.Shutdown(ctx)
}

// Health check endpoint
func (h *HTTPHandler) healthCheck(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{
        "status": "healthy",
        "service": "my-service",
    })
}

// Readiness check endpoint
func (h *HTTPHandler) readinessCheck(w http.ResponseWriter, r *http.Request) {
    // Check dependencies (database, cache, etc.)
    if err := h.service.CheckDependencies(r.Context()); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]string{
            "status": "not ready",
            "error":  err.Error(),
        })
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{
        "status": "ready",
    })
}

// Example CRUD endpoints
func (h *HTTPHandler) listItems(w http.ResponseWriter, r *http.Request) {
    items, err := h.service.ListItems(r.Context())
    if err != nil {
        h.errorResponse(w, err, http.StatusInternalServerError)
        return
    }

    h.jsonResponse(w, items, http.StatusOK)
}

func (h *HTTPHandler) createItem(w http.ResponseWriter, r *http.Request) {
    // Parse request body
    var req struct {
        Name        string `json:"name"`
        Description string `json:"description"`
    }

    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        h.errorResponse(w, err, http.StatusBadRequest)
        return
    }

    // Create item
    item, err := h.service.CreateItem(r.Context(), req.Name, req.Description)
    if err != nil {
        h.errorResponse(w, err, http.StatusInternalServerError)
        return
    }

    h.jsonResponse(w, item, http.StatusCreated)
}

func (h *HTTPHandler) getItem(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id := vars["id"]

    item, err := h.service.GetItem(r.Context(), id)
    if err != nil {
        h.errorResponse(w, err, http.StatusNotFound)
        return
    }

    h.jsonResponse(w, item, http.StatusOK)
}

func (h *HTTPHandler) updateItem(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id := vars["id"]

    var req struct {
        Name        string `json:"name"`
        Description string `json:"description"`
    }

    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        h.errorResponse(w, err, http.StatusBadRequest)
        return
    }

    item, err := h.service.UpdateItem(r.Context(), id, req.Name, req.Description)
    if err != nil {
        h.errorResponse(w, err, http.StatusInternalServerError)
        return
    }

    h.jsonResponse(w, item, http.StatusOK)
}

func (h *HTTPHandler) deleteItem(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    id := vars["id"]

    if err := h.service.DeleteItem(r.Context(), id); err != nil {
        h.errorResponse(w, err, http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusNoContent)
}

// Middleware
func (h *HTTPHandler) loggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        duration := time.Since(start)
        
        // Log request
        log.Printf("%s %s %v", r.Method, r.URL.Path, duration)
    })
}

func (h *HTTPHandler) corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }

        next.ServeHTTP(w, r)
    })
}

// Helper functions
func (h *HTTPHandler) jsonResponse(w http.ResponseWriter, data interface{}, status int) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func (h *HTTPHandler) errorResponse(w http.ResponseWriter, err error, status int) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(map[string]string{
        "error": err.Error(),
    })
}
```

#### 4. Service Layer (`internal/service/service.go`)

```go
package service

import (
    "context"
    "errors"

    "github.com/vhvplatform/my-service/internal/config"
    "github.com/vhvplatform/my-service/internal/model"
    "github.com/vhvplatform/my-service/internal/repository"
)

type Service struct {
    repo   *repository.Repository
    config *config.Config
}

func New(repo *repository.Repository, cfg *config.Config) *Service {
    return &Service{
        repo:   repo,
        config: cfg,
    }
}

func (s *Service) CheckDependencies(ctx context.Context) error {
    return s.repo.Ping(ctx)
}

func (s *Service) ListItems(ctx context.Context) ([]*model.Item, error) {
    return s.repo.FindAll(ctx)
}

func (s *Service) GetItem(ctx context.Context, id string) (*model.Item, error) {
    item, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }
    if item == nil {
        return nil, errors.New("item not found")
    }
    return item, nil
}

func (s *Service) CreateItem(ctx context.Context, name, description string) (*model.Item, error) {
    // Validate input
    if name == "" {
        return nil, errors.New("name is required")
    }

    item := &model.Item{
        Name:        name,
        Description: description,
    }

    if err := s.repo.Create(ctx, item); err != nil {
        return nil, err
    }

    return item, nil
}

func (s *Service) UpdateItem(ctx context.Context, id, name, description string) (*model.Item, error) {
    item, err := s.GetItem(ctx, id)
    if err != nil {
        return nil, err
    }

    item.Name = name
    item.Description = description

    if err := s.repo.Update(ctx, item); err != nil {
        return nil, err
    }

    return item, nil
}

func (s *Service) DeleteItem(ctx context.Context, id string) error {
    return s.repo.Delete(ctx, id)
}
```

#### 5. Repository Layer (`internal/repository/repository.go`)

```go
package repository

import (
    "context"
    "time"

    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"

    "github.com/vhvplatform/my-service/internal/config"
    "github.com/vhvplatform/my-service/internal/model"
)

type Repository struct {
    client     *mongo.Client
    database   *mongo.Database
    collection *mongo.Collection
}

func New(cfg config.DatabaseConfig) (*Repository, error) {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    // Build connection string
    uri := fmt.Sprintf("mongodb://%s:%s@%s:%d/%s",
        cfg.Username, cfg.Password, cfg.Host, cfg.Port, cfg.Database)

    // Connect to MongoDB
    client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
    if err != nil {
        return nil, err
    }

    // Ping database
    if err := client.Ping(ctx, nil); err != nil {
        return nil, err
    }

    database := client.Database(cfg.Database)
    collection := database.Collection("items")

    return &Repository{
        client:     client,
        database:   database,
        collection: collection,
    }, nil
}

func (r *Repository) Close() error {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    return r.client.Disconnect(ctx)
}

func (r *Repository) Ping(ctx context.Context) error {
    return r.client.Ping(ctx, nil)
}

func (r *Repository) FindAll(ctx context.Context) ([]*model.Item, error) {
    cursor, err := r.collection.Find(ctx, bson.M{})
    if err != nil {
        return nil, err
    }
    defer cursor.Close(ctx)

    var items []*model.Item
    if err := cursor.All(ctx, &items); err != nil {
        return nil, err
    }

    return items, nil
}

func (r *Repository) FindByID(ctx context.Context, id string) (*model.Item, error) {
    objectID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return nil, err
    }

    var item model.Item
    err = r.collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&item)
    if err == mongo.ErrNoDocuments {
        return nil, nil
    }
    if err != nil {
        return nil, err
    }

    return &item, nil
}

func (r *Repository) Create(ctx context.Context, item *model.Item) error {
    item.ID = primitive.NewObjectID()
    item.CreatedAt = time.Now()
    item.UpdatedAt = time.Now()

    _, err := r.collection.InsertOne(ctx, item)
    return err
}

func (r *Repository) Update(ctx context.Context, item *model.Item) error {
    item.UpdatedAt = time.Now()

    filter := bson.M{"_id": item.ID}
    update := bson.M{"$set": item}

    _, err := r.collection.UpdateOne(ctx, filter, update)
    return err
}

func (r *Repository) Delete(ctx context.Context, id string) error {
    objectID, err := primitive.ObjectIDFromHex(id)
    if err != nil {
        return err
    }

    _, err = r.collection.DeleteOne(ctx, bson.M{"_id": objectID})
    return err
}
```

#### 6. Model (`internal/model/model.go`)

```go
package model

import (
    "time"

    "go.mongodb.org/mongo-driver/bson/primitive"
)

type Item struct {
    ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
    Name        string             `json:"name" bson:"name"`
    Description string             `json:"description" bson:"description"`
    CreatedAt   time.Time          `json:"created_at" bson:"created_at"`
    UpdatedAt   time.Time          `json:"updated_at" bson:"updated_at"`
}
```

---

## Development Workflow

### 1. Set Up Development Environment

```bash
# Navigate to your service
cd services/my-service

# Install dependencies
go mod download

# Copy environment file
cp .env.example .env

# Edit configuration
vim .env
```

### 2. Run Locally

```bash
# Start dependencies (from go-framework)
cd ../../go-framework
make start-deps

# Run your service
cd ../services/my-service
make run

# Or with hot reload
make dev
```

### 3. Make Changes

```bash
# Create a feature branch
git checkout -b feature/my-feature

# Make your changes
vim internal/service/service.go

# Run tests
make test

# Check code quality
make lint
```

### 4. Test Changes

```bash
# Unit tests
make test-unit

# Integration tests
make test-integration

# All tests
make test

# With coverage
make test-coverage
```

### 5. Build and Deploy

```bash
# Build binary
make build

# Build Docker image
make docker-build

# Run in Docker
make docker-run

# Push to registry
make docker-push
```

---

## Integration Checklist

When creating a new service, ensure you complete these steps:

### Development Phase

- [ ] Service generated with proper structure
- [ ] Configuration management implemented
- [ ] HTTP/gRPC endpoints defined
- [ ] Business logic implemented in service layer
- [ ] Data access implemented in repository layer
- [ ] Models and DTOs defined
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests written

### Infrastructure Phase

- [ ] Dockerfile created and tested
- [ ] docker-compose.yml updated (if needed)
- [ ] Environment variables documented in .env.example
- [ ] Health check endpoints implemented
- [ ] Readiness check endpoints implemented
- [ ] Prometheus metrics exposed
- [ ] Jaeger tracing integrated
- [ ] Database migrations created (if applicable)

### Documentation Phase

- [ ] README.md with service overview
- [ ] API documentation (Swagger/OpenAPI)
- [ ] Architecture decisions documented
- [ ] Configuration options documented
- [ ] Development setup instructions
- [ ] Deployment instructions
- [ ] Troubleshooting guide

### CI/CD Phase

- [ ] GitHub Actions workflow created
- [ ] Build process automated
- [ ] Tests run in CI
- [ ] Docker image build automated
- [ ] Deployment scripts created
- [ ] Rollback procedure documented

### Monitoring Phase

- [ ] Service registered in service discovery
- [ ] Monitoring dashboards created (Grafana)
- [ ] Alerts configured (Prometheus)
- [ ] Logging aggregation configured
- [ ] Tracing configured (Jaeger)
- [ ] Performance benchmarks established

### Security Phase

- [ ] Authentication implemented
- [ ] Authorization implemented
- [ ] Input validation
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] Rate limiting
- [ ] CORS configured
- [ ] Secrets management
- [ ] Security scan passed

---

## Best Practices

### Code Organization

1. **Follow Clean Architecture**
   - Keep layers separate
   - Dependencies point inward
   - Business logic independent of frameworks

2. **Use Dependency Injection**
   ```go
   // Good: Dependencies injected
   func NewService(repo Repository, cache Cache) *Service {
       return &Service{repo: repo, cache: cache}
   }

   // Bad: Direct instantiation
   func NewService() *Service {
       return &Service{repo: repository.New()}
   }
   ```

3. **Keep Functions Small**
   - One function, one responsibility
   - Maximum 50 lines per function
   - Extract complex logic

4. **Use Interfaces**
   ```go
   type Repository interface {
       Create(ctx context.Context, item *Item) error
       FindByID(ctx context.Context, id string) (*Item, error)
   }
   ```

### Error Handling

1. **Always Handle Errors**
   ```go
   // Good
   if err := doSomething(); err != nil {
       return fmt.Errorf("failed to do something: %w", err)
   }

   // Bad
   doSomething() // ignoring error
   ```

2. **Provide Context**
   ```go
   return fmt.Errorf("failed to fetch user %s: %w", userID, err)
   ```

3. **Use Custom Error Types**
   ```go
   type NotFoundError struct {
       Resource string
       ID       string
   }

   func (e *NotFoundError) Error() string {
       return fmt.Sprintf("%s with ID %s not found", e.Resource, e.ID)
   }
   ```

### Configuration

1. **Use Environment Variables**
   - Never hardcode configuration
   - Provide sensible defaults
   - Document all variables

2. **Validate Configuration**
   ```go
   func (c *Config) Validate() error {
       if c.Server.Port == "" {
           return errors.New("server port is required")
       }
       return nil
   }
   ```

### Testing

1. **Write Tests First (TDD)**
   - Define behavior with tests
   - Write minimal code to pass
   - Refactor

2. **Test Coverage Goals**
   - Minimum 80% overall
   - 100% for critical paths
   - All error cases

3. **Use Table-Driven Tests**
   ```go
   func TestCalculate(t *testing.T) {
       tests := []struct {
           name     string
           input    int
           expected int
       }{
           {"zero", 0, 0},
           {"positive", 5, 25},
           {"negative", -3, 9},
       }

       for _, tt := range tests {
           t.Run(tt.name, func(t *testing.T) {
               result := Calculate(tt.input)
               if result != tt.expected {
                   t.Errorf("got %d, want %d", result, tt.expected)
               }
           })
       }
   }
   ```

### API Design

1. **RESTful Conventions**
   - GET /items - List items
   - POST /items - Create item
   - GET /items/:id - Get item
   - PUT /items/:id - Update item
   - DELETE /items/:id - Delete item

2. **Versioning**
   - Use URL versioning: /api/v1/items
   - Plan for backward compatibility

3. **Standard Response Format**
   ```json
   {
       "data": {...},
       "error": null,
       "meta": {
           "timestamp": "2024-01-01T00:00:00Z",
           "request_id": "abc-123"
       }
   }
   ```

### Performance

1. **Use Context for Timeouts**
   ```go
   ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
   defer cancel()
   ```

2. **Cache Appropriately**
   - Cache expensive operations
   - Set appropriate TTLs
   - Handle cache misses

3. **Use Connection Pools**
   - Database connections
   - HTTP clients
   - gRPC connections

### Security

1. **Validate All Input**
   ```go
   func validateEmail(email string) error {
       if !emailRegex.MatchString(email) {
           return errors.New("invalid email format")
       }
       return nil
   }
   ```

2. **Sanitize Output**
   - Prevent XSS
   - Escape HTML
   - Validate JSON

3. **Use Prepared Statements**
   - Prevent SQL injection
   - Use parameterized queries

---

## Testing Your Service

### Unit Tests

```go
// service_test.go
package service

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

// Mock repository
type MockRepository struct {
    mock.Mock
}

func (m *MockRepository) FindByID(ctx context.Context, id string) (*Item, error) {
    args := m.Called(ctx, id)
    if args.Get(0) == nil {
        return nil, args.Error(1)
    }
    return args.Get(0).(*Item), args.Error(1)
}

func TestGetItem(t *testing.T) {
    // Setup
    mockRepo := new(MockRepository)
    svc := New(mockRepo, &config.Config{})

    expectedItem := &Item{ID: "123", Name: "Test"}
    mockRepo.On("FindByID", mock.Anything, "123").Return(expectedItem, nil)

    // Execute
    item, err := svc.GetItem(context.Background(), "123")

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, expectedItem, item)
    mockRepo.AssertExpectations(t)
}
```

### Integration Tests

```go
// integration_test.go
//go:build integration
// +build integration

package tests

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/vhvplatform/my-service/internal/repository"
)

func TestRepositoryIntegration(t *testing.T) {
    // Setup test database
    repo, cleanup := setupTestDB(t)
    defer cleanup()

    // Test create
    item := &Item{Name: "Test Item"}
    err := repo.Create(context.Background(), item)
    assert.NoError(t, err)
    assert.NotEmpty(t, item.ID)

    // Test find
    found, err := repo.FindByID(context.Background(), item.ID.Hex())
    assert.NoError(t, err)
    assert.Equal(t, item.Name, found.Name)
}
```

### End-to-End Tests

```bash
# e2e_test.sh
#!/bin/bash

# Start service
make docker-run &
SERVICE_PID=$!

# Wait for service to be ready
sleep 5

# Run tests
curl -X POST http://localhost:8080/api/v1/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","description":"E2E Test"}'

# Check response
RESPONSE=$(curl -s http://localhost:8080/api/v1/items)
echo "$RESPONSE" | grep -q "Test" || exit 1

# Cleanup
kill $SERVICE_PID
```

---

## Deployment

### Local Deployment

```bash
# Build and run with Docker Compose
docker-compose up -d

# Check logs
docker-compose logs -f my-service

# Stop
docker-compose down
```

### Kubernetes Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-service
  template:
    metadata:
      labels:
        app: my-service
    spec:
      containers:
      - name: my-service
        image: vhvplatform/my-service:latest
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        - name: DB_HOST
          value: "mongodb"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Check status
kubectl get pods -l app=my-service

# View logs
kubectl logs -f deployment/my-service
```

---

## Common Issues and Solutions

### Issue: Service won't start

**Symptoms:** Service fails immediately after starting

**Solutions:**
1. Check configuration
   ```bash
   cat .env
   ```
2. Verify dependencies are running
   ```bash
   docker ps
   ```
3. Check logs
   ```bash
   make logs
   ```

### Issue: Can't connect to database

**Symptoms:** "connection refused" or timeout errors

**Solutions:**
1. Verify database is running
   ```bash
   docker ps | grep mongo
   ```
2. Check connection string
3. Verify network connectivity
4. Check firewall rules

### Issue: Tests failing

**Symptoms:** Unit or integration tests fail

**Solutions:**
1. Run tests individually
   ```bash
   go test -v ./internal/service
   ```
2. Check test database
3. Review recent changes
4. Check for race conditions
   ```bash
   go test -race ./...
   ```

---

## Additional Resources

- [Go Best Practices](https://github.com/golang/go/wiki/CodeReviewComments)
- [Clean Architecture in Go](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Effective Go](https://golang.org/doc/effective_go)
- [Go Testing](https://golang.org/pkg/testing/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)

---

## Getting Help

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Review [EXAMPLES.md](EXAMPLES.md)
- Ask in team chat
- Create an issue on GitHub
- Check existing services for patterns

---

**Happy coding! 🚀**
