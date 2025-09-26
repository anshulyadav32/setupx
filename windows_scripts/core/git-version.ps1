# Git Version Script
# Shows the installed version of Git

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "         Git Version Check" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $gitVersion = git --version
    Write-Host "Git Version: $gitVersion" -ForegroundColor Green
    
    # Show additional version info
    Write-Host ""
    Write-Host "Additional Git Information:" -ForegroundColor White
    
    $gitPath = (Get-Command git -ErrorAction SilentlyContinue).Source
    if ($gitPath) {
        Write-Host "Git Location: $gitPath" -ForegroundColor White
    }
    
    # Show git config
    Write-Host ""
    Write-Host "Git Configuration:" -ForegroundColor White
    git config --list --global | Where-Object { $_ -like "user.*" -or $_ -like "core.*" } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "Git is not installed or not found in PATH" -ForegroundColor Red
}

Write-Host ""