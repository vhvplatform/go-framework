# VHV Platform - Start All Services
# PowerShell Script
# Usage: .\start-all-services.ps1

Write-Host "=== VHV Platform - Starting All Services ===" -ForegroundColor Green
Write-Host ""

# Start Auth Service
Write-Host "[1/5] Starting Auth Service..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd e:\NewFrameWork\go-auth-service\server; go run cmd/main.go" -WindowStyle Normal
Start-Sleep -Seconds 3

# Start Tenant Service
Write-Host "[2/5] Starting Tenant Service..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd e:\NewFrameWork\go-tenant-service\server; go run cmd/main.go" -WindowStyle Normal
Start-Sleep -Seconds 3

# Start User Service
Write-Host "[3/5] Starting User Service..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd e:\NewFrameWork\go-user-service\server; go run cmd/main.go" -WindowStyle Normal
Start-Sleep -Seconds 3

# Start API Gateway
Write-Host "[4/5] Starting API Gateway..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd e:\NewFrameWork\go-api-gateway\server; go run cmd/main.go" -WindowStyle Normal
Start-Sleep -Seconds 3

# Start React Frontend
Write-Host "[5/5] Starting React Frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd e:\NewFrameWork\go-user-service\client; pnpm install; pnpm dev" -WindowStyle Normal

Write-Host ""
Write-Host "=== All services started in separate windows ===" -ForegroundColor Green
Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
Write-Host "  - Auth Service      (gRPC: 50051, HTTP: 8081)"
Write-Host "  - Tenant Service    (gRPC: 50053, HTTP: 8083)"
Write-Host "  - User Service      (gRPC: 50052, HTTP: 8082)"
Write-Host "  - API Gateway       (HTTP: 8080)"
Write-Host "  - React Frontend    (HTTP: 3000)"
Write-Host ""
Write-Host "Wait for all services to start (about 30 seconds)" -ForegroundColor Yellow
Write-Host "Then open browser: http://localhost:3000" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit this window..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
