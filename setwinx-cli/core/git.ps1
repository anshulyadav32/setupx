# Git Component Script with Multiple Functions
# This script contains all Git-related functions that can be called with parameters

param(
    [string]$Action = "help",
    [string]$Component = "git"
)

function Show-Header {
    param([string]$Title)
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "         $Title" -ForegroundColor Yellow
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-GitComponent {
    Show-Header "Git Test"
    
    Write-Host "Testing Git installation..." -ForegroundColor White
    
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
        return $true
    } catch {
        Write-Host "✗ Git is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Git first." -ForegroundColor White
        return $false
    }
}

function Get-GitVersion {
    Show-Header "Git Version Check"
    
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
        
        return $gitVersion
    } catch {
        Write-Host "Git is not installed or not found in PATH" -ForegroundColor Red
        return $null
    }
}

function Get-GitStatus {
    Show-Header "Git Installation Status"
    
    # Check if Git is installed
    $gitInstalled = $false
    try {
        $gitVersion = git --version
        $gitInstalled = $true
        Write-Host "Status: INSTALLED ✓" -ForegroundColor Green
        Write-Host "Version: $gitVersion" -ForegroundColor White
    } catch {
        Write-Host "Status: NOT INSTALLED ✗" -ForegroundColor Red
        return $false
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
        
        return $true
    }
    
    return $false
}

function Get-GitPath {
    Show-Header "Git Installation Path"
    
    try {
        $gitPath = (Get-Command git -ErrorAction SilentlyContinue).Source
        if ($gitPath) {
            Write-Host "Git Executable Path:" -ForegroundColor White
            Write-Host "  $gitPath" -ForegroundColor Green
            
            # Show Git installation directory
            $gitDir = Split-Path $gitPath -Parent
            Write-Host ""
            Write-Host "Git Installation Directory:" -ForegroundColor White
            Write-Host "  $gitDir" -ForegroundColor Green
            
            # Show PATH entries related to Git
            Write-Host ""
            Write-Host "PATH Entries containing Git:" -ForegroundColor White
            $env:PATH -split ';' | Where-Object { $_ -like "*git*" } | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
            
            return $gitPath
        } else {
            Write-Host "Git executable not found in PATH" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "Error finding Git path: $_" -ForegroundColor Red
        return $null
    }
}

function Install-GitComponent {
    Show-Header "Git Installation"
    
    Write-Host "Installing Git for Windows..." -ForegroundColor White
    
    # Check if already installed
    try {
        $existing = git --version
        Write-Host "Git is already installed: $existing" -ForegroundColor Yellow
        Write-Host "Use 'update' action to update to the latest version." -ForegroundColor White
        return $true
    } catch {
        # Not installed, proceed with installation
    }
    
    try {
        # Download and install Git
        Write-Host "Downloading Git for Windows..." -ForegroundColor White
        $gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-2.42.0.2-64-bit.exe"
        $tempPath = "$env:TEMP\GitInstaller.exe"
        
        # Use winget if available, otherwise download manually
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Using winget to install Git..." -ForegroundColor Green
            winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        } else {
            Write-Host "Winget not available, using Chocolatey or direct download..." -ForegroundColor Yellow
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                choco install git -y
            } else {
                Write-Host "Please install Git manually from: https://git-scm.com/download/win" -ForegroundColor Red
                return $false
            }
        }
        
        Write-Host "Git installation completed!" -ForegroundColor Green
        Write-Host "Please restart your terminal to use Git." -ForegroundColor Yellow
        return $true
        
    } catch {
        Write-Host "Error installing Git: $_" -ForegroundColor Red
        return $false
    }
}

function Update-GitComponent {
    Show-Header "Git Update"
    
    Write-Host "Updating Git to the latest version..." -ForegroundColor White
    
    try {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Using winget to update Git..." -ForegroundColor Green
            winget upgrade --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Using Chocolatey to update Git..." -ForegroundColor Green
            choco upgrade git -y
        } else {
            Write-Host "Please update Git manually from: https://git-scm.com/download/win" -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "Git update completed!" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "Error updating Git: $_" -ForegroundColor Red
        return $false
    }
}

function Uninstall-GitComponent {
    Show-Header "Git Reinstall (Uninstall + Install)"
    
    Write-Host "Reinstalling Git (this will uninstall and then install)..." -ForegroundColor White
    
    try {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Uninstalling Git..." -ForegroundColor Yellow
            winget uninstall --id Git.Git -e --source winget
            
            Write-Host "Reinstalling Git..." -ForegroundColor Green
            winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Reinstalling with Chocolatey..." -ForegroundColor Green
            choco uninstall git -y
            choco install git -y
        } else {
            Write-Host "Please reinstall Git manually from: https://git-scm.com/download/win" -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "Git reinstallation completed!" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "Error reinstalling Git: $_" -ForegroundColor Red
        return $false
    }
}

function Show-Help {
    Show-Header "Git Component Help"
    
    Write-Host "Available Actions:" -ForegroundColor White
    Write-Host "  test      - Test Git installation and configuration" -ForegroundColor Green
    Write-Host "  version   - Show Git version information" -ForegroundColor Green
    Write-Host "  status    - Check Git installation status" -ForegroundColor Green
    Write-Host "  path      - Show Git installation path" -ForegroundColor Green
    Write-Host "  install   - Install Git for Windows" -ForegroundColor Green
    Write-Host "  update    - Update Git to latest version" -ForegroundColor Green
    Write-Host "  reinstall - Reinstall Git (uninstall + install)" -ForegroundColor Green
    Write-Host "  help      - Show this help message" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor White
    Write-Host "  .\git.ps1 -Action test" -ForegroundColor Gray
    Write-Host "  .\git.ps1 -Action version" -ForegroundColor Gray
    Write-Host "  .\git.ps1 -Action install" -ForegroundColor Gray
}

# Main execution logic
switch ($Action.ToLower()) {
    "test" { Test-GitComponent }
    "version" { Get-GitVersion }
    "status" { Get-GitStatus }
    "path" { Get-GitPath }
    "install" { Install-GitComponent }
    "update" { Update-GitComponent }
    "reinstall" { Uninstall-GitComponent }
    "help" { Show-Help }
    default { 
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Show-Help
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
Read-Host