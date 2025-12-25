#!/bin/bash
#
# Script: create-service.sh
# Description: Generate a new microservice with complete boilerplate code
# Usage: ./create-service.sh <service-name> [OPTIONS]
#
# Arguments:
#   $1 - Service name (required, e.g., "user-service")
#
# Options:
#   --port PORT              HTTP server port (default: 8080)
#   --grpc-port PORT         gRPC server port (default: 9090)
#   --database TYPE          Database type: mongodb, postgres, none (default: mongodb)
#   --with-grpc              Include gRPC server
#   --with-messaging         Include RabbitMQ messaging
#   --with-cache             Include Redis caching (default: true)
#   --no-cache               Skip Redis caching
#   --no-tests               Skip test file generation
#   --output DIR             Output directory (default: ../services)
#   -h, --help               Show this help message
#
# Examples:
#   # Basic service with MongoDB
#   ./create-service.sh user-service
#
#   # Service with custom port
#   ./create-service.sh user-service --port 8085
#
#   # Full-featured service with gRPC and messaging
#   ./create-service.sh user-service --with-grpc --with-messaging
#
#   # Service with PostgreSQL
#   ./create-service.sh user-service --database postgres
#
#   # Minimal service without database
#   ./create-service.sh user-service --database none --no-cache --no-tests
#
# Environment Variables:
#   GO_MODULE_PREFIX - Go module prefix (default: github.com/vhvcorp)
#
# Requirements:
#   - Go 1.21+ installed
#   - Git for initializing repository
#
# Author: VHV Corp
# See Also:
#   - docs/NEW_SERVICE_GUIDE.md: Complete guide for developing services
#   - docs/DEVELOPMENT.md: Development standards and practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PORT="8080"
GRPC_PORT="9090"
DATABASE="mongodb"
WITH_GRPC=false
WITH_MESSAGING=false
WITH_CACHE=true
WITH_TESTS=true
OUTPUT_DIR="../services"
GO_MODULE_PREFIX="${GO_MODULE_PREFIX:-github.com/vhvcorp}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: ./create-service.sh <service-name> [OPTIONS]

Generate a new microservice with complete boilerplate code.

Arguments:
  service-name              Name of the service (e.g., "user-service")

Options:
  --port PORT               HTTP server port (default: 8080)
  --grpc-port PORT          gRPC server port (default: 9090)
  --database TYPE           Database: mongodb, postgres, none (default: mongodb)
  --with-grpc               Include gRPC server
  --with-messaging          Include RabbitMQ messaging
  --with-cache              Include Redis caching (default: true)
  --no-cache                Skip Redis caching
  --no-tests                Skip test file generation
  --output DIR              Output directory (default: ../services)
  -h, --help                Show this help message

Examples:
  # Basic service with MongoDB
  ./create-service.sh user-service

  # Service with gRPC and messaging
  ./create-service.sh user-service --with-grpc --with-messaging

  # Service with PostgreSQL on custom port
  ./create-service.sh user-service --database postgres --port 8085

For more information, see docs/NEW_SERVICE_GUIDE.md
EOF
}

# Parse arguments
if [ $# -eq 0 ]; then
    print_error "Service name is required"
    show_usage
    exit 1
fi

SERVICE_NAME=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --grpc-port)
            GRPC_PORT="$2"
            shift 2
            ;;
        --database)
            DATABASE="$2"
            if [[ ! "$DATABASE" =~ ^(mongodb|postgres|none)$ ]]; then
                print_error "Invalid database type: $DATABASE (must be mongodb, postgres, or none)"
                exit 1
            fi
            shift 2
            ;;
        --with-grpc)
            WITH_GRPC=true
            shift
            ;;
        --with-messaging)
            WITH_MESSAGING=true
            shift
            ;;
        --with-cache)
            WITH_CACHE=true
            shift
            ;;
        --no-cache)
            WITH_CACHE=false
            shift
            ;;
        --no-tests)
            WITH_TESTS=false
            shift
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$SERVICE_NAME" ]; then
                SERVICE_NAME="$1"
            else
                print_error "Unexpected argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$SERVICE_NAME" ]; then
    print_error "Service name is required"
    show_usage
    exit 1
fi

# Validate service name
if [[ ! "$SERVICE_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    print_error "Invalid service name. Use lowercase letters, numbers, and hyphens only."
    exit 1
fi

# Paths
SERVICE_DIR="${OUTPUT_DIR}/${SERVICE_NAME}"
MODULE_PATH="${GO_MODULE_PREFIX}/${SERVICE_NAME}"

# Check if service already exists
if [ -d "$SERVICE_DIR" ]; then
    print_error "Service directory already exists: $SERVICE_DIR"
    exit 1
fi

# Check prerequisites
if ! command -v go &> /dev/null; then
    print_error "Go is not installed. Please install Go 1.21+ first."
    exit 1
fi

print_header "Creating Service: $SERVICE_NAME"

print_info "Configuration:"
echo "  Service Name: $SERVICE_NAME"
echo "  Module Path: $MODULE_PATH"
echo "  HTTP Port: $PORT"
echo "  gRPC Port: $GRPC_PORT"
echo "  Database: $DATABASE"
echo "  With gRPC: $WITH_GRPC"
echo "  With Messaging: $WITH_MESSAGING"
echo "  With Cache: $WITH_CACHE"
echo "  With Tests: $WITH_TESTS"
echo "  Output Directory: $SERVICE_DIR"
echo ""

# Create directory structure
print_info "Creating directory structure..."
mkdir -p "$SERVICE_DIR"/{cmd/server,internal/{config,handler,service,repository,model},pkg/client,api/proto,migrations,tests/{unit,integration},docker,configs,scripts}

print_success "Directories created"

# Initialize Go module
print_info "Initializing Go module..."
cd "$SERVICE_DIR"
go mod init "$MODULE_PATH"
print_success "Go module initialized"

# Create main.go
print_info "Generating main.go..."
cat > cmd/server/main.go << 'EOF'
package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"__MODULE_PATH__/internal/config"
	"__MODULE_PATH__/internal/handler"
	"__MODULE_PATH__/internal/repository"
	"__MODULE_PATH__/internal/service"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	log.Printf("Starting __SERVICE_NAME__ service on port %s", cfg.Server.Port)

	// Initialize repository
	repo, err := repository.New(cfg)
	if err != nil {
		log.Fatalf("Failed to create repository: %v", err)
	}
	defer repo.Close()

	// Initialize service
	svc := service.New(repo, cfg)

	// Initialize HTTP handler
	httpHandler := handler.NewHTTP(svc, cfg)

	// Start server in goroutine
	serverErrors := make(chan error, 1)
	go func() {
		log.Printf("HTTP server listening on :%s", cfg.Server.Port)
		serverErrors <- httpHandler.Start()
	}()

	// Wait for shutdown signal
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		log.Fatalf("Server error: %v", err)
	case sig := <-shutdown:
		log.Printf("Received signal %v, starting graceful shutdown", sig)

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := httpHandler.Shutdown(ctx); err != nil {
			log.Printf("Graceful shutdown failed: %v", err)
			if err := httpHandler.Close(); err != nil {
				log.Fatalf("Force shutdown failed: %v", err)
			}
		}

		log.Println("Server stopped gracefully")
	}
}
EOF
sed -i.bak "s|__MODULE_PATH__|$MODULE_PATH|g" cmd/server/main.go
sed -i.bak "s|__SERVICE_NAME__|$SERVICE_NAME|g" cmd/server/main.go
rm cmd/server/main.go.bak
print_success "main.go created"

# Create config.go
print_info "Generating config.go..."
cat > internal/config/config.go << 'EOF'
package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Server        ServerConfig
	Database      DatabaseConfig
	Redis         RedisConfig
	RabbitMQ      RabbitMQConfig
	Observability ObservabilityConfig
}

type ServerConfig struct {
	Port     string
	GRPCPort string
	Env      string
}

type DatabaseConfig struct {
	Type     string
	Host     string
	Port     int
	Database string
	Username string
	Password string
}

type RedisConfig struct {
	Enabled  bool
	Host     string
	Port     int
	Password string
	DB       int
}

type RabbitMQConfig struct {
	Enabled  bool
	URL      string
	Exchange string
	Queue    string
}

type ObservabilityConfig struct {
	PrometheusPort string
	JaegerEndpoint string
}

func Load() (*Config, error) {
	// Load .env file if exists (ignore error if not found)
	_ = godotenv.Load()

	cfg := &Config{
		Server: ServerConfig{
			Port:     getEnv("PORT", "__PORT__"),
			GRPCPort: getEnv("GRPC_PORT", "__GRPC_PORT__"),
			Env:      getEnv("ENV", "development"),
		},
		Database: DatabaseConfig{
			Type:     getEnv("DB_TYPE", "__DATABASE__"),
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnvAsInt("DB_PORT", __DB_PORT__),
			Database: getEnv("DB_NAME", "__SERVICE_NAME__"),
			Username: getEnv("DB_USER", ""),
			Password: getEnv("DB_PASSWORD", ""),
		},
		Redis: RedisConfig{
			Enabled:  getEnvAsBool("REDIS_ENABLED", __WITH_CACHE__),
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnvAsInt("REDIS_PORT", 6379),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		RabbitMQ: RabbitMQConfig{
			Enabled:  getEnvAsBool("RABBITMQ_ENABLED", __WITH_MESSAGING__),
			URL:      getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
			Exchange: getEnv("RABBITMQ_EXCHANGE", "events"),
			Queue:    getEnv("RABBITMQ_QUEUE", "__SERVICE_NAME__-queue"),
		},
		Observability: ObservabilityConfig{
			PrometheusPort: getEnv("PROMETHEUS_PORT", "2112"),
			JaegerEndpoint: getEnv("JAEGER_ENDPOINT", "http://localhost:14268/api/traces"),
		},
	}

	return cfg, cfg.Validate()
}

func (c *Config) Validate() error {
	if c.Server.Port == "" {
		return fmt.Errorf("server port is required")
	}
	if c.Database.Type != "none" && c.Database.Host == "" {
		return fmt.Errorf("database host is required")
	}
	return nil
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

func getEnvAsBool(key string, defaultValue bool) bool {
	valueStr := os.Getenv(key)
	if value, err := strconv.ParseBool(valueStr); err == nil {
		return value
	}
	return defaultValue
}
EOF

# Replace placeholders in config
DB_PORT="27017"
if [ "$DATABASE" == "postgres" ]; then
    DB_PORT="5432"
fi
sed -i.bak "s|__PORT__|$PORT|g" internal/config/config.go
sed -i.bak "s|__GRPC_PORT__|$GRPC_PORT|g" internal/config/config.go
sed -i.bak "s|__DATABASE__|$DATABASE|g" internal/config/config.go
sed -i.bak "s|__DB_PORT__|$DB_PORT|g" internal/config/config.go
sed -i.bak "s|__SERVICE_NAME__|$SERVICE_NAME|g" internal/config/config.go
sed -i.bak "s|__WITH_CACHE__|$WITH_CACHE|g" internal/config/config.go
sed -i.bak "s|__WITH_MESSAGING__|$WITH_MESSAGING|g" internal/config/config.go
rm internal/config/config.go.bak
print_success "config.go created"

# Create HTTP handler
print_info "Generating handler/http.go..."
cat > internal/handler/http.go << 'EOF'
package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"__MODULE_PATH__/internal/config"
	"__MODULE_PATH__/internal/service"
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

	// CRUD endpoints
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
	if h.server != nil {
		return h.server.Shutdown(ctx)
	}
	return nil
}

func (h *HTTPHandler) Close() error {
	if h.server != nil {
		return h.server.Close()
	}
	return nil
}

// Health check endpoint
func (h *HTTPHandler) healthCheck(w http.ResponseWriter, r *http.Request) {
	h.jsonResponse(w, map[string]string{
		"status":  "healthy",
		"service": "__SERVICE_NAME__",
	}, http.StatusOK)
}

// Readiness check endpoint
func (h *HTTPHandler) readinessCheck(w http.ResponseWriter, r *http.Request) {
	if err := h.service.CheckDependencies(r.Context()); err != nil {
		h.jsonResponse(w, map[string]string{
			"status": "not ready",
			"error":  err.Error(),
		}, http.StatusServiceUnavailable)
		return
	}

	h.jsonResponse(w, map[string]string{
		"status": "ready",
	}, http.StatusOK)
}

// CRUD endpoints
func (h *HTTPHandler) listItems(w http.ResponseWriter, r *http.Request) {
	items, err := h.service.ListItems(r.Context())
	if err != nil {
		h.errorResponse(w, err, http.StatusInternalServerError)
		return
	}

	h.jsonResponse(w, items, http.StatusOK)
}

func (h *HTTPHandler) createItem(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.errorResponse(w, fmt.Errorf("invalid request body"), http.StatusBadRequest)
		return
	}

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
		h.errorResponse(w, fmt.Errorf("invalid request body"), http.StatusBadRequest)
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
	if err := json.NewEncoder(w).Encode(data); err != nil {
		log.Printf("Failed to encode response: %v", err)
	}
}

func (h *HTTPHandler) errorResponse(w http.ResponseWriter, err error, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{
		"error": err.Error(),
	})
}
EOF
sed -i.bak "s|__MODULE_PATH__|$MODULE_PATH|g" internal/handler/http.go
sed -i.bak "s|__SERVICE_NAME__|$SERVICE_NAME|g" internal/handler/http.go
rm internal/handler/http.go.bak
print_success "handler/http.go created"

# Create service layer
print_info "Generating service/service.go..."
cat > internal/service/service.go << 'EOF'
package service

import (
	"context"
	"errors"

	"__MODULE_PATH__/internal/config"
	"__MODULE_PATH__/internal/model"
	"__MODULE_PATH__/internal/repository"
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
EOF
sed -i.bak "s|__MODULE_PATH__|$MODULE_PATH|g" internal/service/service.go
rm internal/service/service.go.bak
print_success "service/service.go created"

# Create repository layer based on database type
print_info "Generating repository/repository.go..."
if [ "$DATABASE" == "mongodb" ]; then
    cat > internal/repository/repository.go << 'EOF'
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"__MODULE_PATH__/internal/config"
	"__MODULE_PATH__/internal/model"
)

type Repository struct {
	client     *mongo.Client
	database   *mongo.Database
	collection *mongo.Collection
}

func New(cfg *config.Config) (*Repository, error) {
	if cfg.Database.Type == "none" {
		return &Repository{}, nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Build connection string
	uri := fmt.Sprintf("mongodb://%s:%d", cfg.Database.Host, cfg.Database.Port)
	if cfg.Database.Username != "" {
		uri = fmt.Sprintf("mongodb://%s:%s@%s:%d",
			cfg.Database.Username, cfg.Database.Password,
			cfg.Database.Host, cfg.Database.Port)
	}

	// Connect to MongoDB
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to MongoDB: %w", err)
	}

	// Ping database
	if err := client.Ping(ctx, nil); err != nil {
		return nil, fmt.Errorf("failed to ping MongoDB: %w", err)
	}

	database := client.Database(cfg.Database.Database)
	collection := database.Collection("items")

	return &Repository{
		client:     client,
		database:   database,
		collection: collection,
	}, nil
}

func (r *Repository) Close() error {
	if r.client == nil {
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return r.client.Disconnect(ctx)
}

func (r *Repository) Ping(ctx context.Context) error {
	if r.client == nil {
		return nil
	}
	return r.client.Ping(ctx, nil)
}

func (r *Repository) FindAll(ctx context.Context) ([]*model.Item, error) {
	if r.collection == nil {
		return []*model.Item{}, nil
	}

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
	if r.collection == nil {
		return nil, fmt.Errorf("database not configured")
	}

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
	if r.collection == nil {
		return fmt.Errorf("database not configured")
	}

	item.ID = primitive.NewObjectID()
	item.CreatedAt = time.Now()
	item.UpdatedAt = time.Now()

	_, err := r.collection.InsertOne(ctx, item)
	return err
}

func (r *Repository) Update(ctx context.Context, item *model.Item) error {
	if r.collection == nil {
		return fmt.Errorf("database not configured")
	}

	item.UpdatedAt = time.Now()

	filter := bson.M{"_id": item.ID}
	update := bson.M{"$set": item}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	return err
}

func (r *Repository) Delete(ctx context.Context, id string) error {
	if r.collection == nil {
		return fmt.Errorf("database not configured")
	}

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}

	_, err = r.collection.DeleteOne(ctx, bson.M{"_id": objectID})
	return err
}
EOF
elif [ "$DATABASE" == "postgres" ]; then
    cat > internal/repository/repository.go << 'EOF'
package repository

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"

	"__MODULE_PATH__/internal/config"
	"__MODULE_PATH__/internal/model"
)

type Repository struct {
	db *sql.DB
}

func New(cfg *config.Config) (*Repository, error) {
	if cfg.Database.Type == "none" {
		return &Repository{}, nil
	}

	// Build connection string
	connStr := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		cfg.Database.Host, cfg.Database.Port,
		cfg.Database.Username, cfg.Database.Password,
		cfg.Database.Database)

	// Connect to PostgreSQL
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to PostgreSQL: %w", err)
	}

	// Ping database
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping PostgreSQL: %w", err)
	}

	return &Repository{db: db}, nil
}

func (r *Repository) Close() error {
	if r.db == nil {
		return nil
	}
	return r.db.Close()
}

func (r *Repository) Ping(ctx context.Context) error {
	if r.db == nil {
		return nil
	}
	return r.db.PingContext(ctx)
}

func (r *Repository) FindAll(ctx context.Context) ([]*model.Item, error) {
	if r.db == nil {
		return []*model.Item{}, nil
	}

	rows, err := r.db.QueryContext(ctx, "SELECT id, name, description, created_at, updated_at FROM items")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*model.Item
	for rows.Next() {
		var item model.Item
		if err := rows.Scan(&item.ID, &item.Name, &item.Description, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		items = append(items, &item)
	}

	return items, nil
}

func (r *Repository) FindByID(ctx context.Context, id string) (*model.Item, error) {
	if r.db == nil {
		return nil, fmt.Errorf("database not configured")
	}

	var item model.Item
	err := r.db.QueryRowContext(ctx,
		"SELECT id, name, description, created_at, updated_at FROM items WHERE id = $1", id).
		Scan(&item.ID, &item.Name, &item.Description, &item.CreatedAt, &item.UpdatedAt)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	return &item, nil
}

func (r *Repository) Create(ctx context.Context, item *model.Item) error {
	if r.db == nil {
		return fmt.Errorf("database not configured")
	}

	now := time.Now()
	item.CreatedAt = now
	item.UpdatedAt = now

	err := r.db.QueryRowContext(ctx,
		"INSERT INTO items (name, description, created_at, updated_at) VALUES ($1, $2, $3, $4) RETURNING id",
		item.Name, item.Description, item.CreatedAt, item.UpdatedAt).Scan(&item.ID)

	return err
}

func (r *Repository) Update(ctx context.Context, item *model.Item) error {
	if r.db == nil {
		return fmt.Errorf("database not configured")
	}

	item.UpdatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		"UPDATE items SET name = $1, description = $2, updated_at = $3 WHERE id = $4",
		item.Name, item.Description, item.UpdatedAt, item.ID)

	return err
}

func (r *Repository) Delete(ctx context.Context, id string) error {
	if r.db == nil {
		return fmt.Errorf("database not configured")
	}

	_, err := r.db.ExecContext(ctx, "DELETE FROM items WHERE id = $1", id)
	return err
}
EOF
else
    # No database
    cat > internal/repository/repository.go << 'EOF'
package repository

import (
	"context"
	"fmt"
	"sync"

	"__MODULE_PATH__/internal/config"
	"__MODULE_PATH__/internal/model"
)

type Repository struct {
	items map[string]*model.Item
	mu    sync.RWMutex
}

func New(cfg *config.Config) (*Repository, error) {
	return &Repository{
		items: make(map[string]*model.Item),
	}, nil
}

func (r *Repository) Close() error {
	return nil
}

func (r *Repository) Ping(ctx context.Context) error {
	return nil
}

func (r *Repository) FindAll(ctx context.Context) ([]*model.Item, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	items := make([]*model.Item, 0, len(r.items))
	for _, item := range r.items {
		items = append(items, item)
	}

	return items, nil
}

func (r *Repository) FindByID(ctx context.Context, id string) (*model.Item, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	item, ok := r.items[id]
	if !ok {
		return nil, nil
	}

	return item, nil
}

func (r *Repository) Create(ctx context.Context, item *model.Item) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	item.ID = fmt.Sprintf("item-%d", len(r.items)+1)
	r.items[item.ID] = item

	return nil
}

func (r *Repository) Update(ctx context.Context, item *model.Item) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, ok := r.items[item.ID]; !ok {
		return fmt.Errorf("item not found")
	}

	r.items[item.ID] = item
	return nil
}

func (r *Repository) Delete(ctx context.Context, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	delete(r.items, id)
	return nil
}
EOF
fi
sed -i.bak "s|__MODULE_PATH__|$MODULE_PATH|g" internal/repository/repository.go
rm internal/repository/repository.go.bak
print_success "repository/repository.go created"

# Create model
print_info "Generating model/model.go..."
if [ "$DATABASE" == "mongodb" ]; then
    cat > internal/model/model.go << 'EOF'
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
EOF
elif [ "$DATABASE" == "postgres" ]; then
    cat > internal/model/model.go << 'EOF'
package model

import "time"

type Item struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
EOF
else
    cat > internal/model/model.go << 'EOF'
package model

import "time"

type Item struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
EOF
fi
print_success "model/model.go created"

# Create Dockerfile
print_info "Generating Dockerfile..."
cat > docker/Dockerfile << 'EOF'
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app/server ./cmd/server

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/server .

# Expose port
EXPOSE __PORT__

# Run the binary
CMD ["./server"]
EOF
sed -i.bak "s|__PORT__|$PORT|g" docker/Dockerfile
rm docker/Dockerfile.bak
print_success "Dockerfile created"

# Create .env.example
print_info "Generating .env.example..."
cat > .env.example << EOF
# Server Configuration
PORT=$PORT
GRPC_PORT=$GRPC_PORT
ENV=development

# Database Configuration
DB_TYPE=$DATABASE
DB_HOST=localhost
DB_PORT=$DB_PORT
DB_NAME=$SERVICE_NAME
DB_USER=
DB_PASSWORD=

# Redis Configuration
REDIS_ENABLED=$WITH_CACHE
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# RabbitMQ Configuration
RABBITMQ_ENABLED=$WITH_MESSAGING
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
RABBITMQ_EXCHANGE=events
RABBITMQ_QUEUE=${SERVICE_NAME}-queue

# Observability
PROMETHEUS_PORT=2112
JAEGER_ENDPOINT=http://localhost:14268/api/traces
EOF
print_success ".env.example created"

# Create Makefile
print_info "Generating Makefile..."
cat > Makefile << 'EOF'
.PHONY: help build run test docker-build docker-run clean

SERVICE_NAME=__SERVICE_NAME__
DOCKER_IMAGE=vhvcorp/$(SERVICE_NAME)
PORT=__PORT__

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the application
	go build -o bin/server cmd/server/main.go

run: ## Run the application
	go run cmd/server/main.go

dev: ## Run with hot reload (requires air)
	air

test: ## Run all tests
	go test -v ./...

test-unit: ## Run unit tests
	go test -v ./internal/...

test-integration: ## Run integration tests
	go test -v -tags=integration ./tests/integration/...

test-coverage: ## Run tests with coverage
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

lint: ## Run linter
	golangci-lint run

docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE):latest -f docker/Dockerfile .

docker-run: ## Run Docker container
	docker run -p $(PORT):$(PORT) --env-file .env $(DOCKER_IMAGE):latest

docker-push: ## Push Docker image
	docker push $(DOCKER_IMAGE):latest

clean: ## Clean build artifacts
	rm -rf bin/
	rm -f coverage.out coverage.html

deps: ## Download dependencies
	go mod download
	go mod tidy

.DEFAULT_GOAL := help
EOF
sed -i.bak "s|__SERVICE_NAME__|$SERVICE_NAME|g" Makefile
sed -i.bak "s|__PORT__|$PORT|g" Makefile
rm Makefile.bak
print_success "Makefile created"

# Create README
print_info "Generating README.md..."
cat > README.md << EOF
# $SERVICE_NAME

Microservice for the VHV Corp platform.

## Overview

This service provides [describe your service functionality here].

## Features

- RESTful API endpoints
- Health check and readiness probes
- Prometheus metrics
- Jaeger tracing support
$([ "$DATABASE" != "none" ] && echo "- $DATABASE database integration")
$([ "$WITH_CACHE" == "true" ] && echo "- Redis caching")
$([ "$WITH_MESSAGING" == "true" ] && echo "- RabbitMQ messaging")
$([ "$WITH_GRPC" == "true" ] && echo "- gRPC support")

## Prerequisites

- Go 1.21+
- Docker and Docker Compose
$([ "$DATABASE" == "mongodb" ] && echo "- MongoDB 5.0+")
$([ "$DATABASE" == "postgres" ] && echo "- PostgreSQL 13+")
$([ "$WITH_CACHE" == "true" ] && echo "- Redis 6.0+")
$([ "$WITH_MESSAGING" == "true" ] && echo "- RabbitMQ 3.9+")

## Getting Started

### Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/vhvcorp/$SERVICE_NAME.git
cd $SERVICE_NAME

# Install dependencies
make deps

# Copy environment file
cp .env.example .env

# Edit configuration
vim .env
\`\`\`

### Running Locally

\`\`\`bash
# Run the service
make run

# Or with hot reload
make dev
\`\`\`

The service will be available at http://localhost:$PORT

### Running with Docker

\`\`\`bash
# Build Docker image
make docker-build

# Run container
make docker-run
\`\`\`

## API Endpoints

### Health Checks

- \`GET /health\` - Health check
- \`GET /ready\` - Readiness check
- \`GET /metrics\` - Prometheus metrics

### API v1

- \`GET /api/v1/items\` - List all items
- \`POST /api/v1/items\` - Create new item
- \`GET /api/v1/items/:id\` - Get item by ID
- \`PUT /api/v1/items/:id\` - Update item
- \`DELETE /api/v1/items/:id\` - Delete item

## Development

### Project Structure

\`\`\`
$SERVICE_NAME/
├── cmd/server/          # Application entry point
├── internal/            # Private application code
│   ├── config/         # Configuration management
│   ├── handler/        # HTTP/gRPC handlers
│   ├── service/        # Business logic
│   ├── repository/     # Data access layer
│   └── model/          # Data models
├── pkg/                # Public libraries
├── tests/              # Test files
├── docker/             # Docker configuration
├── configs/            # Configuration files
└── scripts/            # Utility scripts
\`\`\`

### Running Tests

\`\`\`bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests
make test-integration

# Generate coverage report
make test-coverage
\`\`\`

### Code Quality

\`\`\`bash
# Run linter
make lint

# Format code
gofmt -w .
\`\`\`

## Configuration

Configuration is managed through environment variables. See \`.env.example\` for all available options.

Key configuration variables:

- \`PORT\` - HTTP server port (default: $PORT)
$([ "$DATABASE" != "none" ] && echo "- \`DB_HOST\` - Database host")
$([ "$WITH_CACHE" == "true" ] && echo "- \`REDIS_HOST\` - Redis host")
$([ "$WITH_MESSAGING" == "true" ] && echo "- \`RABBITMQ_URL\` - RabbitMQ connection URL")

## Deployment

### Docker Compose

\`\`\`bash
docker-compose up -d
\`\`\`

### Kubernetes

\`\`\`bash
kubectl apply -f k8s/
\`\`\`

## Monitoring

- **Metrics**: Available at \`http://localhost:$PORT/metrics\`
- **Health**: Available at \`http://localhost:$PORT/health\`
- **Readiness**: Available at \`http://localhost:$PORT/ready\`

## Contributing

1. Fork the repository
2. Create your feature branch (\`git checkout -b feature/amazing-feature\`)
3. Commit your changes (\`git commit -m 'Add amazing feature'\`)
4. Push to the branch (\`git push origin feature/amazing-feature\`)
5. Open a Pull Request

See [CONTRIBUTING.md](https://github.com/vhvcorp/go-devtools/blob/main/CONTRIBUTING.md) for more details.

## License

Copyright © 2024 VHV Corp. All rights reserved.

## Support

For support and questions:
- Documentation: https://github.com/vhvcorp/go-devtools
- Issues: https://github.com/vhvcorp/$SERVICE_NAME/issues
EOF
print_success "README.md created"

# Install dependencies
print_info "Installing Go dependencies..."
go get github.com/gorilla/mux
go get github.com/joho/godotenv
go get github.com/prometheus/client_golang/prometheus/promhttp

if [ "$DATABASE" == "mongodb" ]; then
    go get go.mongodb.org/mongo-driver/mongo
    go get go.mongodb.org/mongo-driver/bson
elif [ "$DATABASE" == "postgres" ]; then
    go get github.com/lib/pq
fi

if [ "$WITH_TESTS" == "true" ]; then
    go get github.com/stretchr/testify
fi

go mod tidy
print_success "Dependencies installed"

# Create test files if requested
if [ "$WITH_TESTS" == "true" ]; then
    print_info "Generating test files..."
    
    cat > tests/unit/service_test.go << 'EOF'
package unit

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestServiceExample(t *testing.T) {
	ctx := context.Background()
	
	// Add your test here
	assert.NotNil(t, ctx)
}
EOF

    cat > tests/integration/integration_test.go << 'EOF'
//go:build integration
// +build integration

package integration

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestIntegrationExample(t *testing.T) {
	// Add your integration test here
	assert.True(t, true)
}
EOF

    print_success "Test files created"
fi

# Create .gitignore
print_info "Generating .gitignore..."
cat > .gitignore << 'EOF'
# Binaries
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test artifacts
*.test
*.out
coverage.html
coverage.out

# Environment files
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Dependencies
vendor/

# Build artifacts
dist/
build/

# Air (hot reload)
tmp/
EOF
print_success ".gitignore created"

# Initialize git repository
print_info "Initializing git repository..."
git init
git add .
git commit -m "Initial commit: Generated $SERVICE_NAME boilerplate"
print_success "Git repository initialized"

# Print summary
print_header "Service Created Successfully!"

echo -e "${GREEN}Service: $SERVICE_NAME${NC}"
echo -e "${GREEN}Location: $SERVICE_DIR${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Navigate to service directory:"
echo -e "     ${BLUE}cd $SERVICE_DIR${NC}"
echo ""
echo "  2. Review and update configuration:"
echo -e "     ${BLUE}cp .env.example .env${NC}"
echo -e "     ${BLUE}vim .env${NC}"
echo ""
echo "  3. Run the service:"
echo -e "     ${BLUE}make run${NC}"
echo ""
echo "  4. Test the service:"
echo -e "     ${BLUE}curl http://localhost:$PORT/health${NC}"
echo ""
echo "  5. Build Docker image:"
echo -e "     ${BLUE}make docker-build${NC}"
echo ""
echo "For complete documentation, see:"
echo -e "  ${BLUE}docs/NEW_SERVICE_GUIDE.md${NC}"
echo ""

print_success "All done! Happy coding! 🚀"
