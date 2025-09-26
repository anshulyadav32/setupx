# Test PowerShell Script for SetupX
# This is a sample script to demonstrate external terminal execution

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "         SetupX Test Script" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script is running in an external PowerShell terminal!" -ForegroundColor Green
Write-Host ""

Write-Host "Simulating installation process..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Step $i of 5: Processing..." -ForegroundColor White
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "This terminal will remain open. You can:" -ForegroundColor Cyan
Write-Host "- Review the installation output above" -ForegroundColor White
Write-Host "- Run additional commands if needed" -ForegroundColor White
Write-Host "- Close this window when finished" -ForegroundColor White
Write-Host ""