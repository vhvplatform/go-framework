@echo off
REM Generate proto code for all services on Windows

echo ========================================
echo Proto Code Generation for All Services
echo ========================================
echo.

REM Check if protoc is installed
where protoc >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: protoc not found. Please install Protocol Buffers compiler.
    echo Download from: https://github.com/protocolbuffers/protobuf/releases
    exit /b 1
)

REM Check GOPATH
if "%GOPATH%"=="" (
    echo ERROR: GOPATH not set
    exit /b 1
)

echo Using GOPATH: %GOPATH%
echo.

REM Create googleapis directory if not exists
set GOOGLEAPIS_DIR=%GOPATH%\src\github.com\googleapis\googleapis
if not exist "%GOOGLEAPIS_DIR%" (
    echo Setting up googleapis...
    mkdir "%GOPATH%\src\github.com\googleapis" 2>nul
    pushd "%GOPATH%\src\github.com\googleapis"
    git clone https://github.com/googleapis/googleapis.git
    popd
)

REM Install required tools
echo Installing proto generation tools...
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
echo.

REM Generate proto for auth-service
echo [1/3] Generating proto for auth-service...
cd go-auth-service\server\proto
if not exist "..\internal\pb" mkdir "..\internal\pb"
protoc -I. -I"%GOOGLEAPIS_DIR%" ^
    --go_out=../internal/pb ^
    --go_opt=paths=source_relative ^
    --go-grpc_out=../internal/pb ^
    --go-grpc_opt=paths=source_relative ^
    --grpc-gateway_out=../internal/pb ^
    --grpc-gateway_opt=paths=source_relative ^
    --grpc-gateway_opt=logtostderr=true ^
    *.proto
cd ..\..\..
echo ✓ auth-service proto generated
echo.

REM Generate proto for user-service
echo [2/3] Generating proto for user-service...
cd go-user-service\server\proto
if not exist "..\internal\pb" mkdir "..\internal\pb"
protoc -I. -I"%GOOGLEAPIS_DIR%" ^
    --go_out=../internal/pb ^
    --go_opt=paths=source_relative ^
    --go-grpc_out=../internal/pb ^
    --go-grpc_opt=paths=source_relative ^
    --grpc-gateway_out=../internal/pb ^
    --grpc-gateway_opt=paths=source_relative ^
    --grpc-gateway_opt=logtostderr=true ^
    *.proto
cd ..\..\..
echo ✓ user-service proto generated
echo.

REM Generate proto for tenant-service
echo [3/3] Generating proto for tenant-service...
cd go-tenant-service\server\proto
if not exist "..\internal\pb" mkdir "..\internal\pb"
protoc -I. -I"%GOOGLEAPIS_DIR%" ^
    --go_out=../internal/pb ^
    --go_opt=paths=source_relative ^
    --go-grpc_out=../internal/pb ^
    --go-grpc_opt=paths=source_relative ^
    --grpc-gateway_out=../internal/pb ^
    --grpc-gateway_opt=paths=source_relative ^
    --grpc-gateway_opt=logtostderr=true ^
    *.proto
cd ..\..\..
echo ✓ tenant-service proto generated
echo.

echo ========================================
echo Proto generation completed successfully!
echo ========================================
echo Generated files are in: */server/internal/pb/
echo.
