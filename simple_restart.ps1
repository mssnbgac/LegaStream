# Simple Server Restart
Write-Host "Stopping Ruby processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*ruby*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Starting server..." -ForegroundColor Green
Write-Host ""

# Start backend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; ruby production_server.rb"

# Wait a bit for backend to start
Start-Sleep -Seconds 3

# Start frontend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD/frontend'; npm run dev"

Write-Host ""
Write-Host "Server restarted!" -ForegroundColor Green
Write-Host "Backend: http://localhost:4567" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:5173" -ForegroundColor Cyan
Write-Host ""
Write-Host "The deduplication fix is now active!" -ForegroundColor Yellow
