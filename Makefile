.PHONY: help setup start stop restart logs clean

# Colors for output
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
CYAN   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RED    := $(shell tput -Txterm setaf 1)
RESET  := $(shell tput -Txterm sgr0)

# Workspace directory
WORKSPACE_DIR ?= $(HOME)/workspace/go-platform

help: ## Show this help
	@echo ''
	@echo '${CYAN}SaaS Platform - Developer Tools${RESET}'
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "  ${YELLOW}%-25s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)

## Setup Commands
setup: ## Setup complete development environment
	@echo "${GREEN}🚀 Setting up development environment...${RESET}"
	@./server/scripts/setup/install-deps.sh
	@./server/scripts/setup/clone-repos.sh
	@./server/scripts/setup/install-tools.sh
	@./server/scripts/setup/init-workspace.sh
	@echo "${GREEN}✅ Setup complete!${RESET}"

setup-tools: ## Install development tools only
	@echo "${GREEN}🔧 Installing development tools...${RESET}"
	@./server/scripts/setup/install-tools.sh

setup-repos: ## Clone all service repositories
	@echo "${GREEN}📂 Cloning repositories...${RESET}"
	@./server/scripts/setup/clone-repos.sh

setup-env: ## Setup environment variables
	@echo "${GREEN}⚙️  Setting up environment...${RESET}"
	@cd server/docker && cp .env.example .env
	@echo "${YELLOW}Please edit server/docker/.env with your configuration${RESET}"

## Development Commands
create-service: ## Create new service (SERVICE=name, see docs/development/NEW_SERVICE_GUIDE.md)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${RED}❌ Error: SERVICE variable required${RESET}"; \
		echo "Usage: make create-service SERVICE=my-service"; \
		echo ""; \
		echo "Options:"; \
		echo "  PORT=8080              HTTP port"; \
		echo "  DATABASE=mongodb       Database type (mongodb/postgres/none)"; \
		echo "  WITH_GRPC=true         Include gRPC"; \
		echo "  WITH_MESSAGING=true    Include RabbitMQ"; \
		echo ""; \
		echo "Example:"; \
		echo "  make create-service SERVICE=user-service PORT=8085 DATABASE=mongodb"; \
		exit 1; \
	fi
	@ARGS="$(SERVICE)"; \
	[ -n "$(PORT)" ] && ARGS="$$ARGS --port $(PORT)"; \
	[ -n "$(DATABASE)" ] && ARGS="$$ARGS --database $(DATABASE)"; \
	[ "$(WITH_GRPC)" = "true" ] && ARGS="$$ARGS --with-grpc"; \
	[ "$(WITH_MESSAGING)" = "true" ] && ARGS="$$ARGS --with-messaging"; \
	./server/scripts/dev/create-service.sh $$ARGS

start: ## Start all services
	@echo "${GREEN}🚀 Starting all services...${RESET}"
	@cd server/docker && docker compose up -d
	@./server/scripts/dev/wait-for-services.sh
	@echo "${GREEN}✅ All services started!${RESET}"
	@make status

start-dev: ## Start with development overrides (hot-reload)
	@echo "${GREEN}🚀 Starting services in development mode...${RESET}"
	@cd server/docker && docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
	@./server/scripts/dev/wait-for-services.sh
	@echo "${GREEN}✅ Development environment started!${RESET}"

start-observability: ## Start only observability stack
	@echo "${GREEN}📊 Starting observability stack...${RESET}"
	@cd server/docker && docker compose up -d prometheus grafana jaeger
	@echo "${GREEN}✅ Observability stack started!${RESET}"

stop: ## Stop all services
	@echo "${YELLOW}⏸️  Stopping all services...${RESET}"
	@cd server/docker && docker compose down
	@echo "${GREEN}✅ All services stopped!${RESET}"

stop-keep-data: ## Stop services but keep data volumes
	@echo "${YELLOW}⏸️  Stopping services (keeping data)...${RESET}"
	@cd server/docker && docker compose stop
	@echo "${GREEN}✅ Services stopped!${RESET}"

restart: stop start ## Restart all services

restart-service: ## Restart specific service (SERVICE=name)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${RED}❌ Error: SERVICE variable required${RESET}"; \
		echo "Usage: make restart-service SERVICE=auth-service"; \
		exit 1; \
	fi
	@./server/scripts/dev/restart-service.sh $(SERVICE)

rebuild: ## Rebuild and restart specific service (SERVICE=name)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${RED}❌ Error: SERVICE variable required${RESET}"; \
		echo "Usage: make rebuild SERVICE=auth-service"; \
		exit 1; \
	fi
	@./server/scripts/dev/rebuild.sh $(SERVICE)

logs: ## View logs from all services
	@cd server/docker && docker compose logs -f

logs-service: ## View logs from specific service (SERVICE=name)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${RED}❌ Error: SERVICE variable required${RESET}"; \
		echo "Usage: make logs-service SERVICE=auth-service"; \
		exit 1; \
	fi
	@cd server/docker && docker compose logs -f $(SERVICE)

shell: ## Access service shell (SERVICE=name)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${RED}❌ Error: SERVICE variable required${RESET}"; \
		echo "Usage: make shell SERVICE=auth-service"; \
		exit 1; \
	fi
	@./server/scripts/dev/shell.sh $(SERVICE)

status: ## Check status of all services
	@./server/scripts/utilities/check-health.sh

ps: ## Show running containers
	@cd server/docker && docker compose ps

## Database Commands
db-seed: ## Seed database with test data
	@echo "${GREEN}🌱 Seeding database...${RESET}"
	@./server/scripts/database/seed.sh

db-reset: ## Reset database (WARNING: deletes all data)
	@echo "${RED}⚠️  WARNING: This will delete all data!${RESET}"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		./server/scripts/database/reset.sh; \
	else \
		echo "${YELLOW}Cancelled.${RESET}"; \
	fi

db-backup: ## Backup database
	@echo "${GREEN}💾 Backing up database...${RESET}"
	@./server/scripts/database/backup.sh

db-restore: ## Restore database from backup (FILE=path)
	@if [ -z "$(FILE)" ]; then \
		echo "${RED}❌ Error: FILE variable required${RESET}"; \
		echo "Usage: make db-restore FILE=backup.tar.gz"; \
		exit 1; \
	fi
	@./server/scripts/database/restore.sh $(FILE)

db-migrate: ## Run database migrations
	@echo "${GREEN}🔄 Running migrations...${RESET}"
	@./server/scripts/database/migrate.sh

## Testing Commands
test: ## Run all tests
	@echo "${GREEN}🧪 Running all tests...${RESET}"
	@./server/scripts/testing/run-unit-tests.sh
	@./server/scripts/testing/run-integration-tests.sh

test-unit: ## Run unit tests
	@echo "${GREEN}🧪 Running unit tests...${RESET}"
	@./server/scripts/testing/run-unit-tests.sh

test-integration: ## Run integration tests
	@echo "${GREEN}🧪 Running integration tests...${RESET}"
	@./server/scripts/testing/run-integration-tests.sh

test-e2e: ## Run end-to-end tests
	@echo "${GREEN}🧪 Running E2E tests...${RESET}"
	@./server/scripts/testing/run-e2e-tests.sh

test-load: ## Run load tests
	@echo "${GREEN}🧪 Running load tests...${RESET}"
	@./server/scripts/testing/run-load-tests.sh

test-data: ## Generate test data
	@echo "${GREEN}📊 Generating test data...${RESET}"
	@./server/scripts/testing/generate-test-data.sh

## Build Commands
build: ## Build all services
	@echo "${GREEN}🔨 Building all services...${RESET}"
	@./server/scripts/build/build-all.sh

build-service: ## Build specific service (SERVICE=name)
	@if [ -z "$(SERVICE)" ]; then \
		echo "${RED}❌ Error: SERVICE variable required${RESET}"; \
		echo "Usage: make build-service SERVICE=auth-service"; \
		exit 1; \
	fi
	@./server/scripts/build/build-service.sh $(SERVICE)

docker-build: ## Build all Docker images
	@echo "${GREEN}🐳 Building Docker images...${RESET}"
	@./server/scripts/build/docker-build-all.sh

docker-push: ## Push all Docker images
	@echo "${GREEN}🐳 Pushing Docker images...${RESET}"
	@./server/scripts/build/docker-push-all.sh

## Deployment Commands
deploy-local: ## Deploy to local Kubernetes
	@echo "${GREEN}☸️  Deploying to local Kubernetes...${RESET}"
	@./server/scripts/deployment/deploy-local.sh

deploy-dev: ## Deploy to development environment
	@echo "${GREEN}☸️  Deploying to development...${RESET}"
	@./server/scripts/deployment/deploy-dev.sh

port-forward: ## Setup port forwarding to K8s services
	@echo "${GREEN}🔌 Setting up port forwarding...${RESET}"
	@./server/scripts/deployment/port-forward.sh

tunnel: ## Create tunnel to cluster
	@echo "${GREEN}🔌 Creating tunnel...${RESET}"
	@./server/scripts/deployment/tunnel.sh

## Monitoring Commands
open-grafana: ## Open Grafana dashboard
	@./server/scripts/monitoring/open-grafana.sh

open-prometheus: ## Open Prometheus dashboard
	@./server/scripts/monitoring/open-prometheus.sh

open-jaeger: ## Open Jaeger UI
	@./server/scripts/monitoring/open-jaeger.sh

open-rabbitmq: ## Open RabbitMQ Management UI
	@echo "${GREEN}🐰 Opening RabbitMQ Management UI...${RESET}"
	@open http://localhost:15672 || xdg-open http://localhost:15672 || echo "Open http://localhost:15672 in your browser"

tail-logs: ## Tail service logs in real-time
	@./server/scripts/monitoring/tail-logs.sh

## Utility Commands
clean: ## Clean up Docker resources
	@echo "${YELLOW}🧹 Cleaning up...${RESET}"
	@./server/scripts/utilities/cleanup.sh

clean-all: ## Clean everything including volumes (WARNING: deletes data)
	@echo "${RED}⚠️  WARNING: This will delete all data!${RESET}"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd server/docker && docker compose down -v; \
		echo "${GREEN}✅ Cleaned!${RESET}"; \
	else \
		echo "${YELLOW}Cancelled.${RESET}"; \
	fi

validate-env: ## Validate environment configuration
	@./server/scripts/utilities/validate-env.sh

generate-jwt: ## Generate JWT token for testing
	@./server/scripts/utilities/generate-jwt.sh

test-api: ## Test API endpoints
	@./server/scripts/utilities/test-api.sh

health: ## Quick health check of all services
	@echo "${GREEN}🏥 Health check...${RESET}"
	@curl -s http://localhost:8080/health | jq '.' || echo "API Gateway not responding"

version: ## Show tool versions
	@echo "${CYAN}Tool Versions:${RESET}"
	@echo "Docker:     $$(docker --version)"
	@echo "Go:         $$(go version)"
	@echo "kubectl:    $$(kubectl version --client --short 2>/dev/null || echo 'Not installed')"
	@echo "Helm:       $$(helm version --short 2>/dev/null || echo 'Not installed')"

info: ## Show service URLs
	@echo ""
	@echo "${CYAN}═══════════════════════════════════════════════════${RESET}"
	@echo "${GREEN}SaaS Platform - Service URLs${RESET}"
	@echo "${CYAN}═══════════════════════════════════════════════════${RESET}"
	@echo ""
	@echo "${YELLOW}Microservices:${RESET}"
	@echo "  API Gateway:         http://localhost:8080"
	@echo "  Auth Service:        http://localhost:8081 (gRPC: 50051)"
	@echo "  User Service:        http://localhost:8082 (gRPC: 50052)"
	@echo "  Tenant Service:      http://localhost:8083 (gRPC: 50053)"
	@echo "  Notification:        http://localhost:8084 (gRPC: 50054)"
	@echo "  System Config:       http://localhost:8085 (gRPC: 50055)"
	@echo ""
	@echo "${YELLOW}Infrastructure:${RESET}"
	@echo "  MongoDB:             mongodb://localhost:27017"
	@echo "  Redis:               redis://localhost:6379"
	@echo "  RabbitMQ:            amqp://localhost:5672"
	@echo "  RabbitMQ Management: http://localhost:15672 (guest/guest)"
	@echo ""
	@echo "${YELLOW}Observability:${RESET}"
	@echo "  Prometheus:          http://localhost:9090"
	@echo "  Grafana:             http://localhost:3000 (admin/admin)"
	@echo "  Jaeger:              http://localhost:16686"
	@echo ""
	@echo "${CYAN}═══════════════════════════════════════════════════${RESET}"
	@echo ""

.DEFAULT_GOAL := help

## CLI Tool
build-cli: ## Build developer CLI tool
	@echo "${GREEN}🔨 Building CLI tool...${RESET}"
	@cd tools/cli && go build -o ../../bin/saas .
	@echo "${GREEN}✅ CLI built: bin/saas${RESET}"
	@echo "${YELLOW}Tip: Install globally with 'sudo mv bin/saas /usr/local/bin/' (Linux/macOS)${RESET}"
	@echo "${YELLOW}Tip: On Windows, add 'bin' directory to PATH or copy saas.exe to a PATH location${RESET}"

install-cli: build-cli ## Build and install CLI tool
	@echo "${GREEN}📦 Installing CLI tool...${RESET}"
	@sudo cp bin/saas /usr/local/bin/
	@echo "${GREEN}✅ CLI installed to /usr/local/bin/saas${RESET}"
	@echo "${YELLOW}Usage: saas --help${RESET}"
