# Restart both backend and frontend servers

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "RESTARTING ALL SERVERS" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Stop all Ruby and Node processes
Write-Host "Stopping all servers..." -ForegroundColor Yellow

Get-Process | Where-Object {$_.ProcessName -like "*ruby*"} | ForEach-Object {
    Write-Host "  Stopping Ruby process $($_.Id)..." -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Get-Process | Where-Object {$_.ProcessName -like "*node*"} | ForEach-Object {
    Write-Host "  Stopping Node process $($_.Id)..." -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 2

# Start servers
Write-Host ""
Write-Host "Starting servers..." -ForegroundColor Yellow
Write-Host ""

# Start backend
Write-Host "Starting backend on port 6000..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-Command", "ruby simple_server.rb" -WindowStyle Minimized

Start-Sleep -Seconds 3

# Start frontend
Write-Host "Starting frontend on port 5173..." -ForegroundColor Cyan
Set-Location frontend
Start-Process powershell -ArgumentList "-Command", "npm run dev" -WindowStyle Normal
Set-Location ..

Start-Sleep -Seconds 3

# Check status
Write-Host ""
Write-Host "Checking server status..." -ForegroundColor Cyan
./check_servers.ps1

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "SERVERS RESTARTED" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
Write-Host ""
Write-Host "Access your application at: http://localhost:5173" -ForegroundColor White
Write-Host ""
