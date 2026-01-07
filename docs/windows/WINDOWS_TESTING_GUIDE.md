# Windows Installation Testing Guide

This document provides instructions for testing the Windows installation process, particularly for custom paths like `E:\go\go-framework`.

## Test Scenarios

### Scenario 1: Default Path Installation (C: Drive)

**Objective:** Verify installation works with default Windows user directory.

**Test Path:** `C:\Users\<Username>\workspace\go-platform\go-framework`

**Steps:**
1. Open PowerShell (as Administrator)
2. Create workspace directory:
   ```powershell
   mkdir -p $HOME\workspace\go-platform
   cd $HOME\workspace\go-platform
   ```
3. Clone repository:
   ```powershell
   git clone https://github.com/vhvplatform/go-framework.git
   cd go-framework
   ```
4. Run automated setup:
   ```powershell
   .\scripts\setup\setup-windows.ps1
   ```
5. Verify in WSL2:
   ```bash
   wsl
   cd /mnt/c/Users/<Username>/workspace/go-platform/go-framework
   make build-cli
   make start
   make status
   make stop
   ```

**Expected Results:**
- ✅ All setup steps complete without errors
- ✅ CLI tool builds successfully
- ✅ Docker services start and are healthy
- ✅ Make commands work correctly

---

### Scenario 2: E: Drive Installation

**Objective:** Verify installation works with custom path on E: drive.

**Test Path:** `E:\go\go-framework`

**Prerequisites:**
- E: drive exists and is accessible
- Minimum 20GB free space on E:
- Write permissions on E: drive

**Steps:**
1. Open PowerShell (as Administrator)
2. Verify E: drive:
   ```powershell
   Get-PSDrive -Name E
   Get-PSDrive -Name E | Select-Object Name, Used, Free
   ```
3. Create directory:
   ```powershell
   New-Item -Path E:\go -ItemType Directory -Force
   cd E:\go
   ```
4. Clone repository:
   ```powershell
   git clone https://github.com/vhvplatform/go-framework.git
   cd go-framework
   ```
5. Configure Git:
   ```powershell
   git config core.autocrlf false
   git config core.eol lf
   ```
6. Run automated setup with custom path:
   ```powershell
   .\scripts\setup\setup-windows.ps1 -InstallPath "E:\go\go-framework"
   ```
7. Verify in WSL2:
   ```bash
   wsl
   cd /mnt/e/go/go-framework
   pwd  # Should show: /mnt/e/go/go-framework
   ls -la
   chmod +x scripts/**/*.sh
   make build-cli
   make start
   make status
   make stop
   ```

**Expected Results:**
- ✅ E: drive accessible from both PowerShell and WSL2
- ✅ Setup script detects custom path correctly
- ✅ All dependencies install successfully
- ✅ CLI tool builds at E:\go\go-framework\bin\saas.exe
- ✅ Docker services start from WSL2 path
- ✅ All services healthy
- ✅ Make commands work correctly

---

### Scenario 3: Different Drive (D:, F:, etc.)

**Objective:** Verify installation works with any available drive letter.

**Test Path:** `D:\projects\go-framework` (or F:, G:, etc.)

**Steps:**
1. Replace E: with your target drive in Scenario 2
2. Adjust paths accordingly
3. Follow same verification steps

**Expected Results:**
- ✅ Same as Scenario 2 with different drive letter
- ✅ WSL2 path is `/mnt/d/projects/go-framework` (adjust as needed)

---

### Scenario 4: Path with Subdirectories

**Objective:** Verify installation works with nested directory structure.

**Test Path:** `E:\development\projects\go\go-framework`

**Steps:**
1. Create nested directory structure:
   ```powershell
   New-Item -Path E:\development\projects\go -ItemType Directory -Force
   cd E:\development\projects\go
   ```
2. Clone and setup:
   ```powershell
   git clone https://github.com/vhvplatform/go-framework.git
   cd go-framework
   .\scripts\setup\setup-windows.ps1 -InstallPath "E:\development\projects\go\go-framework"
   ```
3. Verify in WSL2:
   ```bash
   wsl
   cd /mnt/e/development/projects/go/go-framework
   make build-cli
   make start
   make status
   ```

**Expected Results:**
- ✅ Nested directories work correctly
- ✅ Long paths don't cause issues
- ✅ All functionality works as expected

---

## Testing Checklist

Use this checklist for each test scenario:

### Pre-Installation Tests
- [ ] Drive exists and is accessible
- [ ] Sufficient free space (20GB+)
- [ ] Write permissions verified
- [ ] WSL2 installed and working
- [ ] Docker Desktop installed and running
- [ ] Go installed (1.21+)
- [ ] Git installed (2.0+)

### Installation Tests
- [ ] Repository clones successfully
- [ ] Git line endings configured correctly
- [ ] Setup script runs without errors
- [ ] All dependencies install successfully
- [ ] Environment variables set correctly
- [ ] Go tools install successfully
- [ ] Project dependencies download
- [ ] CLI tool builds successfully

### Post-Installation Tests
- [ ] Binary exists at expected path
- [ ] CLI tool runs: `.\bin\saas.exe --help`
- [ ] WSL2 can access installation path
- [ ] File permissions correct in WSL2
- [ ] Scripts are executable
- [ ] `make build-cli` works
- [ ] `make start` starts all services
- [ ] `make status` shows all services healthy
- [ ] All service URLs accessible
- [ ] `make logs` shows service logs
- [ ] `make stop` stops services cleanly

### Compatibility Tests
- [ ] Make commands work from correct directory
- [ ] Relative paths resolve correctly
- [ ] Docker volumes mount correctly
- [ ] Environment variables accessible
- [ ] No path length issues (Windows MAX_PATH)
- [ ] No permission errors
- [ ] No line ending issues (CRLF vs LF)

### Performance Tests
- [ ] File operations are responsive
- [ ] Build times are reasonable
- [ ] Docker startup time acceptable
- [ ] No slow file access
- [ ] WSL2 performance good

### Documentation Tests
- [ ] README.md quick start works
- [ ] WINDOWS_SETUP.md manual steps work
- [ ] WINDOWS_E_DRIVE_EXAMPLE.md is accurate
- [ ] WINDOWS_VALIDATION_CHECKLIST.md covers all items
- [ ] Troubleshooting guides are helpful
- [ ] Examples match actual behavior

---

## Test Results Template

```
Test Date: _______________
Tester: _______________
Windows Version: _______________
WSL2 Version: _______________
Docker Version: _______________
Go Version: _______________

Scenario: [ ] 1 - Default Path  [ ] 2 - E: Drive  [ ] 3 - Other Drive  [ ] 4 - Nested Path

Installation Path: _______________________________________________

Results:
[ ] PASS - All tests passed
[ ] PARTIAL - Some issues encountered
[ ] FAIL - Major issues preventing use

Issues Encountered:
_______________________________________________
_______________________________________________
_______________________________________________

Resolution Steps Taken:
_______________________________________________
_______________________________________________
_______________________________________________

Performance Notes:
_______________________________________________
_______________________________________________

Documentation Issues:
_______________________________________________
_______________________________________________

Recommendations:
_______________________________________________
_______________________________________________

Overall Assessment:
[ ] Ready for production use
[ ] Needs minor improvements
[ ] Needs major improvements

Notes:
_______________________________________________
_______________________________________________
_______________________________________________
```

---

## Automated Testing Script

For automated validation, use this PowerShell script:

```powershell
# Save as: test-windows-installation.ps1
param(
    [string]$InstallPath = "E:\go\go-framework"
)

Write-Host "Testing Windows Installation at: $InstallPath" -ForegroundColor Cyan

$results = @{}

# Test 1: Check if path exists
$results["Path Exists"] = Test-Path $InstallPath
Write-Host "Path exists: $($results['Path Exists'])" -ForegroundColor $(if($results["Path Exists"]){"Green"}else{"Red"})

# Test 2: Check if CLI tool exists
$cliPath = Join-Path $InstallPath "bin\saas.exe"
$results["CLI Exists"] = Test-Path $cliPath
Write-Host "CLI exists: $($results['CLI Exists'])" -ForegroundColor $(if($results["CLI Exists"]){"Green"}else{"Red"})

# Test 3: Check if docker directory exists
$dockerPath = Join-Path $InstallPath "docker"
$results["Docker Dir Exists"] = Test-Path $dockerPath
Write-Host "Docker dir exists: $($results['Docker Dir Exists'])" -ForegroundColor $(if($results["Docker Dir Exists"]){"Green"}else{"Red"})

# Test 4: Check if .env file exists
$envPath = Join-Path $dockerPath ".env"
$results["Env File Exists"] = Test-Path $envPath
Write-Host "Env file exists: $($results['Env File Exists'])" -ForegroundColor $(if($results["Env File Exists"]){"Green"}else{"Red"})

# Test 5: Check if Makefile exists
$makefilePath = Join-Path $InstallPath "Makefile"
$results["Makefile Exists"] = Test-Path $makefilePath
Write-Host "Makefile exists: $($results['Makefile Exists'])" -ForegroundColor $(if($results["Makefile Exists"]){"Green"}else{"Red"})

# Test 6: Run CLI tool
if ($results["CLI Exists"]) {
    try {
        $output = & $cliPath --help 2>&1
        $results["CLI Runs"] = $output -match "SaaS Platform"
        Write-Host "CLI runs: $($results['CLI Runs'])" -ForegroundColor $(if($results["CLI Runs"]){"Green"}else{"Red"})
    } catch {
        $results["CLI Runs"] = $false
        Write-Host "CLI runs: False" -ForegroundColor Red
    }
}

# Test 7: Check WSL2 access
$wslPath = $InstallPath -replace '\\', '/' -replace '^([A-Za-z]):', '/mnt/$1' -replace '/mnt/([A-Za-z])', { '/mnt/' + $_.Groups[1].Value.ToLower() }
try {
    $wslCheck = wsl test -d "$wslPath" 2>&1
    $results["WSL Access"] = $LASTEXITCODE -eq 0
    Write-Host "WSL access: $($results['WSL Access'])" -ForegroundColor $(if($results["WSL Access"]){"Green"}else{"Red"})
} catch {
    $results["WSL Access"] = $false
    Write-Host "WSL access: False" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
$passed = ($results.Values | Where-Object { $_ -eq $true }).Count
$total = $results.Count
Write-Host "Passed: $passed / $total" -ForegroundColor $(if($passed -eq $total){"Green"}else{"Yellow"})

if ($passed -eq $total) {
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed" -ForegroundColor Yellow
    exit 1
}
```

---

## Manual Testing Commands

Quick reference for manual testing:

### PowerShell Commands
```powershell
# Navigate to installation
cd E:\go\go-framework

# Check structure
Get-ChildItem

# Run CLI
.\bin\saas.exe --help
.\bin\saas.exe status

# Check Git config
git config --get core.autocrlf
git config --get core.eol
```

### WSL2 Commands
```bash
# Navigate to installation
cd /mnt/e/go/go-framework

# Check structure
ls -la

# Check permissions
ls -la scripts/setup/

# Make scripts executable
chmod +x scripts/**/*.sh

# Build CLI
make build-cli

# Start services
make start

# Check status
make status

# View logs
make logs

# Stop services
make stop
```

### Docker Commands
```bash
# Check Docker
docker --version
docker ps

# Check containers
docker ps -a

# Check volumes
docker volume ls

# Check networks
docker network ls
```

---

## Troubleshooting During Testing

### If Setup Script Fails

1. **Check prerequisites:**
   ```powershell
   go version
   git --version
   docker --version
   wsl --status
   ```

2. **Check permissions:**
   ```powershell
   # Test write access
   New-Item -Path E:\go\test.txt -ItemType File
   Remove-Item -Path E:\go\test.txt
   ```

3. **Check disk space:**
   ```powershell
   Get-PSDrive -Name E | Select-Object Name, Used, Free
   ```

### If WSL2 Access Fails

1. **Verify WSL2 is running:**
   ```powershell
   wsl --status
   ```

2. **Check mount:**
   ```bash
   mount | grep /mnt/e
   ```

3. **Remount if needed:**
   ```bash
   sudo umount /mnt/e
   sudo mount -t drvfs E: /mnt/e
   ```

### If Services Don't Start

1. **Check Docker Desktop is running**
2. **Check port availability:**
   ```powershell
   netstat -ano | findstr :8080
   ```
3. **Check Docker resources in Settings**
4. **View detailed logs:**
   ```bash
   cd /mnt/e/go/go-framework
   make logs
   ```

---

## Continuous Testing

For ongoing validation:

1. **After Windows Updates:**
   - Verify WSL2 still works
   - Check Docker Desktop compatibility
   - Rerun installation tests

2. **After Repository Updates:**
   - Pull latest changes
   - Rebuild CLI tool
   - Restart services
   - Verify all functionality

3. **After System Changes:**
   - Drive changes (if E: is external)
   - Antivirus updates
   - System configuration changes

---

## Reporting Issues

When reporting installation issues, include:

1. **Test scenario used** (1-4)
2. **Installation path** (exact path)
3. **Windows version** (`winver`)
4. **WSL2 version** (`wsl --status`)
5. **Error messages** (full output)
6. **Steps that failed** (specific commands)
7. **Test results template** (filled out)

Submit to: https://github.com/vhvplatform/go-framework/issues

---

## Success Criteria

Installation testing is successful when:

- ✅ All scenarios work without errors
- ✅ Documentation is accurate and complete
- ✅ Setup script handles all paths correctly
- ✅ WSL2 integration works seamlessly
- ✅ Docker services start and run properly
- ✅ All make commands function correctly
- ✅ Performance is acceptable
- ✅ No critical issues identified
- ✅ Troubleshooting guides are effective

---

**For complete validation, use the [Windows Validation Checklist](WINDOWS_VALIDATION_CHECKLIST.md).**
