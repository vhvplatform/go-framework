#!/bin/bash
# Generate proto code for all services on Windows (PowerShell)

Write-Host "========================================"
Write-Host "Proto Code Generation for All Services"
Write-Host "========================================"
Write-Host ""

# Check if protoc is installed
if (-not (Get-Command protoc -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: protoc not found. Please install Protocol Buffers compiler." -ForegroundColor Red
    Write-Host "Download from: https://github.com/protocolbuffers/protobuf/releases"
    exit 1
}

# Check GOPATH
if ([string]::IsNullOrEmpty($env:GOPATH)) {
    Write-Host "ERROR: GOPATH not set" -ForegroundColor Red
    exit 1
}

Write-Host "Using GOPATH: $env:GOPATH"
Write-Host ""

# Create googleapis directory if not exists
$GOOGLEAPIS_DIR = Join-Path $env:GOPATH "src\github.com\googleapis\googleapis"
if (-not (Test-Path $GOOGLEAPIS_DIR)) {
    Write-Host "Setting up googleapis..."
    $googleapisParent = Join-Path $env:GOPATH "src\github.com\googleapis"
    New-Item -ItemType Directory -Force -Path $googleapisParent | Out-Null
    Push-Location $googleapisParent
    git clone https://github.com/googleapis/googleapis.git
    Pop-Location
}

# Install required tools
Write-Host "Installing proto generation tools..."
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
Write-Host ""

# Function to generate proto
function Generate-Proto {
    param(
        [string]$ServiceName,
        [string]$ProtoDir,
        [int]$Index,
        [int]$Total
    )
    
    Write-Host "[$Index/$Total] Generating proto for $ServiceName..."
    Push-Location $ProtoDir
    
    $outDir = Join-Path $ProtoDir "..\internal\pb"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    
    $protoFiles = Get-ChildItem -Filter "*.proto" | Select-Object -ExpandProperty Name
    
    protoc -I. -I"$GOOGLEAPIS_DIR" `
        --go_out=../internal/pb `
        --go_opt=paths=source_relative `
        --go-grpc_out=../internal/pb `
        --go-grpc_opt=paths=source_relative `
        --grpc-gateway_out=../internal/pb `
        --grpc-gateway_opt=paths=source_relative `
        --grpc-gateway_opt=logtostderr=true `
        $protoFiles
    
    Pop-Location
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $ServiceName proto generated" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to generate proto for $ServiceName" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host ""
}

# Generate proto for all services
Generate-Proto "auth-service" "go-auth-service\server\proto" 1 3
Generate-Proto "user-service" "go-user-service\server\proto" 2 3
Generate-Proto "tenant-service" "go-tenant-service\server\proto" 3 3

Write-Host "========================================"
Write-Host "Proto generation completed successfully!" -ForegroundColor Green
Write-Host "========================================"
Write-Host "Generated files are in: */server/internal/pb/"
Write-Host ""
