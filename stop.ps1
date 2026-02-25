# LegaStream Stop Script
Write-Host "Stopping LegaStream services..." -ForegroundColor Yellow

docker-compose down

Write-Host "All services stopped" -ForegroundColor Green