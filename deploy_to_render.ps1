# Deploy to Render
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 79) -ForegroundColor Cyan
Write-Host "  DEPLOY TO RENDER" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 79) -ForegroundColor Cyan
Write-Host ""

Write-Host "This will commit and push all changes to GitHub, triggering Render deployment" -ForegroundColor Yellow
Write-Host ""

# Check git status
Write-Host "Checking git status..." -ForegroundColor Cyan
git status

Write-Host ""
Write-Host "Changes to be deployed:" -ForegroundColor Yellow
Write-Host "  - Fixed duplicate entity extraction" -ForegroundColor Green
Write-Host "  - Removed unreliable person name extraction from fallback" -ForegroundColor Green
Write-Host "  - Enhanced entity display with all 10 types" -ForegroundColor Green
Write-Host "  - Improved deduplication logic" -ForegroundColor Green
Write-Host ""

$confirm = Read-Host "Do you want to proceed with deployment? (yes/no)"

if ($confirm -eq "yes") {
    Write-Host ""
    Write-Host "Adding all changes..." -ForegroundColor Cyan
    git add .
    
    Write-Host "Committing changes..." -ForegroundColor Cyan
    git commit -m "Fix: Entity extraction improvements - remove duplicates, enhance UI, fix fallback extraction"
    
    Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
    git push origin main
    
    Write-Host ""
    Write-Host "=" -NoNewline -ForegroundColor Green
    Write-Host ("=" * 79) -ForegroundColor Green
    Write-Host "  DEPLOYMENT INITIATED!" -ForegroundColor Green
    Write-Host "=" -NoNewline -ForegroundColor Green
    Write-Host ("=" * 79) -ForegroundColor Green
    Write-Host ""
    Write-Host "Render will automatically detect the changes and redeploy." -ForegroundColor Yellow
    Write-Host "This usually takes 5-10 minutes." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Monitor deployment at: https://dashboard.render.com" -ForegroundColor Cyan
    Write-Host "Your app: https://legastream.onrender.com" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IMPORTANT: Don't forget to add your Gemini API key to Render environment variables!" -ForegroundColor Red
    Write-Host "  1. Go to https://dashboard.render.com" -ForegroundColor Yellow
    Write-Host "  2. Select your LegaStream service" -ForegroundColor Yellow
    Write-Host "  3. Go to Environment tab" -ForegroundColor Yellow
    Write-Host "  4. Add: GEMINI_API_KEY = AIzaSyCgDuGe3beNs2wVq-KXYhWHPJ0SAP8340g" -ForegroundColor Yellow
    Write-Host "  5. Save and redeploy" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Deployment cancelled." -ForegroundColor Red
}
