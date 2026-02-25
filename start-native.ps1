# LegaStream Native Startup Script
Write-Host "🚀 Starting LegaStream AI Agentic OS (Native Mode)..." -ForegroundColor Green

# Check if Ruby is available
try {
    ruby --version | Out-Null
    Write-Host "✓ Ruby is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Ruby not found. Please install Ruby first." -ForegroundColor Red
    exit 1
}

# Check if Node.js is available
try {
    node --version | Out-Null
    Write-Host "✓ Node.js is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install Node.js first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow

# Start the Ruby backend server in background
Write-Host "📡 Starting Ruby backend server..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-Command", "ruby simple_server.rb" -WindowStyle Minimized

# Wait a moment for backend to start
Start-Sleep -Seconds 2

# Start the React frontend
Write-Host "🎨 Starting React frontend..." -ForegroundColor Cyan
Set-Location frontend
Start-Process powershell -ArgumentList "-Command", "npm run dev" -WindowStyle Normal

Write-Host ""
Write-Host "🎉 LegaStream is starting up!" -ForegroundColor Green
Write-Host "📊 Frontend: http://localhost:5173" -ForegroundColor Cyan
Write-Host "🔧 Backend: http://localhost:6000" -ForegroundColor Cyan
Write-Host "📊 Health Check: http://localhost:6000/up" -ForegroundColor Cyan

Write-Host ""
Write-Host "✨ Demo Features Available:" -ForegroundColor Yellow
Write-Host "  • Dashboard with mock data" -ForegroundColor Gray
Write-Host "  • Document upload simulation" -ForegroundColor Gray
Write-Host "  • Live Logic Terminal with AI reasoning" -ForegroundColor Gray
Write-Host "  • Authentication (use any email/password)" -ForegroundColor Gray

Write-Host ""
Write-Host "🛑 To stop: Close both PowerShell windows" -ForegroundColor Yellow