# Load Development Seed Data into MongoDB
# Usage: .\load-seed-data.ps1

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   LOAD SEED DATA" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# MongoDB connection string
$mongoUri = "mongodb://colombo:SASSMongoDB%232627@192.168.1.203:27017/saas_framework?authSource=admin"
$scriptPath = "e:\Go\go-framework\scripts\seed-dev-data.js"

# Check if mongosh is available
Write-Host "Checking mongosh installation..." -ForegroundColor Yellow
$mongoshCheck = Get-Command mongosh -ErrorAction SilentlyContinue
if (-not $mongoshCheck) {
    Write-Host "❌ mongosh not found. Please install MongoDB Shell." -ForegroundColor Red
    Write-Host "Download from: https://www.mongodb.com/try/download/shell" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ mongosh found" -ForegroundColor Green
Write-Host ""

# Check if script file exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Seed script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

# Test MongoDB connection
Write-Host "Testing MongoDB connection..." -ForegroundColor Yellow
$testConnection = mongosh "$mongoUri" --eval "db.adminCommand('ping')" --quiet 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cannot connect to MongoDB" -ForegroundColor Red
    Write-Host "Error: $testConnection" -ForegroundColor Red
    exit 1
}
Write-Host "✓ MongoDB connection successful" -ForegroundColor Green
Write-Host ""

# Load seed data
Write-Host "Loading seed data..." -ForegroundColor Yellow
Write-Host "Script: $scriptPath" -ForegroundColor Gray
Write-Host ""

mongosh "$mongoUri" --file "$scriptPath"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "   SEED DATA LOADED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now start the services and test with:" -ForegroundColor Yellow
    Write-Host "  Email:    admin@test.com" -ForegroundColor Cyan
    Write-Host "  Password: Admin@123" -ForegroundColor Cyan
    Write-Host "  Tenant:   default-tenant" -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Host "❌ Failed to load seed data" -ForegroundColor Red
    exit 1
}

Write-Host ""
