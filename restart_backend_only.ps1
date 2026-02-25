# Restart only the backend server (keep frontend running)

Write-Host "Restarting backend server..." -ForegroundColor Cyan
Write-Host ""

# Find and kill Ruby processes running simple_server.rb
Write-Host "Stopping backend..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*ruby*"} | ForEach-Object {
    Write-Host "  Stopping process $($_.Id)..." -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 2

# Start backend again
Write-Host ""
Write-Host "Starting backend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-Command", "ruby simple_server.rb" -WindowStyle Minimized

Start-Sleep -Seconds 3

# Check if it's running
Write-Host ""
$backend = Test-NetConnection -ComputerName localhost -Port 6000 -InformationLevel Quiet -WarningAction SilentlyContinue

if ($backend) {
    Write-Host "[OK] Backend restarted successfully on http://localhost:6000" -ForegroundColor Green
} else {
    Write-Host "[X] Backend failed to start" -ForegroundColor Red
    Write-Host "    Check the backend window for errors" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Frontend is still running on http://localhost:5173" -ForegroundColor Cyan
Write-Host ""
