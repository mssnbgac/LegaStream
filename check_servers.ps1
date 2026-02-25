# Check if LegaStream servers are running

Write-Host "Checking LegaStream servers..." -ForegroundColor Cyan
Write-Host ""

# Check backend (port 6000)
try {
    $backend = Test-NetConnection -ComputerName localhost -Port 6000 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($backend) {
        Write-Host "[OK] Backend is running on http://localhost:6000" -ForegroundColor Green
    } else {
        Write-Host "[X] Backend is NOT running on port 6000" -ForegroundColor Red
    }
} catch {
    Write-Host "[X] Cannot check backend status" -ForegroundColor Red
}

# Check frontend (port 5173)
try {
    $frontend = Test-NetConnection -ComputerName localhost -Port 5173 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($frontend) {
        Write-Host "[OK] Frontend is running on http://localhost:5173" -ForegroundColor Green
    } else {
        Write-Host "[X] Frontend is NOT running on port 5173" -ForegroundColor Yellow
        Write-Host "     (Frontend may take 10-15 seconds to start)" -ForegroundColor Gray
    }
} catch {
    Write-Host "[X] Cannot check frontend status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Access your application at:" -ForegroundColor Cyan
Write-Host "  http://localhost:5173" -ForegroundColor White
Write-Host ""
