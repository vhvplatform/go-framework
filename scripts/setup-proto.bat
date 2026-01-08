@echo off
REM Quick Setup Script for Proto Code Generation

echo ========================================
echo Proto Generation Quick Setup
echo ========================================
echo.

REM Step 1: Check and install Go tools
echo Step 1: Installing Go proto generation tools...
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest
echo ✓ Go tools installed
echo.

REM Step 2: Check protoc
echo Step 2: Checking for protoc...
where protoc >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo ⚠ WARNING: protoc not found!
    echo.
    echo Please install Protocol Buffers compiler:
    echo 1. Download from: https://github.com/protocolbuffers/protobuf/releases
    echo 2. Extract to C:\protoc
    echo 3. Add C:\protoc\bin to your PATH
    echo.
    echo OR install using Chocolatey:
    echo    choco install protoc
    echo.
    echo OR install using Scoop:
    echo    scoop install protobuf
    echo.
    echo After installation, run this script again.
    pause
    exit /b 1
)
echo ✓ protoc found: 
protoc --version
echo.

REM Step 3: Setup GOPATH if not set
if "%GOPATH%"=="" (
    echo Setting GOPATH...
    set GOPATH=%USERPROFILE%\go
    setx GOPATH "%GOPATH%" >nul
    echo ✓ GOPATH set to: %GOPATH%
) else (
    echo ✓ GOPATH: %GOPATH%
)
echo.

REM Step 4: Setup googleapis
echo Step 3: Setting up googleapis...
set GOOGLEAPIS_DIR=%GOPATH%\src\github.com\googleapis\googleapis
if not exist "%GOOGLEAPIS_DIR%" (
    echo Cloning googleapis repository...
    mkdir "%GOPATH%\src\github.com\googleapis" 2>nul
    pushd "%GOPATH%\src\github.com\googleapis"
    git clone https://github.com/googleapis/googleapis.git
    popd
    echo ✓ googleapis cloned
) else (
    echo ✓ googleapis already exists
)
echo.

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Run: generate-proto.bat
echo    This will generate proto code for all services
echo.
echo 2. Or generate individually:
echo    cd go-auth-service\server\proto
echo    make proto
echo.
pause
