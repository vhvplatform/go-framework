#!/bin/bash
#
# Script: interactive-setup.sh
# Description: Interactive setup script for go-framework development environment
# Usage: ./interactive-setup.sh [OPTIONS]
#
# Options:
#   --workspace PATH          Custom workspace directory (default: ~/workspace/go-platform)
#   --skip-docker-check       Skip Docker installation check
#   --skip-repos              Skip repository cloning
#   --skip-seed               Skip database seeding
#   --jwt-secret SECRET       Custom JWT secret
#   --quick                   Quick setup with defaults (no prompts)
#   --help                    Show this help message
#
# Examples:
#   ./interactive-setup.sh
#   ./interactive-setup.sh --workspace ~/my-workspace --quick
#   ./interactive-setup.sh --skip-repos --skip-seed
#
# Author: VHV Corp
# Last Modified: 2024-12-25
#

set -e
set -o pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Default values
WORKSPACE_DIR="$HOME/workspace/go-platform"
SKIP_DOCKER_CHECK=false
SKIP_REPOS=false
SKIP_SEED=false
JWT_SECRET=""
QUICK_MODE=false

# Start time for tracking
START_TIME=$(date +%s)

# Functions
print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}$1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_step() {
    echo -e "${BLUE}▶${NC} $*"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$QUICK_MODE" = true ]; then
        return 0
    fi
    
    local response
    if [ "$default" = "y" ]; then
        read -r -p "$prompt [Y/n] " response
        case "$response" in
            [nN][oO]|[nN]) return 1 ;;
            *) return 0 ;;
        esac
    else
        read -r -p "$prompt [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

show_help() {
    grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --skip-docker-check)
            SKIP_DOCKER_CHECK=true
            shift
            ;;
        --skip-repos)
            SKIP_REPOS=true
            shift
            ;;
        --skip-seed)
            SKIP_SEED=true
            shift
            ;;
        --jwt-secret)
            JWT_SECRET="$2"
            shift 2
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main script
main() {
    print_header "🚀 go-framework Interactive Setup"
    
    echo "This script will set up your complete development environment."
    echo "It will take approximately 10-15 minutes depending on your internet speed."
    echo ""
    
    if [ "$QUICK_MODE" = false ]; then
        if ! confirm "Do you want to continue?" y; then
            echo "Setup cancelled."
            exit 0
        fi
    fi
    
    # 1. Detect OS
    detect_os
    
    # 2. Check prerequisites
    check_prerequisites
    
    # 3. Setup workspace
    setup_workspace
    
    # 4. Install dependencies
    install_dependencies
    
    # 5. Clone repositories
    if [ "$SKIP_REPOS" = false ]; then
        clone_repositories
    else
        log_warning "Skipping repository cloning (--skip-repos flag)"
    fi
    
    # 6. Configure environment
    configure_environment
    
    # 7. Start services
    start_services
    
    # 8. Seed database
    if [ "$SKIP_SEED" = false ]; then
        seed_database
    else
        log_warning "Skipping database seeding (--skip-seed flag)"
    fi
    
    # 9. Verify installation
    verify_installation
    
    # 10. Show summary
    show_summary
}

detect_os() {
    print_header "1️⃣  System Detection"
    
    log_step "Detecting operating system..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        if [[ $(uname -m) == "arm64" ]]; then
            ARCH="Apple Silicon"
        else
            ARCH="Intel"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        if [ -f /etc/os-release ]; then
            DISTRO=$(. /etc/os-release && echo "$NAME")
        else
            DISTRO="Unknown"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="Windows"
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS="WSL2"
        fi
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    log_info "Operating System: $OS"
    [ -n "${ARCH:-}" ] && log_info "Architecture: $ARCH"
    [ -n "${DISTRO:-}" ] && log_info "Distribution: $DISTRO"
}

check_prerequisites() {
    print_header "2️⃣  Prerequisites Check"
    
    local missing_deps=()
    
    # Check Docker
    if [ "$SKIP_DOCKER_CHECK" = false ]; then
        log_step "Checking Docker..."
        if command -v docker &> /dev/null; then
            local docker_version=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
            log_info "Docker found: v$docker_version"
            
            # Check if Docker is running
            if ! docker info &> /dev/null; then
                log_warning "Docker is installed but not running"
                log_step "Starting Docker..."
                
                if [[ "$OS" == "macOS" ]]; then
                    open -a Docker
                    log_step "Waiting for Docker to start (this may take 30-60 seconds)..."
                    for i in {1..60}; do
                        if docker info &> /dev/null; then
                            log_info "Docker is now running"
                            break
                        fi
                        sleep 1
                        echo -n "."
                    done
                    echo ""
                else
                    log_error "Please start Docker manually and re-run this script"
                    exit 1
                fi
            else
                log_info "Docker is running"
            fi
        else
            log_warning "Docker not found"
            missing_deps+=("docker")
        fi
    else
        log_warning "Skipping Docker check (--skip-docker-check flag)"
    fi
    
    # Check Go
    log_step "Checking Go..."
    if command -v go &> /dev/null; then
        local go_version=$(go version | cut -d ' ' -f3 | sed 's/go//')
        local required_version="1.21"
        
        if [ "$(printf '%s\n' "$required_version" "$go_version" | sort -V | head -n1)" = "$required_version" ]; then
            log_info "Go found: v$go_version"
        else
            log_warning "Go version $go_version is older than required $required_version"
            missing_deps+=("go")
        fi
    else
        log_warning "Go not found"
        missing_deps+=("go")
    fi
    
    # Check Git
    log_step "Checking Git..."
    if command -v git &> /dev/null; then
        local git_version=$(git --version | cut -d ' ' -f3)
        log_info "Git found: v$git_version"
    else
        log_error "Git not found - required for installation"
        exit 1
    fi
    
    # If dependencies are missing, offer to install
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        log_warning "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Installation instructions:"
        
        for dep in "${missing_deps[@]}"; do
            case $dep in
                docker)
                    if [[ "$OS" == "macOS" ]]; then
                        echo "  Docker: brew install --cask docker"
                    elif [[ "$OS" == "Linux" ]]; then
                        echo "  Docker: https://docs.docker.com/engine/install/"
                    fi
                    ;;
                go)
                    if [[ "$OS" == "macOS" ]]; then
                        echo "  Go: brew install go"
                    elif [[ "$OS" == "Linux" ]]; then
                        echo "  Go: https://go.dev/doc/install"
                    fi
                    ;;
            esac
        done
        
        echo ""
        if confirm "Do you want to continue anyway?"; then
            log_warning "Continuing with missing dependencies..."
        else
            exit 1
        fi
    fi
}

setup_workspace() {
    print_header "3️⃣  Workspace Setup"
    
    # Prompt for workspace location if not in quick mode
    if [ "$QUICK_MODE" = false ]; then
        echo "Default workspace location: $WORKSPACE_DIR"
        if confirm "Use default location?"; then
            log_info "Using default workspace: $WORKSPACE_DIR"
        else
            read -r -p "Enter workspace path: " custom_workspace
            if [ -n "$custom_workspace" ]; then
                WORKSPACE_DIR="${custom_workspace/#\~/$HOME}"
            fi
        fi
    fi
    
    log_step "Creating workspace directory: $WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR/bin"
    mkdir -p "$WORKSPACE_DIR/logs"
    mkdir -p "$WORKSPACE_DIR/data"
    mkdir -p "$WORKSPACE_DIR/backups"
    
    log_info "Workspace created successfully"
}

install_dependencies() {
    print_header "4️⃣  Installing Dependencies"
    
    log_step "Installing system dependencies..."
    
    # Check and install jq
    if ! command -v jq &> /dev/null; then
        log_step "Installing jq..."
        if [[ "$OS" == "macOS" ]]; then
            brew install jq || log_warning "Failed to install jq"
        elif [[ "$OS" == "Linux" ]]; then
            sudo apt-get install -y jq || log_warning "Failed to install jq"
        fi
    else
        log_info "jq already installed"
    fi
    
    # Check and install kubectl
    if ! command -v kubectl &> /dev/null; then
        log_step "Installing kubectl..."
        if [[ "$OS" == "macOS" ]]; then
            brew install kubectl || log_warning "Failed to install kubectl"
        elif [[ "$OS" == "Linux" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
        fi
    else
        log_info "kubectl already installed"
    fi
    
    # Install Go tools
    if command -v go &> /dev/null; then
        log_step "Installing Go development tools..."
        
        go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
        go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        go install github.com/cosmtrek/air@latest
        go install github.com/golang/mock/mockgen@latest
        
        log_info "Go tools installed"
    else
        log_warning "Skipping Go tools (Go not installed)"
    fi
}

clone_repositories() {
    print_header "5️⃣  Cloning Repositories"
    
    local repos=(
        "go-shared-go"
        "go-api-gateway"
        "go-auth-service"
        "go-user-service"
        "go-tenant-service"
        "go-notification-service"
        "go-system-config-service"
        "go-infrastructure"
    )
    
    if [ "$QUICK_MODE" = false ]; then
        echo "Select repositories to clone:"
        echo "  1) All repositories (default)"
        echo "  2) Core services only (gateway + 3 services)"
        echo "  3) Custom selection"
        read -r -p "Enter choice [1]: " repo_choice
        repo_choice=${repo_choice:-1}
    else
        repo_choice=1
    fi
    
    case $repo_choice in
        2)
            repos=("go-shared-go" "go-api-gateway" "go-auth-service" "go-user-service")
            ;;
        3)
            # Custom selection logic
            local selected_repos=()
            for repo in "${repos[@]}"; do
                if confirm "Clone $repo?"; then
                    selected_repos+=("$repo")
                fi
            done
            repos=("${selected_repos[@]}")
            ;;
    esac
    
    log_step "Cloning ${#repos[@]} repositories..."
    
    for repo in "${repos[@]}"; do
        local repo_path="$WORKSPACE_DIR/$repo"
        if [ -d "$repo_path" ]; then
            log_warning "$repo already exists, skipping"
        else
            log_step "Cloning $repo..."
            if git clone "https://github.com/vhvcorp/$repo.git" "$repo_path" 2>/dev/null; then
                log_info "$repo cloned successfully"
            else
                log_error "Failed to clone $repo (repository may not exist yet)"
            fi
        fi
    done
}

configure_environment() {
    print_header "6️⃣  Environment Configuration"
    
    local env_file="$PWD/docker/.env"
    local env_example="$PWD/docker/.env.example"
    
    if [ -f "$env_file" ]; then
        log_warning ".env file already exists"
        if ! confirm "Overwrite existing .env file?"; then
            log_info "Keeping existing .env file"
            return
        fi
    fi
    
    if [ ! -f "$env_example" ]; then
        log_error ".env.example not found"
        return
    fi
    
    log_step "Creating .env file..."
    cp "$env_example" "$env_file"
    
    # Generate JWT secret if not provided
    if [ -z "$JWT_SECRET" ]; then
        log_step "Generating secure JWT secret..."
        if command -v openssl &> /dev/null; then
            JWT_SECRET=$(openssl rand -base64 32)
        else
            # Fallback: generate random string and base64 encode it
            JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 | base64 2>/dev/null || \
                        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        fi
    fi
    
    # Update .env file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" "$env_file"
    else
        sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" "$env_file"
    fi
    
    log_info ".env file configured"
    
    # Prompt for optional configurations
    if [ "$QUICK_MODE" = false ]; then
        echo ""
        if confirm "Do you want to configure SMTP settings for email notifications?"; then
            read -r -p "SMTP Host: " smtp_host
            read -r -p "SMTP Port [587]: " smtp_port
            smtp_port=${smtp_port:-587}
            read -r -p "SMTP Username: " smtp_user
            read -r -s -p "SMTP Password: " smtp_pass
            echo ""
            
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|SMTP_HOST=.*|SMTP_HOST=$smtp_host|" "$env_file"
                sed -i '' "s|SMTP_PORT=.*|SMTP_PORT=$smtp_port|" "$env_file"
                sed -i '' "s|SMTP_USERNAME=.*|SMTP_USERNAME=$smtp_user|" "$env_file"
                sed -i '' "s|SMTP_PASSWORD=.*|SMTP_PASSWORD=$smtp_pass|" "$env_file"
            else
                sed -i "s|SMTP_HOST=.*|SMTP_HOST=$smtp_host|" "$env_file"
                sed -i "s|SMTP_PORT=.*|SMTP_PORT=$smtp_port|" "$env_file"
                sed -i "s|SMTP_USERNAME=.*|SMTP_USERNAME=$smtp_user|" "$env_file"
                sed -i "s|SMTP_PASSWORD=.*|SMTP_PASSWORD=$smtp_pass|" "$env_file"
            fi
            
            log_info "SMTP settings configured"
        fi
    fi
}

start_services() {
    print_header "7️⃣  Starting Services"
    
    log_step "Pulling Docker images (this may take 5-10 minutes)..."
    cd docker
    docker-compose pull
    
    log_step "Starting Docker Compose services..."
    docker-compose up -d
    
    log_step "Waiting for services to be healthy (timeout: 5 minutes)..."
    local max_wait=300
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        if docker-compose ps | grep -q "Up (healthy)"; then
            log_info "Services are starting up..."
        fi
        
        # Check if all services are healthy
        local unhealthy=$(docker-compose ps | grep -c "unhealthy" || true)
        if [ "$unhealthy" -eq 0 ]; then
            log_info "All services are healthy!"
            cd ..
            return 0
        fi
        
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    
    echo ""
    log_warning "Some services may still be starting up"
    log_step "Check status with: make status"
    cd ..
}

seed_database() {
    print_header "8️⃣  Database Seeding"
    
    if [ "$QUICK_MODE" = false ]; then
        if ! confirm "Do you want to seed the database with test data?" y; then
            log_info "Skipping database seeding"
            return
        fi
    fi
    
    log_step "Loading test data..."
    
    # Wait a bit more for MongoDB to be fully ready
    sleep 5
    
    # Get the script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local seed_script="$script_dir/../database/seed.sh"
    
    if [ -f "$seed_script" ]; then
        "$seed_script" || log_warning "Database seeding failed (services may still be starting)"
    elif [ -f "./scripts/database/seed.sh" ]; then
        ./scripts/database/seed.sh || log_warning "Database seeding failed (services may still be starting)"
    else
        log_warning "Seed script not found"
    fi
}

verify_installation() {
    print_header "9️⃣  Verification"
    
    log_step "Running health checks..."
    
    # Check API Gateway
    local api_url="http://localhost:8080/health"
    log_step "Testing API Gateway..."
    
    for i in {1..30}; do
        if curl -sf "$api_url" > /dev/null 2>&1; then
            log_info "API Gateway is responding"
            break
        fi
        if [ $i -eq 30 ]; then
            log_warning "API Gateway not responding yet (may still be starting)"
        fi
        sleep 2
    done
    
    # Test authentication
    log_step "Testing authentication endpoint..."
    local login_response=$(curl -sf -X POST http://localhost:8080/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}' 2>/dev/null || echo "")
    
    if echo "$login_response" | grep -q "token"; then
        log_info "Authentication is working"
    else
        log_warning "Authentication test failed (may need more time to start)"
    fi
}

show_summary() {
    print_header "🎉 Setup Complete!"
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${GREEN}${BOLD}Installation completed successfully!${NC}"
    echo -e "Total time: ${minutes}m ${seconds}s"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BOLD}📍 Workspace Location:${NC}"
    echo "   $WORKSPACE_DIR"
    echo ""
    echo -e "${BOLD}🌐 Service URLs:${NC}"
    echo "   API Gateway:    http://localhost:8080"
    echo "   Grafana:        http://localhost:3000 (admin/admin)"
    echo "   Jaeger:         http://localhost:16686"
    echo "   RabbitMQ Mgmt:  http://localhost:15672 (guest/guest)"
    echo "   Prometheus:     http://localhost:9090"
    echo ""
    echo -e "${BOLD}🔑 Test Credentials:${NC}"
    echo "   Admin: admin@example.com / admin123"
    echo "   User:  user@example.com / user123"
    echo ""
    echo -e "${BOLD}⚡ Quick Commands:${NC}"
    echo "   make status         - Check service health"
    echo "   make logs           - View all service logs"
    echo "   make stop           - Stop all services"
    echo "   make start          - Start all services"
    echo "   make restart        - Restart all services"
    echo "   make open-grafana   - Open Grafana dashboard"
    echo "   make test-api       - Test API endpoints"
    echo ""
    echo -e "${BOLD}📚 Next Steps:${NC}"
    echo "   1. Open Grafana: make open-grafana"
    echo "   2. Import Postman collection from postman/ directory"
    echo "   3. Read documentation in docs/ directory"
    echo "   4. Try example API calls: make test-api"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Save summary to file
    local summary_file="$WORKSPACE_DIR/SETUP_SUMMARY.txt"
    cat > "$summary_file" << EOF
go-framework Setup Summary
=========================

Installation Date: $(date)
Duration: ${minutes}m ${seconds}s
Operating System: $OS

Workspace Location: $WORKSPACE_DIR

Service URLs:
- API Gateway:    http://localhost:8080
- Grafana:        http://localhost:3000 (admin/admin)
- Jaeger:         http://localhost:16686
- RabbitMQ Mgmt:  http://localhost:15672 (guest/guest)
- Prometheus:     http://localhost:9090

Test Credentials:
- Admin: admin@example.com / admin123
- User:  user@example.com / user123

Quick Commands:
- make status         - Check service health
- make logs           - View all service logs
- make stop           - Stop all services
- make start          - Start all services
- make restart        - Restart all services
- make open-grafana   - Open Grafana dashboard
- make test-api       - Test API endpoints

Documentation:
- README.md           - Overview and quick start
- docs/SETUP.md       - Detailed setup guide
- docs/TOOLS.md       - Tool reference
- docs/ARCHITECTURE.md - System architecture

Support:
- GitHub Issues: https://github.com/vhvcorp/go-framework/issues
- Documentation: https://github.com/vhvcorp/go-framework/tree/main/docs
EOF
    
    log_info "Setup summary saved to: $summary_file"
    echo ""
    echo "For help, visit: https://github.com/vhvcorp/go-framework"
    echo ""
}

# Run main function
main "$@"
