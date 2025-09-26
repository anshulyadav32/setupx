# Git Test Script
# Tests if Git is installed and working correctly

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "         Git Test Script" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing Git installation..." -ForegroundColor White

# Check if git command is available
try {
    $gitVersion = git --version
    Write-Host "✓ Git is installed: $gitVersion" -ForegroundColor Green
    
    # Test git config
    $userName = git config --global user.name 2>$null
    $userEmail = git config --global user.email 2>$null
    
    if ($userName -and $userEmail) {
        Write-Host "✓ Git is configured:" -ForegroundColor Green
        Write-Host "  User: $userName" -ForegroundColor White
        Write-Host "  Email: $userEmail" -ForegroundColor White
    } else {
        Write-Host "⚠ Git is not configured with user details" -ForegroundColor Yellow
        Write-Host "  Run: git config --global user.name 'Your Name'" -ForegroundColor White
        Write-Host "  Run: git config --global user.email 'your.email@example.com'" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Git test completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git first." -ForegroundColor White
}

Write-Host ""