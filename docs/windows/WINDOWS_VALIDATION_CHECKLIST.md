# Windows Installation Validation Checklist

This checklist helps verify that the go-framework is correctly installed and configured on Windows systems, particularly when using custom installation paths like `E:\go\go-framework`.

## Pre-Installation Checklist

### System Requirements
- [ ] Windows 10 version 2004+ (Build 19041+) or Windows 11
- [ ] Minimum 8GB RAM (16GB recommended)
- [ ] Minimum 20GB free disk space
- [ ] 64-bit processor with virtualization support
- [ ] Administrator access (for initial setup)
- [ ] Stable internet connection

### Custom Path Considerations (e.g., E:\go\go-framework)
- [ ] Target drive exists and is accessible (e.g., E: drive)
- [ ] Sufficient free space on target drive (20GB+)
- [ ] Write permissions on target directory
- [ ] Path does not contain spaces or special characters
- [ ] Drive is not a removable/network drive (for best performance)
- [ ] SSD drive recommended for better performance

## Installation Checklist

### 1. WSL2 Setup
- [ ] WSL2 installed successfully
- [ ] WSL2 version is 2 (verify with `wsl --status`)
- [ ] Ubuntu or preferred Linux distribution installed
- [ ] WSL2 can access Windows filesystem
- [ ] Can navigate to installation path in WSL2 (e.g., `cd /mnt/e/go/go-framework`)

### 2. Docker Desktop
- [ ] Docker Desktop installed
- [ ] Docker Desktop is running
- [ ] "Use WSL 2 based engine" is enabled
- [ ] WSL integration enabled for your distribution
- [ ] `docker --version` returns version 20.0+
- [ ] `docker ps` runs without errors
- [ ] Can run test container: `docker run hello-world`

### 3. Go Installation
- [ ] Go installed (version 1.21+, 1.25+ recommended)
- [ ] `go version` shows correct version
- [ ] GOPATH is set correctly
- [ ] GOROOT is set correctly
- [ ] Go binaries in PATH
- [ ] Can run `go env` successfully
- [ ] Go modules enabled (default in Go 1.16+)

### 4. Git Installation
- [ ] Git installed (version 2.0+)
- [ ] `git --version` shows correct version
- [ ] Git configured with user name and email
- [ ] Git line endings configured (`core.autocrlf = false`, `core.eol = lf`)
- [ ] Can clone repositories successfully

### 5. Repository Setup
- [ ] Repository cloned to intended location
- [ ] All files present (no clone errors)
- [ ] Can navigate to repository in PowerShell
- [ ] Can navigate to repository in WSL2
- [ ] File permissions correct in WSL2 (`ls -la` shows user ownership)
- [ ] Scripts are executable in WSL2 (`chmod +x scripts/**/*.sh`)

### 6. PowerShell Setup Script
- [ ] Can run `.\scripts\setup\setup-windows.ps1`
- [ ] Script detects custom installation path correctly
- [ ] All dependencies checked successfully
- [ ] Environment configuration created (`.env` file)
- [ ] Go development tools installed
- [ ] Project dependencies downloaded
- [ ] CLI tool built successfully

### 7. Go Development Tools
- [ ] protoc-gen-go installed
- [ ] protoc-gen-go-grpc installed
- [ ] golangci-lint installed
- [ ] Tools accessible in PATH
- [ ] Can verify with `protoc-gen-go --version`

### 8. Project Build
- [ ] CLI tool builds without errors
- [ ] Binary created at `bin/saas.exe`
- [ ] Binary is executable: `.\bin\saas.exe --help`
- [ ] CLI shows correct help information
- [ ] No compilation errors or warnings

### 9. Project Dependencies
- [ ] Go modules downloaded successfully
- [ ] `go mod download` completes without errors
- [ ] `go mod tidy` runs successfully
- [ ] No missing dependencies
- [ ] Can verify with `go list -m all`

## Post-Installation Validation

### 1. WSL2 Access
- [ ] Can access installation directory from WSL2
- [ ] Correct path mapping (Windows ↔ WSL2)
- [ ] File permissions allow script execution
- [ ] No "Permission denied" errors when running scripts
- [ ] Performance is acceptable (no slow file access)

### 2. Make Commands (WSL2)
```bash
# Navigate to installation directory in WSL2
cd /mnt/e/go/go-framework  # Adjust path as needed
```

- [ ] `make help` displays all available commands
- [ ] `make version` shows tool versions
- [ ] `make validate-env` passes validation
- [ ] `make build-cli` builds successfully

### 3. Docker Services
```bash
# In WSL2, in project directory
make start
```

- [ ] Docker Compose starts without errors
- [ ] All containers start successfully
- [ ] `make status` shows all services healthy
- [ ] `make ps` lists running containers
- [ ] `make info` displays service URLs
- [ ] Can access services (e.g., http://localhost:8080)

### 4. Service Health Checks
- [ ] API Gateway: http://localhost:8080/health
- [ ] Auth Service: http://localhost:8081/health
- [ ] User Service: http://localhost:8082/health
- [ ] Tenant Service: http://localhost:8083/health
- [ ] Notification Service: http://localhost:8084/health
- [ ] System Config Service: http://localhost:8085/health
- [ ] MongoDB accessible: mongodb://localhost:27017
- [ ] Redis accessible: redis://localhost:6379
- [ ] RabbitMQ Management: http://localhost:15672

### 5. Observability Stack
- [ ] Prometheus: http://localhost:9090
- [ ] Grafana: http://localhost:3000 (admin/admin)
- [ ] Jaeger: http://localhost:16686
- [ ] All dashboards load correctly
- [ ] Metrics are being collected

### 6. Testing
```bash
# In WSL2, in project directory
make test-unit
```

- [ ] Unit tests run successfully
- [ ] No test failures
- [ ] Test output is readable
- [ ] Can run tests multiple times

### 7. Logs and Monitoring
```bash
make logs
```

- [ ] Can view logs from all services
- [ ] Logs are readable and formatted correctly
- [ ] `make logs-service SERVICE=auth-service` works for specific services
- [ ] No error logs during startup

### 8. Service Operations
```bash
make stop
make start
make restart
```

- [ ] Services stop cleanly
- [ ] Services start successfully
- [ ] Services restart without issues
- [ ] `make restart-service SERVICE=auth-service` works for individual services

## Path-Specific Validation (E:\go\go-framework)

### Windows PowerShell
```powershell
cd E:\go\go-framework
```

- [ ] Can navigate to `E:\go\go-framework` in PowerShell
- [ ] `Get-Location` shows correct path
- [ ] Directory structure intact
- [ ] Can execute `.\bin\saas.exe`
- [ ] Can run Go commands: `go version`

### WSL2 Linux
```bash
cd /mnt/e/go/go-framework
```

- [ ] Can navigate to `/mnt/e/go/go-framework` in WSL2
- [ ] `pwd` shows `/mnt/e/go/go-framework`
- [ ] File permissions are correct
- [ ] Scripts are executable
- [ ] Make commands work correctly

### Drive Accessibility
- [ ] E: drive is permanently mounted (not removable)
- [ ] E: drive accessible after Windows restart
- [ ] E: drive accessible in WSL2 after restart
- [ ] Consistent performance across sessions

### Path Handling
- [ ] No issues with backslashes vs forward slashes
- [ ] Environment variables resolve correctly
- [ ] Relative paths work as expected
- [ ] Symbolic links (if any) work correctly

## Common Issues Checklist

### If Services Don't Start
- [ ] Docker Desktop is running
- [ ] WSL2 is running
- [ ] All required ports are available (8080-8085, 9090, 3000, etc.)
- [ ] Sufficient system resources (CPU, RAM)
- [ ] No conflicting services

### If Make Commands Fail
- [ ] Running from WSL2 (not Windows PowerShell)
- [ ] In correct directory
- [ ] Make is installed in WSL2: `which make`
- [ ] Scripts are executable: `chmod +x scripts/**/*.sh`

### If File Access is Slow
- [ ] Using SSD (not HDD)
- [ ] Not using network/removable drive
- [ ] Windows Defender exclusions configured
- [ ] WSL2 memory allocated properly (`.wslconfig`)

### If Permission Errors Occur
- [ ] Files owned by current user: `ls -la`
- [ ] Scripts executable: `chmod +x scripts/**/*.sh`
- [ ] Correct line endings (LF not CRLF)
- [ ] Git configured correctly for line endings

## Documentation Validation

- [ ] README.md mentions Windows custom path support
- [ ] WINDOWS_SETUP.md includes E:\go\go-framework examples
- [ ] Setup script supports -InstallPath parameter
- [ ] Troubleshooting section covers custom paths
- [ ] Path mapping documented (Windows ↔ WSL2)

## Final Verification

### Comprehensive Test
```bash
# In WSL2, in project directory
make clean
make setup-env
make build-cli
make start
make status
make test-unit
make stop
```

- [ ] All commands execute successfully
- [ ] No errors or warnings
- [ ] System performs well
- [ ] Ready for development

### Developer Workflow Test
1. [ ] Make a small code change
2. [ ] Build the project
3. [ ] Run tests
4. [ ] Start services
5. [ ] Verify changes work
6. [ ] Stop services
7. [ ] No issues encountered

### Documentation Test
1. [ ] Follow README quick start
2. [ ] Follow WINDOWS_SETUP.md manual installation
3. [ ] Run automated PowerShell script
4. [ ] All documentation is accurate
5. [ ] Examples work as described

## Sign-Off

**Installation Date:** _________________

**Installation Path:** _________________

**Windows Version:** _________________

**Validator Name:** _________________

**Signature:** _________________

**Notes/Issues:**
_______________________________________________
_______________________________________________
_______________________________________________

## Additional Resources

- [Windows Setup Guide](WINDOWS_SETUP.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Getting Started Guide](GETTING_STARTED.md)
- [Development Guide](DEVELOPMENT.md)

---

**Status Legend:**
- ✅ Checked and working
- ⚠️ Checked with minor issues
- ❌ Failed or not working
- ⏭️ Skipped
- 📝 Needs review

**For any issues, refer to:**
1. Troubleshooting section in WINDOWS_SETUP.md
2. GitHub Issues
3. Project documentation
