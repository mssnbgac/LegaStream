# Restart servers and prepare for testing the entity saving fix

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "RESTARTING SERVERS TO APPLY FIX" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Stop servers
Write-Host "Stopping servers..." -ForegroundColor Yellow
& ./stop.ps1

Start-Sleep -Seconds 2

# Start servers
Write-Host ""
Write-Host "Starting servers..." -ForegroundColor Yellow
& ./start.ps1

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "SERVERS RESTARTED - FIX IS NOW ACTIVE" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Go to http://localhost:3000" -ForegroundColor White
Write-Host "  2. Upload a document (e.g., New_York_Employment_Contract.pdf)" -ForegroundColor White
Write-Host "  3. Wait for analysis to complete" -ForegroundColor White
Write-Host "  4. Click 'View Extracted Entities'" -ForegroundColor White
Write-Host "  5. Verify all 17 entities are shown (not just 7)" -ForegroundColor White
Write-Host ""

Write-Host "To run automated test after upload:" -ForegroundColor Cyan
Write-Host "  ruby test_entity_saving_fix.rb" -ForegroundColor White
Write-Host ""

Write-Host "Expected result:" -ForegroundColor Cyan
Write-Host "  Summary: 17 Entities Extracted" -ForegroundColor Green
Write-Host "  Detail:  17 entities found" -ForegroundColor Green
Write-Host "  Success rate: 100%" -ForegroundColor Green
Write-Host ""
