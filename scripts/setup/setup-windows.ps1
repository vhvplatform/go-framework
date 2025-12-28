#
# Script: setup-windows.ps1
# Description: Automated setup script for Windows development environment
# Usage: .\setup-windows.ps1
#
# This script automates the installation and configuration of the development
# environment for the go-framework project on Windows.
#
# Features:
#   - System compatibility check
#   - WSL2 installation verification
#   - Docker Desktop installation check
#   - Go installation and configuration
#   - Git installation and configuration
#   - Environment variables setup
#   - Go development tools installation
#   - Project dependencies download
#   - Build verification
#   - Test execution
#
# Requirements:
#   - Windows 10 Build 19041+ or Windows 11
#   - PowerShell 5.1+ or PowerShell Core 7+
#   - Administrator privileges (for some operations)
#   - Internet connection
#
# Examples:
#   .\setup-windows.ps1
#   .\setup-windows.ps1 -SkipTests
#   .\setup-windows.ps1 -Verbose
#
# Author: VHV Corp
# Last Modified: 2024-12-28
#

[CmdletBinding()]
param(
    [switch]$SkipTests,
    [switch]$SkipBuild,
    [switch]$Force
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Script:RequiredGoVersion = "1.21.0"
$Script:RecommendedGoVersion = "1.25.0"
$Script:RequiredGitVersion = "2.0.0"
$Script:RequiredDockerVersion = "20.0.0"
$Script:MinWindowsBuild = 19041

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Success" { Write-Host "✓ $Message" -ForegroundColor Green }
        "Error"   { Write-Host "✗ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
        "Info"    { Write-Host "ℹ $Message" -ForegroundColor Cyan }
        "Step"    { Write-Host "`n==== $Message ====" -ForegroundColor Magenta }
        default   { Write-Host $Message }
    }
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

# Version comparison helper
function Compare-Version {
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    $v1 = [version]($Version1 -replace '[^0-9.]', '')
    $v2 = [version]($Version2 -replace '[^0-9.]', '')
    
    return $v1.CompareTo($v2)
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check Windows version
function Test-WindowsVersion {
    Write-SectionHeader "Checking Windows Version"
    
    $build = [System.Environment]::OSVersion.Version.Build
    $version = [System.Environment]::OSVersion.Version
    
    Write-ColorOutput "Windows Version: $($version.Major).$($version.Minor) Build $build" "Info"
    
    if ($build -ge $Script:MinWindowsBuild) {
        Write-ColorOutput "Windows version is compatible" "Success"
        return $true
    } else {
        Write-ColorOutput "Windows Build $build is too old. Minimum required: $Script:MinWindowsBuild" "Error"
        Write-ColorOutput "Please update Windows to version 2004 (Build 19041) or later" "Warning"
        return $false
    }
}

# Check system architecture
function Get-SystemArchitecture {
    $arch = $env:PROCESSOR_ARCHITECTURE
    Write-ColorOutput "System Architecture: $arch" "Info"
    return $arch
}

# Check if WSL2 is installed
function Test-WSL2 {
    Write-SectionHeader "Checking WSL2"
    
    try {
        $wslVersion = wsl --status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "WSL2 is installed" "Success"
            
            # Check WSL version
            $wslList = wsl -l -v 2>&1
            Write-Host $wslList
            return $true
        }
    } catch {
        Write-ColorOutput "WSL2 is not installed" "Warning"
        return $false
    }
    
    return $false
}

# Install or guide WSL2 installation
function Install-WSL2 {
    Write-SectionHeader "Installing WSL2"
    
    if (-not (Test-Administrator)) {
        Write-ColorOutput "Administrator privileges required for WSL2 installation" "Warning"
        Write-ColorOutput "Please run the following command in an elevated PowerShell:" "Info"
        Write-Host "  wsl --install" -ForegroundColor Yellow
        Write-Host ""
        Write-ColorOutput "After installation, restart your computer and run this script again" "Info"
        return $false
    }
    
    Write-ColorOutput "Installing WSL2..." "Info"
    Write-ColorOutput "This may take several minutes..." "Info"
    
    try {
        wsl --install
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "WSL2 installation completed" "Success"
            Write-ColorOutput "Please restart your computer to complete WSL2 setup" "Warning"
            Write-ColorOutput "After restart, run this script again" "Info"
            return $true
        } else {
            Write-ColorOutput "WSL2 installation failed" "Error"
            return $false
        }
    } catch {
        Write-ColorOutput "Error installing WSL2: $_" "Error"
        Write-ColorOutput "Please install WSL2 manually: https://docs.microsoft.com/en-us/windows/wsl/install" "Info"
        return $false
    }
}

# Check if Docker Desktop is installed
function Test-Docker {
    Write-SectionHeader "Checking Docker Desktop"
    
    try {
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Docker is installed: $dockerVersion" "Success"
            
            # Check if Docker daemon is running
            try {
                docker ps 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "Docker daemon is running" "Success"
                    return $true
                } else {
                    Write-ColorOutput "Docker daemon is not running" "Warning"
                    Write-ColorOutput "Please start Docker Desktop" "Info"
                    return $false
                }
            } catch {
                Write-ColorOutput "Docker daemon is not running" "Warning"
                Write-ColorOutput "Please start Docker Desktop" "Info"
                return $false
            }
        }
    } catch {
        Write-ColorOutput "Docker is not installed" "Warning"
        return $false
    }
    
    return $false
}

# Guide Docker Desktop installation
function Install-Docker {
    Write-SectionHeader "Docker Desktop Installation"
    
    Write-ColorOutput "Docker Desktop is not installed or not running" "Warning"
    Write-Host ""
    Write-ColorOutput "Please follow these steps:" "Info"
    Write-Host "  1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "  2. Run the installer" -ForegroundColor Yellow
    Write-Host "  3. Enable 'Use WSL 2 based engine' option" -ForegroundColor Yellow
    Write-Host "  4. Complete the installation and restart if prompted" -ForegroundColor Yellow
    Write-Host "  5. Start Docker Desktop" -ForegroundColor Yellow
    Write-Host "  6. Run this script again" -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "Have you installed and started Docker Desktop? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        return Test-Docker
    }
    
    return $false
}

# Check if Go is installed
function Test-Go {
    Write-SectionHeader "Checking Go Installation"
    
    try {
        $goVersion = go version 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Extract version number
            if ($goVersion -match 'go(\d+\.\d+\.\d+)') {
                $installedVersion = $matches[1]
                Write-ColorOutput "Go is installed: $goVersion" "Success"
                
                # Check if version meets requirements
                if ((Compare-Version $installedVersion $Script:RequiredGoVersion) -ge 0) {
                    Write-ColorOutput "Go version meets requirements" "Success"
                    
                    if ((Compare-Version $installedVersion $Script:RecommendedGoVersion) -ge 0) {
                        Write-ColorOutput "Go version is recommended or newer" "Success"
                    } else {
                        Write-ColorOutput "Consider upgrading to Go $Script:RecommendedGoVersion or later" "Warning"
                    }
                    
                    return $true
                } else {
                    Write-ColorOutput "Go version $installedVersion is too old. Minimum required: $Script:RequiredGoVersion" "Warning"
                    return $false
                }
            }
        }
    } catch {
        Write-ColorOutput "Go is not installed" "Warning"
        return $false
    }
    
    return $false
}

# Install Go
function Install-Go {
    Write-SectionHeader "Installing Go"
    
    $arch = Get-SystemArchitecture
    $goArch = if ($arch -eq "ARM64") { "arm64" } else { "amd64" }
    
    Write-ColorOutput "Detecting latest Go version..." "Info"
    
    # Use a stable known version
    $goVersion = $Script:RecommendedGoVersion
    $downloadUrl = "https://go.dev/dl/go$goVersion.windows-$goArch.msi"
    $installerPath = "$env:TEMP\go-installer.msi"
    
    Write-ColorOutput "Downloading Go $goVersion for $goArch..." "Info"
    Write-ColorOutput "URL: $downloadUrl" "Info"
    
    try {
        # Download Go installer
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        
        Write-ColorOutput "Installing Go..." "Info"
        Write-ColorOutput "Please follow the installer prompts" "Info"
        
        # Run installer
        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qb" -Wait
        
        # Clean up
        Remove-Item $installerPath -ErrorAction SilentlyContinue
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-ColorOutput "Go installation completed" "Success"
        Write-ColorOutput "Please restart PowerShell for PATH changes to take effect" "Warning"
        
        return $true
    } catch {
        Write-ColorOutput "Error installing Go: $_" "Error"
        Write-ColorOutput "Please install Go manually from: https://go.dev/dl/" "Info"
        return $false
    }
}

# Check if Git is installed
function Test-Git {
    Write-SectionHeader "Checking Git Installation"
    
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Git is installed: $gitVersion" "Success"
            return $true
        }
    } catch {
        Write-ColorOutput "Git is not installed" "Warning"
        return $false
    }
    
    return $false
}

# Install Git
function Install-Git {
    Write-SectionHeader "Installing Git"
    
    $arch = Get-SystemArchitecture
    $gitArch = if ($arch -eq "ARM64") { "arm64" } else { "64-bit" }
    
    Write-ColorOutput "Git is not installed" "Warning"
    Write-Host ""
    Write-ColorOutput "Please follow these steps:" "Info"
    Write-Host "  1. Download Git for Windows from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "  2. Download the $gitArch version" -ForegroundColor Yellow
    Write-Host "  3. Run the installer with default settings" -ForegroundColor Yellow
    Write-Host "  4. Restart PowerShell" -ForegroundColor Yellow
    Write-Host "  5. Run this script again" -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "Have you installed Git? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        return Test-Git
    }
    
    return $false
}

# Configure Go environment
function Set-GoEnvironment {
    Write-SectionHeader "Configuring Go Environment"
    
    try {
        $goPath = go env GOPATH
        $goRoot = go env GOROOT
        
        Write-ColorOutput "GOROOT: $goRoot" "Info"
        Write-ColorOutput "GOPATH: $goPath" "Info"
        
        # Check if GOPATH/bin is in PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $goBinPath = "$goPath\bin"
        
        if ($currentPath -notlike "*$goBinPath*") {
            Write-ColorOutput "Adding GOPATH/bin to PATH..." "Info"
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$goBinPath", "User")
            $env:Path += ";$goBinPath"
            Write-ColorOutput "Added $goBinPath to PATH" "Success"
        } else {
            Write-ColorOutput "GOPATH/bin is already in PATH" "Success"
        }
        
        # Configure Go proxy
        Write-ColorOutput "Configuring Go proxy..." "Info"
        & go env -w GOPROXY=https://proxy.golang.org,direct
        Write-ColorOutput "Go proxy configured" "Success"
        
        return $true
    } catch {
        Write-ColorOutput "Error configuring Go environment: $_" "Error"
        return $false
    }
}

# Install Go development tools
function Install-GoTools {
    Write-SectionHeader "Installing Go Development Tools"
    
    $tools = @(
        "google.golang.org/protobuf/cmd/protoc-gen-go@latest",
        "google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest",
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    )
    
    foreach ($tool in $tools) {
        Write-ColorOutput "Installing $tool..." "Info"
        try {
            & go install $tool
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Installed $tool" "Success"
            } else {
                Write-ColorOutput "Failed to install $tool" "Warning"
            }
        } catch {
            Write-ColorOutput "Error installing ${tool}: $_" "Warning"
        }
    }
    
    return $true
}

# Setup environment configuration
function Set-ProjectEnvironment {
    Write-SectionHeader "Setting Up Project Environment"
    
    $dockerDir = Join-Path $PSScriptRoot "..\..\docker"
    $envFile = Join-Path $dockerDir ".env"
    $envExample = Join-Path $dockerDir ".env.example"
    
    if (Test-Path $envExample) {
        if (-not (Test-Path $envFile)) {
            Write-ColorOutput "Creating .env file from template..." "Info"
            Copy-Item $envExample $envFile
            Write-ColorOutput "Created .env file" "Success"
            Write-ColorOutput "You may want to customize $envFile" "Info"
        } else {
            Write-ColorOutput ".env file already exists" "Success"
        }
    } else {
        Write-ColorOutput ".env.example not found, skipping environment setup" "Warning"
    }
    
    return $true
}

# Download project dependencies
function Install-Dependencies {
    Write-SectionHeader "Installing Project Dependencies"
    
    $cliDir = Join-Path $PSScriptRoot "..\..\tools\cli"
    
    if (Test-Path $cliDir) {
        Write-ColorOutput "Downloading Go module dependencies..." "Info"
        
        Push-Location $cliDir
        try {
            & go mod download
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Dependencies downloaded successfully" "Success"
            } else {
                Write-ColorOutput "Failed to download some dependencies" "Warning"
            }
            
            & go mod tidy
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Dependencies tidied successfully" "Success"
            }
        } catch {
            Write-ColorOutput "Error downloading dependencies: $_" "Error"
        } finally {
            Pop-Location
        }
    } else {
        Write-ColorOutput "CLI directory not found, skipping dependency installation" "Warning"
    }
    
    return $true
}

# Build the project
function Build-Project {
    Write-SectionHeader "Building Project"
    
    if ($SkipBuild) {
        Write-ColorOutput "Skipping build (--SkipBuild specified)" "Info"
        return $true
    }
    
    $cliDir = Join-Path $PSScriptRoot "..\..\tools\cli"
    $binDir = Join-Path $PSScriptRoot "..\..\bin"
    
    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir | Out-Null
    }
    
    if (Test-Path $cliDir) {
        Write-ColorOutput "Building CLI tool..." "Info"
        
        Push-Location $cliDir
        try {
            $outputPath = Join-Path $binDir "saas.exe"
            & go build -o $outputPath .
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Build completed successfully" "Success"
                Write-ColorOutput "Binary location: $outputPath" "Info"
                return $true
            } else {
                Write-ColorOutput "Build failed" "Error"
                return $false
            }
        } catch {
            Write-ColorOutput "Error building project: $_" "Error"
            return $false
        } finally {
            Pop-Location
        }
    } else {
        Write-ColorOutput "CLI directory not found, skipping build" "Warning"
        return $false
    }
}

# Run tests
function Invoke-Tests {
    Write-SectionHeader "Running Tests"
    
    if ($SkipTests) {
        Write-ColorOutput "Skipping tests (--SkipTests specified)" "Info"
        return $true
    }
    
    $cliDir = Join-Path $PSScriptRoot "..\..\tools\cli"
    
    if (Test-Path $cliDir) {
        Write-ColorOutput "Running unit tests..." "Info"
        
        Push-Location $cliDir
        try {
            & go test -v ./...
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "All tests passed" "Success"
                return $true
            } else {
                Write-ColorOutput "Some tests failed" "Warning"
                return $false
            }
        } catch {
            Write-ColorOutput "Error running tests: $_" "Error"
            return $false
        } finally {
            Pop-Location
        }
    } else {
        Write-ColorOutput "CLI directory not found, skipping tests" "Warning"
        return $true
    }
}

# Print summary
function Show-Summary {
    param(
        [hashtable]$Results
    )
    
    Write-SectionHeader "Setup Summary"
    
    Write-Host ""
    foreach ($key in $Results.Keys) {
        $status = if ($Results[$key]) { "✓" } else { "✗" }
        $color = if ($Results[$key]) { "Green" } else { "Red" }
        Write-Host "  $status $key" -ForegroundColor $color
    }
    Write-Host ""
    
    $allSuccess = $true
    foreach ($value in $Results.Values) {
        if (-not $value) {
            $allSuccess = $false
            break
        }
    }
    
    if ($allSuccess) {
        Write-ColorOutput "✨ Setup completed successfully!" "Success"
        Write-Host ""
        Write-ColorOutput "Next steps:" "Info"
        Write-Host "  1. Read the documentation: docs\WINDOWS_SETUP.md" -ForegroundColor Yellow
        Write-Host "  2. Start using WSL2 for development: wsl" -ForegroundColor Yellow
        Write-Host "  3. Navigate to project: cd /mnt/c/Users/$env:USERNAME/..." -ForegroundColor Yellow
        Write-Host "  4. Run services: make start" -ForegroundColor Yellow
        Write-Host "  5. Check status: make status" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-ColorOutput "⚠ Setup completed with some issues" "Warning"
        Write-Host ""
        Write-ColorOutput "Please review the errors above and:" "Info"
        Write-Host "  1. Follow the manual installation instructions" -ForegroundColor Yellow
        Write-Host "  2. Check the troubleshooting guide: docs\WINDOWS_SETUP.md" -ForegroundColor Yellow
        Write-Host "  3. Run this script again after fixing issues" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "║      Go Framework - Windows Setup Script                 ║" -ForegroundColor White
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-ColorOutput "This script will set up your development environment" "Info"
    Write-ColorOutput "Estimated time: 20-45 minutes" "Info"
    Write-Host ""
    
    # Check if running as admin
    if (Test-Administrator) {
        Write-ColorOutput "Running with administrator privileges" "Info"
    } else {
        Write-ColorOutput "Not running as administrator (some features may require admin)" "Warning"
    }
    
    $results = @{}
    
    # Check Windows version
    $results["Windows Version Check"] = Test-WindowsVersion
    if (-not $results["Windows Version Check"]) {
        Write-ColorOutput "Cannot continue with incompatible Windows version" "Error"
        return
    }
    
    # Get system architecture
    Get-SystemArchitecture | Out-Null
    
    # Check/Install WSL2
    if (-not (Test-WSL2)) {
        $installed = Install-WSL2
        $results["WSL2 Installation"] = $installed
        if ($installed -and -not $Force) {
            Write-ColorOutput "Please restart your computer and run this script again" "Warning"
            return
        }
    } else {
        $results["WSL2 Installation"] = $true
    }
    
    # Check/Install Docker
    if (-not (Test-Docker)) {
        $installed = Install-Docker
        $results["Docker Installation"] = $installed
    } else {
        $results["Docker Installation"] = $true
    }
    
    # Check/Install Go
    if (-not (Test-Go)) {
        $installed = Install-Go
        $results["Go Installation"] = $installed
        if ($installed) {
            Write-ColorOutput "Please restart PowerShell and run this script again" "Warning"
            return
        }
    } else {
        $results["Go Installation"] = $true
    }
    
    # Check/Install Git
    if (-not (Test-Git)) {
        $installed = Install-Git
        $results["Git Installation"] = $installed
        if ($installed) {
            Write-ColorOutput "Please restart PowerShell and run this script again" "Warning"
            return
        }
    } else {
        $results["Git Installation"] = $true
    }
    
    # Configure Go environment
    $results["Go Environment"] = Set-GoEnvironment
    
    # Install Go tools
    $results["Go Development Tools"] = Install-GoTools
    
    # Setup project environment
    $results["Project Environment"] = Set-ProjectEnvironment
    
    # Install dependencies
    $results["Project Dependencies"] = Install-Dependencies
    
    # Build project
    $results["Project Build"] = Build-Project
    
    # Run tests
    $results["Tests"] = Invoke-Tests
    
    # Show summary
    Show-Summary -Results $results
}

# Run main function
Main
