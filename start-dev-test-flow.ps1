# VHV Platform - Start Development Test Environment
# This script starts all services in the correct order for testing
# Usage: .\start-dev-test-flow.ps1

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   VHV PLATFORM - DEV TEST FLOW" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# PRE-FLIGHT CHECKS
# ========================================
Write-Host "Running pre-flight checks..." -ForegroundColor Yellow

# Check MongoDB connection
Write-Host "  • Checking MongoDB..." -ForegroundColor Gray
$testMongo = mongosh "mongodb://colombo:SASSMongoDB%232627@192.168.1.203:27017/?authSource=admin" --eval "db.adminCommand('ping')" --quiet 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "    ❌ Cannot connect to MongoDB" -ForegroundColor Red
    Write-Host "    Please check network/credentials" -ForegroundColor Yellow
    exit 1
}
Write-Host "    ✓ MongoDB connected" -ForegroundColor Green

# Check if ports are available
$ports = @(8080, 8081, 8082, 8083, 3000, 50051, 50052, 50053)
$portsInUse = @()
foreach ($port in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        $portsInUse += $port
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host "  ⚠ Warning: Ports already in use: $($portsInUse -join ', ')" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 0
    }
}

Write-Host ""

# ========================================
# SEED DATA
# ========================================
$loadSeed = Read-Host "Load seed data? (recommended for first run) (y/N)"
if ($loadSeed -eq "y" -or $loadSeed -eq "Y") {
    Write-Host ""
    Write-Host "Loading seed data..." -ForegroundColor Yellow
    & "e:\Go\go-framework\scripts\load-seed-data.ps1"
    Write-Host ""
    Start-Sleep -Seconds 2
}

# ========================================
# START SERVICES
# ========================================
Write-Host "Starting services in correct order..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C in any service window to stop that service" -ForegroundColor Gray
Write-Host ""

# 1. Auth Service (critical - must start first)
Write-Host "[1/5] Starting Auth Service..." -ForegroundColor Cyan
Write-Host "      gRPC: 50051, HTTP: 8081" -ForegroundColor Gray
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd e:\Go\go-auth-service\server; Write-Host 'AUTH SERVICE' -ForegroundColor Green; go run cmd/main.go"
) -WindowStyle Normal
Start-Sleep -Seconds 6

# 2. Tenant Service
Write-Host "[2/5] Starting Tenant Service..." -ForegroundColor Cyan
Write-Host "      gRPC: 50053, HTTP: 8083" -ForegroundColor Gray
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd e:\Go\go-tenant-service; Write-Host 'TENANT SERVICE' -ForegroundColor Green; go run cmd/tenant/main.go"
) -WindowStyle Normal
Start-Sleep -Seconds 6

# 3. User Service
Write-Host "[3/5] Starting User Service..." -ForegroundColor Cyan
Write-Host "      gRPC: 50052, HTTP: 8082" -ForegroundColor Gray
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd e:\Go\go-user-service; Write-Host 'USER SERVICE' -ForegroundColor Green; go run cmd/main.go"
) -WindowStyle Normal
Start-Sleep -Seconds 6

# 4. API Gateway (needs all backend services)
Write-Host "[4/5] Starting API Gateway..." -ForegroundColor Cyan
Write-Host "      HTTP: 8080" -ForegroundColor Gray
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd e:\Go\go-api-gateway; Write-Host 'API GATEWAY' -ForegroundColor Green; go run cmd/main.go"
) -WindowStyle Normal
Start-Sleep -Seconds 6

# 5. React Frontend (needs gateway)
Write-Host "[5/5] Starting React Frontend..." -ForegroundColor Cyan
Write-Host "      HTTP: 3000" -ForegroundColor Gray
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd e:\ReactJS\react-user-service; Write-Host 'REACT FRONTEND' -ForegroundColor Green; npm run dev"
) -WindowStyle Normal

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "   ALL SERVICES STARTED" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Services are starting in separate windows..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Service Endpoints:" -ForegroundColor Cyan
Write-Host "  • API Gateway:     http://localhost:8080" -ForegroundColor White
Write-Host "  • React UI:        http://localhost:3000" -ForegroundColor White
Write-Host "  • Auth Service:    http://localhost:8081 (gRPC: 50051)" -ForegroundColor Gray
Write-Host "  • User Service:    http://localhost:8082 (gRPC: 50052)" -ForegroundColor Gray
Write-Host "  • Tenant Service:  http://localhost:8083 (gRPC: 50053)" -ForegroundColor Gray
Write-Host ""
Write-Host "Test Credentials:" -ForegroundColor Cyan
Write-Host "  Email:    admin@test.com" -ForegroundColor White
Write-Host "  Password: Admin@123" -ForegroundColor White
Write-Host "  Tenant:   default-tenant" -ForegroundColor White
Write-Host ""
Write-Host "API Routing Examples:" -ForegroundColor Cyan
Write-Host "  Login:       POST http://localhost:8080/api/auth/login" -ForegroundColor Gray
Write-Host "  List Users:  GET  http://localhost:8080/api/user/v1/users" -ForegroundColor Gray
Write-Host "  Get Tenant:  GET  http://localhost:8080/api/tenant/v1/info" -ForegroundColor Gray
Write-Host ""
Write-Host "⏳ Wait ~30-40 seconds for all services to be fully ready..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Then open browser: " -NoNewline -ForegroundColor Yellow
Write-Host "http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to close this window (services will keep running)..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
