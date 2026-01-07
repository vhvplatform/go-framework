# Example: Installing go-framework to E:\go\go-framework

This guide provides a complete walkthrough for installing and setting up the go-framework on a Windows system using a custom directory path: `E:\go\go-framework`.

## Why Use a Custom Path?

Common reasons for using a custom installation path:
- **More disk space**: Your C: drive might be limited, and E: drive has more space
- **Better organization**: Keeping development projects separate from system files
- **Performance**: E: might be a faster SSD
- **Backup strategy**: Easier to backup a specific drive
- **IT policy**: Company requirements for project locations

## Prerequisites

Before starting, ensure:
1. **E: drive exists and is accessible**
   ```powershell
   # Verify E: drive in PowerShell
   Get-PSDrive -Name E
   ```

2. **Sufficient free space** (minimum 20GB)
   ```powershell
   Get-PSDrive -Name E | Select-Object Name, Used, Free
   ```

3. **Write permissions** on E: drive
   ```powershell
   # Test write access
   New-Item -Path E:\test.txt -ItemType File
   Remove-Item -Path E:\test.txt
   ```

## Step-by-Step Installation

### Step 1: Prepare the Directory

Open PowerShell (as Administrator for first-time setup):

```powershell
# Create the directory structure
New-Item -Path E:\go -ItemType Directory -Force
Set-Location E:\go

# Verify the directory was created
Get-Location  # Should show: E:\go
```

### Step 2: Clone the Repository

```powershell
# Clone to the specific path
git clone https://github.com/vhvplatform/go-framework.git E:\go\go-framework

# Navigate to the directory
cd E:\go\go-framework

# Verify the clone
Get-ChildItem
# You should see: docker/, scripts/, tools/, README.md, etc.
```

### Step 3: Configure Git for Windows/WSL2 Compatibility

```powershell
# Still in E:\go\go-framework
# Configure Git to use LF line endings (important for WSL2)
git config core.autocrlf false
git config core.eol lf

# Verify configuration
git config --get core.autocrlf  # Should show: false
git config --get core.eol       # Should show: lf
```

### Step 4: Run the Automated Setup Script

```powershell
# Run the setup script with custom path
.\scripts\setup\setup-windows.ps1 -InstallPath "E:\go\go-framework"

# The script will:
# - Verify system requirements
# - Check/install WSL2
# - Check/install Docker Desktop
# - Install Go and Git (if needed)
# - Configure environment
# - Install Go development tools
# - Download dependencies
# - Build the CLI tool
# - Run tests (unless -SkipTests specified)
```

**Alternative: Skip tests for faster setup**
```powershell
.\scripts\setup\setup-windows.ps1 -InstallPath "E:\go\go-framework" -SkipTests
```

### Step 5: Verify Installation in PowerShell

```powershell
# Verify you're in the correct directory
Get-Location  # Should show: E:\go\go-framework

# Check that the CLI tool was built
Test-Path .\bin\saas.exe  # Should return: True

# Run the CLI tool
.\bin\saas.exe --help

# Expected output:
# SaaS Platform Developer Tools
# 
# Usage:
#   saas [command]
# ...
```

### Step 6: Set Up WSL2 Access

Open WSL2 (Ubuntu or your preferred distribution):

```bash
# Navigate to the installation directory
# E: drive in Windows = /mnt/e in WSL2
cd /mnt/e/go/go-framework

# Verify you're in the right place
pwd
# Should show: /mnt/e/go/go-framework

ls -la
# Should list all project files

# Make scripts executable
chmod +x scripts/setup/*.sh
chmod +x scripts/**/*.sh

# Verify permissions
ls -la scripts/setup/
# Scripts should show as executable (green or with 'x' in permissions)
```

### Step 7: Configure WSL2 Mount Options (Optional but Recommended)

For better performance and compatibility:

```bash
# In WSL2
# Edit WSL configuration
sudo nano /etc/wsl.conf

# Add these lines:
[automount]
enabled = true
options = "metadata,umask=22,fmask=11"
mountFsTab = true

# Save and exit (Ctrl+X, Y, Enter)

# Restart WSL2 to apply changes
exit

# In PowerShell:
wsl --shutdown

# Wait a few seconds, then restart WSL2:
wsl
```

### Step 8: Install Dependencies and Build

```bash
# In WSL2, in the project directory
cd /mnt/e/go/go-framework

# Verify Go is available
go version

# Download dependencies
cd tools/cli
go mod download
go mod tidy
cd ../..

# Build the CLI tool
make build-cli

# Verify build
ls -la bin/
# Should show saas.exe
```

### Step 9: Start Docker Services

```bash
# Still in WSL2, in project directory
cd /mnt/e/go/go-framework

# Ensure Docker Desktop is running
docker --version
docker ps

# Start all services
make start

# This will:
# 1. Pull Docker images (first time only, may take 5-10 minutes)
# 2. Start all containers
# 3. Wait for services to be healthy
# 4. Display status

# Check service status
make status

# Expected output:
# 🏥 Checking service health...
#   API Gateway... ✅
#   Auth Service... ✅
#   ...
```

### Step 10: Verify Everything Works

```bash
# In WSL2
cd /mnt/e/go/go-framework

# View service information
make info

# Test API Gateway
curl http://localhost:8080/health

# Expected response (or similar):
# {"status":"ok","timestamp":"..."}

# View logs
make logs

# Stop services when done
make stop
```

## Daily Development Workflow

### Starting Your Work Session

**Option 1: Using WSL2 (Recommended)**
```bash
# Open WSL2 terminal
wsl

# Navigate to project
cd /mnt/e/go/go-framework

# Start services
make start

# Work on your code...
```

**Option 2: Using PowerShell**
```powershell
# Open PowerShell
cd E:\go\go-framework

# For Docker operations, switch to WSL2:
wsl

# Now you're in WSL2, navigate to project
cd /mnt/e/go/go-framework

# Start services
make start
```

### Quick Access Aliases (Optional)

Make your life easier with aliases:

**For WSL2 (add to ~/.bashrc):**
```bash
# Edit bash configuration
nano ~/.bashrc

# Add these lines at the end:
alias gf='cd /mnt/e/go/go-framework'
alias gfs='cd /mnt/e/go/go-framework && make start'
alias gfst='cd /mnt/e/go/go-framework && make status'

# Save and reload
source ~/.bashrc

# Now you can use:
gf      # Go to framework directory
gfs     # Go to framework and start services
gfst    # Go to framework and check status
```

**For PowerShell (add to profile):**
```powershell
# Edit PowerShell profile
notepad $PROFILE

# Add these lines:
function gf { Set-Location E:\go\go-framework }
function gfw { wsl cd /mnt/e/go/go-framework }

# Save and reload
. $PROFILE

# Now you can use:
gf      # Navigate to E:\go\go-framework in PowerShell
gfw     # Open WSL2 in the framework directory
```

## Common Operations

### Building the Project
```bash
# In WSL2, in project directory
cd /mnt/e/go/go-framework
make build-cli
```

### Running Tests
```bash
# In WSL2
cd /mnt/e/go/go-framework
make test-unit
make test-integration
```

### Viewing Logs
```bash
# All services
make logs

# Specific service
make logs-service SERVICE=auth-service
```

### Restarting a Service
```bash
make restart-service SERVICE=auth-service
```

### Accessing Monitoring Tools
```bash
# Open in browser
make open-grafana
make open-prometheus
make open-jaeger
```

## Troubleshooting E: Drive Specific Issues

### Issue: "Drive E: not found" in WSL2

**Solution:**
```bash
# Check if E: is mounted
ls /mnt/e

# If not mounted, remount manually
sudo mkdir -p /mnt/e
sudo mount -t drvfs E: /mnt/e
```

### Issue: Permission Denied Errors

**Solution:**
```bash
# Fix ownership
cd /mnt/e/go/go-framework
sudo chown -R $USER:$USER .

# Make scripts executable
chmod +x scripts/**/*.sh
```

### Issue: Slow Performance

**Solutions:**
1. **Ensure E: is an SSD, not HDD**
2. **Configure WSL2 to use more resources**
   ```powershell
   # In PowerShell, create/edit .wslconfig
   notepad $env:USERPROFILE\.wslconfig
   
   # Add:
   [wsl2]
   memory=8GB
   processors=4
   swap=2GB
   
   # Restart WSL2
   wsl --shutdown
   wsl
   ```

3. **Exclude from Windows Defender**
   - Open Windows Security
   - Go to Virus & threat protection
   - Manage settings
   - Add exclusion for `E:\go`

### Issue: Docker Can't Access Files

**Solution:**
```powershell
# In Docker Desktop:
# 1. Settings → Resources → File Sharing
# 2. Add E:\ to shared drives
# 3. Apply & Restart
```

### Issue: Path Not Persistent After Restart

**Solution:**
Ensure E: drive is a physical/internal drive, not:
- Network drive
- External USB drive
- Mapped drive

If it's a secondary internal drive, it should persist automatically.

## Performance Tips for E: Drive Installation

1. **Use SSD**: Ensure E: is an SSD for best performance
2. **Disable Indexing**: Right-click E: drive → Properties → Uncheck "Allow files on this drive to have contents indexed"
3. **Antivirus Exclusions**: Add `E:\go\go-framework` to antivirus exclusions
4. **WSL2 Memory**: Allocate sufficient memory in `.wslconfig`
5. **Docker Resources**: Ensure Docker Desktop has adequate resources (Settings → Resources)

## Backup Recommendations

Since your installation is on E: drive:

```powershell
# Create a backup script (save as E:\go\backup.ps1)
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "E:\backups\go-framework-$timestamp.zip"
Compress-Archive -Path E:\go\go-framework -DestinationPath $backupPath -CompressionLevel Optimal
Write-Host "Backup created: $backupPath"
```

## Validation

After completing setup, use the validation checklist:

```bash
# In WSL2
cd /mnt/e/go/go-framework

# Follow the validation checklist
cat docs/WINDOWS_VALIDATION_CHECKLIST.md
```

Go through each item in the checklist to ensure everything is working correctly.

## Summary

You now have go-framework installed at `E:\go\go-framework` with:
- ✅ Full Windows PowerShell access at `E:\go\go-framework`
- ✅ Full WSL2 access at `/mnt/e/go/go-framework`
- ✅ Docker services working
- ✅ All tools and dependencies installed
- ✅ CLI tool built and functional
- ✅ Development environment ready

## Next Steps

1. Read [Getting Started Guide](GETTING_STARTED.md)
2. Review [Development Guide](DEVELOPMENT.md)
3. Try [Examples](../examples/)
4. Start developing!

## Getting Help

If you encounter issues:
1. Check [WINDOWS_SETUP.md](WINDOWS_SETUP.md) troubleshooting section
2. Review [WINDOWS_VALIDATION_CHECKLIST.md](WINDOWS_VALIDATION_CHECKLIST.md)
3. Search [GitHub Issues](https://github.com/vhvplatform/go-framework/issues)
4. Open a new issue with details about your E: drive setup

---

**Happy Coding from E:\go\go-framework!** 🚀
