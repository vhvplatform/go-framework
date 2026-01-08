# Proto Code Generation Setup Guide

## Prerequisites

### 1. Install Protocol Buffers Compiler (protoc)

**Windows:**
1. Download the latest release from: https://github.com/protocolbuffers/protobuf/releases
2. Extract to a folder (e.g., `C:\protoc`)
3. Add `C:\protoc\bin` to your PATH environment variable
4. Verify: `protoc --version`

**Alternative - Using Chocolatey:**
```powershell
choco install protoc
```

**Alternative - Using Scoop:**
```powershell
scoop install protobuf
```

### 2. Install Go Proto Plugins

```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
```

Verify plugins are in your PATH (should be in `%GOPATH%\bin` or `%USERPROFILE%\go\bin`):
```bash
where protoc-gen-go
where protoc-gen-go-grpc
where protoc-gen-grpc-gateway
```

### 3. Setup googleapis

The scripts will automatically clone googleapis to `%GOPATH%\src\github.com\googleapis\googleapis`.

If GOPATH is not set, run:
```powershell
$env:GOPATH = "C:\Users\YourUsername\go"
[System.Environment]::SetEnvironmentVariable('GOPATH', $env:GOPATH, 'User')
```

## Generate Proto Code

### Option 1: Generate All Services (Windows Batch)
```cmd
cd go-framework\scripts
.\generate-proto.bat
```

### Option 2: Generate All Services (PowerShell)
```powershell
cd go-framework\scripts
.\generate-proto.ps1
```

### Option 3: Generate Individual Service
```cmd
cd go-auth-service\server\proto
make proto

# Or manually:
protoc -I. -I%GOPATH%\src\github.com\googleapis\googleapis ^
    --go_out=../internal/pb ^
    --go_opt=paths=source_relative ^
    --go-grpc_out=../internal/pb ^
    --go-grpc_opt=paths=source_relative ^
    --grpc-gateway_out=../internal/pb ^
    --grpc-gateway_opt=paths=source_relative ^
    --grpc-gateway_opt=logtostderr=true ^
    *.proto
```

## Verify Generated Files

After running the script, check for generated files in:
- `go-auth-service/server/internal/pb/*.pb.go`
- `go-user-service/server/internal/pb/*.pb.go`
- `go-tenant-service/server/internal/pb/*.pb.go`

Each service should have:
- `*.pb.go` - Protocol buffer message definitions
- `*_grpc.pb.go` - gRPC service definitions
- `*.pb.gw.go` - gRPC-Gateway HTTP bindings

## Troubleshooting

### Error: "protoc not found"
- Ensure protoc is installed and in your PATH
- Run: `where protoc` (should show the path)

### Error: "protoc-gen-go: program not found"
- Install Go plugins (see step 2 above)
- Ensure `%GOPATH%\bin` is in your PATH

### Error: "google/api/annotations.proto: File not found"
- Run the googleapis setup in the script
- Or manually clone: `git clone https://github.com/googleapis/googleapis.git %GOPATH%\src\github.com\googleapis\googleapis`

### Permission Denied (PowerShell)
- Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Or use the `.bat` file instead

## Next Steps

After generating proto code:
1. Update gRPC clients in `go-api-gateway/server/internal/client/` to use generated code
2. Implement gRPC servers in each service
3. Test gRPC endpoints
