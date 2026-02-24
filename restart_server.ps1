# Restart Server Script
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 79) -ForegroundColor Cyan
Write-Host "  SERVER RESTART SCRIPT" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 79) -ForegroundColor Cyan
Write-Host ""

# Stop any running Ruby processes
Write-Host "🛑 Stopping any running Ruby processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*ruby*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Check if processes are stopped
$rubyProcesses = Get-Process | Where-Object {$_.ProcessName -like "*ruby*"}
if ($rubyProcesses) {
    Write-Host "⚠️  Some Ruby processes are still running. Please close them manually." -ForegroundColor Red
    exit 1
}

Write-Host "✅ All Ruby processes stopped" -ForegroundColor Green
Write-Host ""

# Start the production server
Write-Host "🚀 Starting production server..." -ForegroundColor Yellow
Write-Host ""

# Run the production server
& .\start-production.ps1
