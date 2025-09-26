# Git Status Script
# Shows the installation status of Git

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "         Git Installation Status" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Git is installed
$gitInstalled = $false
try {
    $gitVersion = git --version
    $gitInstalled = $true
    Write-Host "Status: INSTALLED ✓" -ForegroundColor Green
    Write-Host "Version: $gitVersion" -ForegroundColor White
} catch {
    Write-Host "Status: NOT INSTALLED ✗" -ForegroundColor Red
}

if ($gitInstalled) {
    # Check Git path
    $gitPath = (Get-Command git -ErrorAction SilentlyContinue).Source
    Write-Host "Location: $gitPath" -ForegroundColor White
    
    # Check if it's in PATH
    $inPath = $env:PATH -split ';' | Where-Object { $_ -like "*git*" }
    if ($inPath) {
        Write-Host "PATH Status: ✓ Available in system PATH" -ForegroundColor Green
    } else {
        Write-Host "PATH Status: ⚠ May not be properly configured in PATH" -ForegroundColor Yellow
    }
    
    # Check configuration
    $userName = git config --global user.name 2>$null
    $userEmail = git config --global user.email 2>$null
    
    Write-Host ""
    Write-Host "Configuration Status:" -ForegroundColor White
    if ($userName) {
        Write-Host "  User Name: ✓ $userName" -ForegroundColor Green
    } else {
        Write-Host "  User Name: ✗ Not configured" -ForegroundColor Red
    }
    
    if ($userEmail) {
        Write-Host "  User Email: ✓ $userEmail" -ForegroundColor Green
    } else {
        Write-Host "  User Email: ✗ Not configured" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "Git needs to be installed to use version control features." -ForegroundColor Yellow
}

Write-Host ""