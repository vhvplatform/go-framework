#!/bin/bash
#
# Script: install-deps.sh
# Description: Install system dependencies required for development
# Usage: ./install-deps.sh
#
# This script automatically detects your operating system (macOS, Linux, Windows/WSL2)
# and installs the required development tools:
#   - Docker Desktop
#   - Go 1.21+
#   - kubectl (Kubernetes CLI)
#   - Helm (Package manager for Kubernetes)
#   - Protocol Buffers compiler
#   - jq (JSON processor)
#   - hey (HTTP load testing tool)
#
# Supported Platforms:
#   - macOS (Intel and Apple Silicon)
#   - Linux (Ubuntu, Debian, Fedora, RHEL)
#   - Windows (via WSL2)
#
# Examples:
#   ./install-deps.sh
#   make setup  # Runs this script as part of setup
#
# Notes:
#   - Requires internet connection
#   - May require sudo privileges on Linux
#   - On macOS, requires Homebrew (will be installed if missing)
#   - On Windows, must be run inside WSL2
#
# Author: VHV Corp
# Last Modified: 2024-01-15
#

set -e

echo "📦 Installing dependencies..."

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    CYGWIN*|MINGW*|MSYS*)    MACHINE=Windows;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "Detected OS: ${MACHINE}"

if [ "${MACHINE}" = "Mac" ]; then
    echo "Installing dependencies for macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "✅ Homebrew already installed"
    fi
    
    # Install tools
    echo "Installing development tools..."
    brew install go || echo "Go already installed"
    brew install docker || echo "Docker already installed"
    brew install kubectl || echo "kubectl already installed"
    brew install helm || echo "Helm already installed"
    brew install protobuf || echo "protobuf already installed"
    brew install jq || echo "jq already installed"
    brew install hey || echo "hey already installed"
    
    # Check if Docker Desktop is running
    if ! docker info &> /dev/null; then
        echo "⚠️  Docker is not running. Please start Docker Desktop."
        echo "   Download from: https://www.docker.com/products/docker-desktop"
    else
        echo "✅ Docker is running"
    fi
    
elif [ "${MACHINE}" = "Linux" ]; then
    echo "Installing dependencies for Linux..."
    
    # Update package list
    sudo apt-get update
    
    # Install basic tools
    echo "Installing basic tools..."
    sudo apt-get install -y git make curl wget unzip jq
    
    # Install Go
    if ! command -v go &> /dev/null; then
        echo "Installing Go..."
        GO_VERSION="1.21.5"
        wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
        rm "go${GO_VERSION}.linux-amd64.tar.gz"
        
        # Add to PATH
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin
        echo "✅ Go installed"
    else
        echo "✅ Go already installed"
    fi
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        echo "⚠️  You need to log out and back in for Docker permissions to take effect"
        echo "✅ Docker installed"
    else
        echo "✅ Docker already installed"
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        DOCKER_COMPOSE_VERSION="v2.23.3"
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "✅ Docker Compose installed"
    else
        echo "✅ Docker Compose already installed"
    fi
    
    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        echo "✅ kubectl installed"
    else
        echo "✅ kubectl already installed"
    fi
    
    # Install Helm
    if ! command -v helm &> /dev/null; then
        echo "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        echo "✅ Helm installed"
    else
        echo "✅ Helm already installed"
    fi
    
    # Install protobuf
    if ! command -v protoc &> /dev/null; then
        echo "Installing protobuf..."
        PROTOC_VERSION="21.12"
        PROTOC_ZIP="protoc-${PROTOC_VERSION}-linux-x86_64.zip"
        curl -OL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}"
        sudo unzip -o ${PROTOC_ZIP} -d /usr/local bin/protoc
        sudo unzip -o ${PROTOC_ZIP} -d /usr/local 'include/*'
        rm -f ${PROTOC_ZIP}
        echo "✅ protobuf installed"
    else
        echo "✅ protobuf already installed"
    fi
    
    # Install hey (load testing tool)
    if ! command -v hey &> /dev/null; then
        echo "Installing hey..."
        go install github.com/rakyll/hey@latest
        echo "✅ hey installed"
    else
        echo "✅ hey already installed"
    fi
    
elif [ "${MACHINE}" = "Windows" ]; then
    echo "For Windows, please use the PowerShell setup scripts:"
    echo "  .\scripts\setup\install-deps.ps1"
    exit 1
else
    echo "❌ Unsupported operating system: ${MACHINE}"
    exit 1
fi

echo ""
echo "✅ Dependencies installed successfully!"
echo ""
echo "Installed versions:"
echo "  Go:      $(go version)"
echo "  Docker:  $(docker --version)"
echo "  kubectl: $(kubectl version --client --short 2>/dev/null || echo 'Not available')"
echo "  Helm:    $(helm version --short 2>/dev/null || echo 'Not available')"
echo "  protoc:  $(protoc --version 2>/dev/null || echo 'Not available')"
echo ""
