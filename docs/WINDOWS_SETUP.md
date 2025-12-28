# Windows Setup Guide

Complete guide for setting up the go-framework development environment on Windows.

## Table of Contents

- [System Requirements](#system-requirements)
- [Quick Setup (Automated)](#quick-setup-automated)
- [Manual Installation](#manual-installation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

---

## System Requirements

### Minimum Requirements

- **Operating System:** Windows 10 version 2004 or later (Build 19041+) or Windows 11
- **RAM:** 8GB (16GB recommended for running all services)
- **Disk Space:** 20GB free space (SSD recommended)
- **CPU:** 2 cores (4+ cores recommended)
- **Architecture:** x64 or ARM64
- **Internet:** Broadband connection for downloading dependencies

### Required Software

The following software will be installed or checked by the automated setup script:

- **WSL2** (Windows Subsystem for Linux 2)
- **Docker Desktop** 4.0+ for Windows
- **Go** 1.21+ (1.25+ recommended)
- **Git** for Windows 2.0+
- **PowerShell** 5.1+ or PowerShell Core 7+

### Optional but Recommended

- **Windows Terminal** (for better command-line experience)
- **VS Code** with Go extension (for development)
- **Postman** or similar API testing tool

---

## Quick Setup (Automated)

The fastest way to get started on Windows:

### Option 1: Using PowerShell Script (Recommended)

1. **Open PowerShell as Administrator**
   - Right-click on Start menu
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Enable script execution** (if not already enabled):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Clone the repository**:
   ```powershell
   git clone https://github.com/vhvplatform/go-framework.git
   cd go-framework
   ```

4. **Run the automated setup script**:
   ```powershell
   .\scripts\setup\setup-windows.ps1
   ```

5. **Follow the on-screen instructions**

The script will:
- ✓ Check system compatibility
- ✓ Verify or guide installation of WSL2
- ✓ Check/install Docker Desktop
- ✓ Install or update Go
- ✓ Install or update Git
- ✓ Configure environment variables
- ✓ Install Go development tools
- ✓ Download project dependencies
- ✓ Build the project
- ✓ Run verification tests

**Estimated Time:** 20-45 minutes (depending on internet speed and required installations)

### Option 2: Using Windows Subsystem for Linux (WSL2)

If you prefer using Linux tools:

1. **Install WSL2** (if not already installed):
   ```powershell
   wsl --install
   ```

2. **Restart your computer** when prompted

3. **Open Ubuntu/WSL2 terminal** and follow the [Linux setup instructions](SETUP.md#linux-ubuntudebian)

---

## Manual Installation

For users who prefer step-by-step manual installation or want more control:

### Step 1: Install WSL2

WSL2 is required for running Docker Desktop and provides the best Linux compatibility on Windows.

1. **Open PowerShell as Administrator** and run:
   ```powershell
   wsl --install
   ```

2. **Restart your computer** when installation completes

3. **Set up your Linux username and password** when prompted after restart

4. **Update WSL2**:
   ```powershell
   wsl --update
   ```

5. **Set WSL2 as default**:
   ```powershell
   wsl --set-default-version 2
   ```

6. **Verify installation**:
   ```powershell
   wsl --status
   ```

**Troubleshooting WSL2:**
- If installation fails, ensure virtualization is enabled in BIOS
- Check Windows version: Run `winver` (needs Build 19041+)
- See [Microsoft WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/install)

### Step 2: Install Docker Desktop

Docker Desktop provides containerization support for running services.

1. **Download Docker Desktop**:
   - Visit [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Download Docker Desktop for Windows

2. **Install Docker Desktop**:
   - Run the installer
   - Accept the license agreement
   - Select "Use WSL 2 instead of Hyper-V" option
   - Complete the installation
   - Restart your computer if prompted

3. **Configure Docker Desktop**:
   - Launch Docker Desktop
   - Go to Settings → General
   - Ensure "Use the WSL 2 based engine" is checked
   - Go to Settings → Resources → WSL Integration
   - Enable integration with your WSL2 distributions

4. **Verify Docker installation**:
   ```powershell
   docker --version
   docker ps
   ```

### Step 3: Install Go

Go is the primary programming language for this project.

#### Option A: Using Official Installer (Recommended)

1. **Download Go installer**:
   - Visit [https://go.dev/dl/](https://go.dev/dl/)
   - Download the Windows installer (.msi) for your architecture
   - Recommended: Go 1.25 or later

2. **Run the installer**:
   - Double-click the downloaded .msi file
   - Follow the installation wizard
   - Default installation path: `C:\Program Files\Go`

3. **Verify installation**:
   ```powershell
   go version
   ```

#### Option B: Using Chocolatey

If you have [Chocolatey](https://chocolatey.org/) installed:

```powershell
choco install golang
```

#### Configure Go Environment

1. **Set GOPATH** (if not already set):
   ```powershell
   [Environment]::SetEnvironmentVariable("GOPATH", "$HOME\go", "User")
   ```

2. **Add Go bin to PATH**:
   ```powershell
   $goPath = [Environment]::GetEnvironmentVariable("GOPATH", "User")
   $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
   if ($currentPath -notlike "*$goPath\bin*") {
       [Environment]::SetEnvironmentVariable("Path", "$currentPath;$goPath\bin", "User")
   }
   ```

3. **Restart PowerShell** to apply environment changes

4. **Verify Go configuration**:
   ```powershell
   go env GOPATH
   go env GOROOT
   ```

### Step 4: Install Git

Git is required for version control and cloning repositories.

#### Option A: Using Official Installer (Recommended)

1. **Download Git for Windows**:
   - Visit [https://git-scm.com/download/win](https://git-scm.com/download/win)
   - Download the latest version for your architecture

2. **Run the installer**:
   - Use recommended settings during installation
   - Select "Git from the command line and also from 3rd-party software"
   - Choose your preferred editor
   - Select "Use Windows' default console window"

3. **Verify installation**:
   ```powershell
   git --version
   ```

#### Option B: Using Chocolatey

```powershell
choco install git
```

#### Configure Git

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Step 5: Clone Repository

```powershell
# Create workspace directory
mkdir -p $HOME\workspace\go-platform
cd $HOME\workspace\go-platform

# Clone go-framework repository
git clone https://github.com/vhvplatform/go-framework.git
cd go-framework
```

### Step 6: Install Go Development Tools

```powershell
# Option 1: Using the provided script (in WSL2)
wsl
cd /mnt/c/Users/YourUsername/workspace/go-platform/go-framework
./scripts/setup/install-tools.sh
exit

# Option 2: Manual installation
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

### Step 7: Configure Environment Variables

1. **Copy environment example file**:
   ```powershell
   cd docker
   Copy-Item .env.example .env
   ```

2. **Edit .env file** with your preferred text editor:
   ```powershell
   notepad .env
   ```

3. **Customize settings** as needed (JWT secret, SMTP, etc.)

### Step 8: Install Project Dependencies

```powershell
# In WSL2 (recommended for Docker operations)
wsl
cd /mnt/c/Users/YourUsername/workspace/go-platform/go-framework

# Download Go module dependencies
cd tools/cli
go mod download
cd ../..

# Or if there are other go.mod files
find . -name "go.mod" -execdir go mod download \;
```

### Step 9: Build the Project

```powershell
# In WSL2
wsl
cd /mnt/c/Users/YourUsername/workspace/go-platform/go-framework

# Build the CLI tool
cd tools/cli
go build -o ../../bin/saas.exe .
cd ../..

# Verify build
./bin/saas.exe --help
```

---

## Verification

After installation, verify your setup:

### 1. Check Installed Tools

```powershell
# Check versions
go version          # Should show Go 1.21 or later
git --version       # Should show Git 2.0 or later
docker --version    # Should show Docker 20.0 or later
wsl --status        # Should show WSL2 running

# Check Docker
docker ps           # Should list running containers (may be empty)
docker-compose --version  # Should show version
```

### 2. Check Go Environment

```powershell
go env GOPATH       # Should show your Go workspace path
go env GOROOT       # Should show Go installation path
go env GOOS         # Should show 'windows'
go env GOARCH       # Should show 'amd64' or 'arm64'
```

### 3. Build CLI Tool

```powershell
cd tools\cli
go build -o ..\..\bin\saas.exe .
..\..\bin\saas.exe --help
```

Expected output:
```
SaaS Platform Developer Tools

Usage:
  saas [command]

Available Commands:
  setup       Setup development environment
  start       Start all services
  ...
```

### 4. Test Docker Integration

```powershell
# In WSL2
wsl
cd /mnt/c/Users/YourUsername/workspace/go-platform/go-framework

# Try to start services
make start

# Check service status
make status

# Stop services
make stop
```

### 5. Run Tests (Optional)

```powershell
# In WSL2
cd tools/cli
go test -v ./...
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: WSL2 Installation Fails

**Symptoms:**
- Error: "WSL 2 requires an update to its kernel component"
- Installation hangs or fails

**Solutions:**
1. **Enable virtualization in BIOS/UEFI**:
   - Restart computer and enter BIOS/UEFI
   - Enable Intel VT-x or AMD-V virtualization
   - Save and exit

2. **Update Windows**:
   - Go to Settings → Update & Security → Windows Update
   - Install all available updates
   - Restart your computer

3. **Install WSL2 kernel update manually**:
   - Download from: https://aka.ms/wsl2kernel
   - Run the installer

4. **Check Windows version**:
   - Press Win+R, type `winver`
   - Ensure Build is 19041 or higher
   - Update Windows if needed

#### Issue: Docker Desktop Won't Start

**Symptoms:**
- Docker Desktop shows "Docker Desktop starting..." forever
- Error: "Hardware assisted virtualization and data execution protection must be enabled"

**Solutions:**
1. **Enable WSL2 integration**:
   - Ensure WSL2 is installed and working: `wsl --status`
   - In Docker Desktop: Settings → Resources → WSL Integration
   - Enable integration with your distributions

2. **Restart WSL2**:
   ```powershell
   wsl --shutdown
   wsl
   ```

3. **Restart Docker Desktop**:
   - Quit Docker Desktop completely
   - Start Docker Desktop again

4. **Check for conflicting software**:
   - Disable Hyper-V if WSL2 is being used
   - Check antivirus software isn't blocking Docker

#### Issue: Go Command Not Found

**Symptoms:**
- `go: command not found` or `'go' is not recognized`

**Solutions:**
1. **Add Go to PATH manually**:
   ```powershell
   # Add Go installation directory
   $env:Path += ";C:\Program Files\Go\bin"
   
   # Add Go workspace bin directory
   $goPath = go env GOPATH
   $env:Path += ";$goPath\bin"
   
   # Make permanent
   [Environment]::SetEnvironmentVariable("Path", $env:Path, "User")
   ```

2. **Restart PowerShell** after modifying PATH

3. **Verify Go installation**:
   - Check if Go is installed: `dir "C:\Program Files\Go"`
   - Reinstall if missing

#### Issue: Permission Denied in WSL2

**Symptoms:**
- `Permission denied` errors when running scripts
- Cannot execute shell scripts

**Solutions:**
1. **Make scripts executable**:
   ```bash
   chmod +x scripts/setup/*.sh
   chmod +x scripts/**/*.sh
   ```

2. **Check file ownership**:
   ```bash
   ls -la scripts/
   # If owned by root, change ownership:
   sudo chown -R $USER:$USER .
   ```

3. **Check line endings**:
   - Windows uses CRLF, Linux uses LF
   - Configure Git to use LF:
   ```powershell
   git config --global core.autocrlf false
   ```
   - Then re-clone the repository

#### Issue: Port Already in Use

**Symptoms:**
- Error: "bind: address already in use"
- Services fail to start

**Solutions:**
1. **Check which process is using the port**:
   ```powershell
   netstat -ano | findstr :8080
   ```

2. **Kill the process** (replace PID):
   ```powershell
   taskkill /PID <PID> /F
   ```

3. **Or change port in configuration**:
   - Edit `docker-compose.yml`
   - Change port mappings to unused ports

#### Issue: Docker Compose Command Not Found

**Symptoms:**
- `docker-compose: command not found`

**Solutions:**
1. **Docker Compose is now integrated into Docker CLI**:
   - Use `docker compose` instead of `docker-compose`
   - Or create alias:
   ```powershell
   function docker-compose { docker compose $args }
   ```

2. **Install Docker Compose V2**:
   - Usually included with Docker Desktop
   - Verify: `docker compose version`

#### Issue: Make Command Not Found

**Symptoms:**
- `'make' is not recognized as an internal or external command`

**Solutions:**
1. **Use WSL2 for make commands**:
   ```powershell
   wsl
   cd /mnt/c/Users/YourUsername/workspace/go-platform/go-framework
   make setup
   ```

2. **Install Make on Windows** (optional):
   ```powershell
   choco install make
   ```

3. **Use alternative commands**:
   - Instead of `make setup`, run individual scripts
   - Check `Makefile` for the actual commands

#### Issue: Slow Performance in WSL2

**Symptoms:**
- Operations are very slow
- File access is sluggish

**Solutions:**
1. **Store files in WSL2 filesystem** (not Windows filesystem):
   ```bash
   # Instead of /mnt/c/Users/...
   # Use ~/workspace/...
   cd ~
   mkdir -p workspace/go-platform
   cd workspace/go-platform
   git clone https://github.com/vhvplatform/go-framework.git
   ```

2. **Configure WSL2 memory**:
   - Create/edit `%USERPROFILE%\.wslconfig`:
   ```ini
   [wsl2]
   memory=8GB
   processors=4
   swap=2GB
   ```
   - Restart WSL2: `wsl --shutdown`

3. **Disable Windows Defender real-time scanning for WSL2 folders**:
   - Add exclusion for: `%LOCALAPPDATA%\Packages\CanonicalGroupLimited*`

#### Issue: Go Module Download Fails

**Symptoms:**
- `go: connection refused`
- `go get: timeout`

**Solutions:**
1. **Configure Go proxy**:
   ```powershell
   go env -w GOPROXY=https://proxy.golang.org,direct
   ```

2. **Check network/firewall**:
   - Ensure access to proxy.golang.org
   - Check corporate proxy settings

3. **Use private proxy** (if needed):
   ```powershell
   go env -w GOPROXY=https://your-private-proxy.com
   ```

#### Issue: Architecture Mismatch

**Symptoms:**
- Binary won't run
- "exec format error"

**Solutions:**
1. **Check your system architecture**:
   ```powershell
   [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
   ```

2. **Build for correct architecture**:
   ```powershell
   # For AMD64
   $env:GOARCH = "amd64"
   go build
   
   # For ARM64
   $env:GOARCH = "arm64"
   go build
   ```

---

## Next Steps

Once your environment is set up:

1. **Read the Getting Started Guide**: [docs/GETTING_STARTED.md](GETTING_STARTED.md)

2. **Explore available commands**:
   ```bash
   # In WSL2
   make help
   ```

3. **Start the services**:
   ```bash
   make start
   ```

4. **Check service status**:
   ```bash
   make status
   ```

5. **View service URLs**:
   ```bash
   make info
   ```

6. **Try the CLI tool**:
   ```powershell
   # In PowerShell
   .\bin\saas.exe --help
   .\bin\saas.exe status
   ```

7. **Review documentation**:
   - [Local Development Guide](LOCAL_DEVELOPMENT.md)
   - [Testing Guide](TESTING.md)
   - [Debugging Guide](DEBUGGING.md)
   - [Tools Reference](TOOLS.md)

8. **Set up your IDE**:
   - VS Code: Open the workspace and install recommended extensions
   - GoLand: Import project and configure Go SDK

9. **Run tests**:
   ```bash
   make test
   ```

10. **Start developing**:
    - Create a new branch for your feature
    - Make your changes
    - Run tests and builds
    - Submit a pull request

---

## Additional Resources

### Official Documentation

- [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/windows/)
- [Go Documentation](https://go.dev/doc/)
- [Git for Windows](https://git-scm.com/download/win)

### Community Resources

- [Go Forum](https://forum.golangbridge.org/)
- [Docker Community](https://www.docker.com/community/)
- [Stack Overflow - WSL2](https://stackoverflow.com/questions/tagged/wsl-2)

### Project Documentation

- [Main README](../README.md)
- [Contributing Guidelines](../CONTRIBUTING.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

---

## Tips for Windows Users

### Use Windows Terminal

Windows Terminal provides a better command-line experience:
- Install from Microsoft Store
- Supports multiple tabs
- Better color support
- Customizable appearance

### PowerShell Profile

Create a PowerShell profile for quick access:

```powershell
# Edit profile
notepad $PROFILE

# Add useful aliases
function gf { cd $HOME\workspace\go-platform\go-framework }
function wslf { wsl cd /mnt/c/Users/$env:USERNAME/workspace/go-platform/go-framework }
```

### VS Code Integration

VS Code works great with WSL2:
- Install "Remote - WSL" extension
- Open folder in WSL2: `code .` from WSL2 terminal
- Full Linux development experience in Windows

### File System Best Practices

- Store code in WSL2 filesystem (`~/workspace/`) for best performance
- Access from Windows: `\\wsl$\Ubuntu\home\username\workspace\`
- Use WSL2 terminal for all development commands
- Use Windows tools (VS Code, browsers) for UI

---

**Need Help?**

If you encounter issues not covered here:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Search [GitHub Issues](https://github.com/vhvplatform/go-framework/issues)
3. Open a new issue with:
   - Detailed description
   - Steps to reproduce
   - Environment details (Windows version, tools versions)
   - Error messages and logs

Happy coding! 🚀
