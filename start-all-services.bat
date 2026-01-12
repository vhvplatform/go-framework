@echo off
REM Start All Services Script for VHV Platform (Windows)
REM Usage: start-all-services.bat

echo === VHV Platform - Starting All Services ===
echo.

REM Start Auth Service
echo [1/5] Starting Auth Service...
start "Auth Service" cmd /k "cd /d e:\Go\go-auth-service\server && go run cmd/main.go"
timeout /t 3 /nobreak >nul

REM Start Tenant Service
echo [2/5] Starting Tenant Service...
start "Tenant Service" cmd /k "cd /d e:\Go\go-tenant-service && go run cmd/tenant/main.go"
timeout /t 3 /nobreak >nul

REM Start User Service
echo [3/5] Starting User Service...
start "User Service" cmd /k "cd /d e:\Go\go-user-service && go run cmd/main.go"
timeout /t 3 /nobreak >nul

REM Start API Gateway
echo [4/5] Starting API Gateway...
start "API Gateway" cmd /k "cd /d e:\Go\go-api-gateway && go run cmd/main.go"
timeout /t 3 /nobreak >nul

REM Start React Frontend
echo [5/5] Starting React Frontend...
start "React Frontend" cmd /k "cd /d e:\ReactJS\react-user-service && npm run dev"

echo.
echo === All services started in separate windows ===
echo.
echo Services:
echo   - Auth Service      (gRPC: 50051, HTTP: 8081)
echo   - Tenant Service    (gRPC: 50053, HTTP: 8083)
echo   - User Service      (gRPC: 50052, HTTP: 8082)
echo   - API Gateway       (HTTP: 8080)
echo   - React Frontend    (HTTP: 3000)
echo.
echo Wait for all services to start (about 30 seconds)
echo Then open browser: http://localhost:3000
echo.
pause
