# VHV Platform Startup Scripts

## Quick Start

### Windows (Recommended)

**Option 1: Batch Script**
```bash
cd e:\NewFrameWork\go-framework
start-all-services.bat
```

**Option 2: PowerShell Script**
```powershell
cd e:\NewFrameWork\go-framework
.\start-all-services.ps1
```

### Linux/Mac

```bash
cd e:\NewFrameWork\go-framework
chmod +x start-all-services.sh
./start-all-services.sh
```

## What Gets Started

1. **Auth Service** - Port 50051 (gRPC), 8081 (HTTP)
2. **Tenant Service** - Port 50053 (gRPC), 8083 (HTTP)
3. **User Service** - Port 50052 (gRPC), 8082 (HTTP)
4. **API Gateway** - Port 8080 (HTTP)
5. **React Frontend** - Port 3000 (HTTP)

## After Starting

Wait ~30 seconds for all services to initialize, then:

1. Open browser: `http://localhost:3000`
2. Login with test credentials (if exists)
3. Test User CRUD functionality

## Stopping Services

### Windows Batch/PowerShell
- Close each terminal window manually
- Or use Task Manager to kill `go.exe` processes

### Linux/Mac (tmux)
```bash
tmux kill-session -t vhv-platform
```

## Troubleshooting

### Port Already in Use
```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8080 | xargs kill -9
```

### Service Won't Start
1. Check `.env` file exists in each service
2. Verify MongoDB/Redis connectivity
3. Check logs in service terminal

## Manual Start (Alternative)

If scripts don't work, start manually in separate terminals:

```bash
# Terminal 1
cd e:\NewFrameWork\go-auth-service\server
go run cmd/main.go

# Terminal 2
cd e:\NewFrameWork\go-tenant-service\server
go run cmd/main.go

# Terminal 3
cd e:\NewFrameWork\go-user-service\server
go run cmd/main.go

# Terminal 4
cd e:\NewFrameWork\go-api-gateway\server
go run cmd/main.go

# Terminal 5
cd e:\NewFrameWork\go-user-service\client_bak
pnpm dev
```
