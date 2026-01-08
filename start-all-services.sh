#!/bin/bash
# Start All Services Script for VHV Platform
# Usage: ./start-all-services.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== VHV Platform - Starting All Services ===${NC}"

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}tmux is not installed. Please install tmux first.${NC}"
    echo "Install: sudo apt-get install tmux (Linux) or brew install tmux (Mac)"
    exit 1
fi

# Kill existing tmux session if exists
tmux kill-session -t vhv-platform 2>/dev/null || true

# Create new tmux session
echo -e "${YELLOW}Creating tmux session 'vhv-platform'...${NC}"
tmux new-session -d -s vhv-platform -n auth-service

# Window 1: Auth Service
echo -e "${GREEN}[1/5] Starting Auth Service...${NC}"
tmux send-keys -t vhv-platform:auth-service "cd e:/NewFrameWork/go-auth-service/server && go run cmd/main.go" C-m

# Window 2: Tenant Service
echo -e "${GREEN}[2/5] Starting Tenant Service...${NC}"
tmux new-window -t vhv-platform -n tenant-service
tmux send-keys -t vhv-platform:tenant-service "cd e:/NewFrameWork/go-tenant-service/server && go run cmd/main.go" C-m

# Window 3: User Service
echo -e "${GREEN}[3/5] Starting User Service...${NC}"
tmux new-window -t vhv-platform -n user-service
tmux send-keys -t vhv-platform:user-service "cd e:/NewFrameWork/go-user-service/server && go run cmd/main.go" C-m

# Window 4: API Gateway
echo -e "${GREEN}[4/5] Starting API Gateway...${NC}"
tmux new-window -t vhv-platform -n api-gateway
tmux send-keys -t vhv-platform:api-gateway "cd e:/NewFrameWork/go-api-gateway/server && go run cmd/main.go" C-m

# Window 5: React Frontend
echo -e "${GREEN}[5/5] Starting React Frontend...${NC}"
tmux new-window -t vhv-platform -n react-frontend
tmux send-keys -t vhv-platform:react-frontend "cd e:/NewFrameWork/go-user-service/client && pnpm install && pnpm dev" C-m

echo -e "${GREEN}=== All services started in tmux session 'vhv-platform' ===${NC}"
echo -e "${YELLOW}To attach to the session: tmux attach -t vhv-platform${NC}"
echo -e "${YELLOW}To switch windows: Ctrl+B then window number (0-4)${NC}"
echo -e "${YELLOW}To detach: Ctrl+B then D${NC}"
echo -e "${YELLOW}To kill session: tmux kill-session -t vhv-platform${NC}"
echo ""
echo -e "${GREEN}Services:${NC}"
echo "  0: Auth Service      (gRPC: 50051, HTTP: 8081)"
echo "  1: Tenant Service    (gRPC: 50053, HTTP: 8083)"
echo "  2: User Service      (gRPC: 50052, HTTP: 8082)"
echo "  3: API Gateway       (HTTP: 8080)"
echo "  4: React Frontend    (HTTP: 3000)"
echo ""
echo -e "${GREEN}Attaching to session...${NC}"
tmux attach -t vhv-platform
