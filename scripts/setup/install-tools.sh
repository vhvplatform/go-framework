#!/bin/bash
set -e

echo "🔧 Installing development tools..."

# Ensure GOPATH is set
if [ -z "$GOPATH" ]; then
    export GOPATH=$(go env GOPATH)
fi

# Ensure GOPATH/bin is in PATH
if [[ ":$PATH:" != *":$GOPATH/bin:"* ]]; then
    export PATH=$PATH:$GOPATH/bin
fi

echo "GOPATH: $GOPATH"
echo ""

# Go tools for protocol buffers
echo "📦 Installing Protocol Buffer tools..."
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
echo "✅ Protocol Buffer tools installed"

# Linting tools
echo "📦 Installing linting tools..."
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
echo "✅ Linting tools installed"

# Hot reload tool
echo "📦 Installing hot reload tool (air)..."
go install github.com/cosmtrek/air@latest
echo "✅ Air installed"

# Mock generation tool
echo "📦 Installing mock generation tool..."
go install go.uber.org/mock/mockgen@latest
echo "✅ Mock generation tool installed"

# Code generation tools
echo "📦 Installing additional tools..."
go install github.com/golang/mock/mockgen@latest || echo "Note: golang/mock is deprecated, using uber mock instead"
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/swaggo/swag/cmd/swag@latest  # For API documentation
echo "✅ Additional tools installed"

# Load testing tool
echo "📦 Installing load testing tool (hey)..."
go install github.com/rakyll/hey@latest
echo "✅ hey installed"

# Database tools (optional but useful)
echo "📦 Installing database tools..."
go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest || echo "⚠️  migrate installation failed (optional)"
echo "✅ Database tools installed"

echo ""
echo "✅ All development tools installed successfully!"
echo ""
echo "Installed tools:"
echo "  protoc-gen-go:        $(which protoc-gen-go 2>/dev/null || echo 'Not in PATH')"
echo "  protoc-gen-go-grpc:   $(which protoc-gen-go-grpc 2>/dev/null || echo 'Not in PATH')"
echo "  golangci-lint:        $(which golangci-lint 2>/dev/null || echo 'Not in PATH')"
echo "  air:                  $(which air 2>/dev/null || echo 'Not in PATH')"
echo "  mockgen:              $(which mockgen 2>/dev/null || echo 'Not in PATH')"
echo "  goimports:            $(which goimports 2>/dev/null || echo 'Not in PATH')"
echo "  swag:                 $(which swag 2>/dev/null || echo 'Not in PATH')"
echo "  hey:                  $(which hey 2>/dev/null || echo 'Not in PATH')"
echo ""
echo "Make sure $GOPATH/bin is in your PATH:"
echo "  export PATH=\$PATH:\$GOPATH/bin"
echo ""
