# PowerShell Profile for Essential Windows Development Tools
# This profile enhances PowerShell with development tools and productivity features

# Import Oh My Posh if available
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # Load Oh My Posh theme
    $themePath = Join-Path $PSScriptRoot "oh-my-posh-theme.json"
    if (Test-Path $themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
    } else {
        # Fallback to default theme
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
    }
}

# Import PSReadLine for enhanced command line editing
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
}

# Import Git aliases if Git is available
if (Get-Command git -ErrorAction SilentlyContinue) {
    # Git aliases
    Set-Alias -Name g -Value git
    Set-Alias -Name gs -Value "git status"
    Set-Alias -Name ga -Value "git add"
    Set-Alias -Name gc -Value "git commit"
    Set-Alias -Name gp -Value "git push"
    Set-Alias -Name gl -Value "git pull"
    Set-Alias -Name gd -Value "git diff"
    Set-Alias -Name gb -Value "git branch"
    Set-Alias -Name gco -Value "git checkout"
    Set-Alias -Name gcm -Value "git checkout main"
    Set-Alias -Name gcb -Value "git checkout -b"
    Set-Alias -Name gst -Value "git stash"
    Set-Alias -Name gsp -Value "git stash pop"
    Set-Alias -Name glog -Value "git log --oneline --graph --decorate"
}

# Docker aliases if Docker is available
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Set-Alias -Name d -Value docker
    Set-Alias -Name dc -Value "docker-compose"
    Set-Alias -Name dps -Value "docker ps"
    Set-Alias -Name dpa -Value "docker ps -a"
    Set-Alias -Name di -Value "docker images"
    Set-Alias -Name drm -Value "docker rm"
    Set-Alias -Name drmi -Value "docker rmi"
    Set-Alias -Name dexec -Value "docker exec -it"
}

# Cloud CLI aliases
if (Get-Command aws -ErrorAction SilentlyContinue) {
    Set-Alias -Name aws -Value aws
}

if (Get-Command az -ErrorAction SilentlyContinue) {
    Set-Alias -Name az -Value az
}

if (Get-Command gcloud -ErrorAction SilentlyContinue) {
    Set-Alias -Name gcloud -Value gcloud
}

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Set-Alias -Name k -Value kubectl
    Set-Alias -Name kctx -Value "kubectl config use-context"
    Set-Alias -Name kns -Value "kubectl config set-context --current --namespace"
}

# VS Code aliases
if (Get-Command code -ErrorAction SilentlyContinue) {
    Set-Alias -Name c -Value code
    Set-Alias -Name c. -Value "code ."
    Set-Alias -Name cn -Value "code --new-window"
}

# Windows Terminal aliases
if (Get-Command wt -ErrorAction SilentlyContinue) {
    Set-Alias -Name wt -Value wt
    Set-Alias -Name wtn -Value "wt new-tab"
    Set-Alias -Name wtp -Value "wt new-pane"
}

# Utility functions
function Get-CloudStatus {
    <#
    .SYNOPSIS
    Shows the status of cloud CLI tools and authentication.
    #>
    Write-Host "=== Cloud CLI Status ===" -ForegroundColor Cyan
    
    # AWS
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        try {
            $awsIdentity = aws sts get-caller-identity 2>$null
            if ($awsIdentity) {
                Write-Host "✓ AWS CLI: Authenticated" -ForegroundColor Green
            } else {
                Write-Host "⚠ AWS CLI: Not authenticated" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "✗ AWS CLI: Error" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ AWS CLI: Not installed" -ForegroundColor Red
    }
    
    # Azure
    if (Get-Command az -ErrorAction SilentlyContinue) {
        try {
            $azAccount = az account show 2>$null
            if ($azAccount) {
                Write-Host "✓ Azure CLI: Authenticated" -ForegroundColor Green
            } else {
                Write-Host "⚠ Azure CLI: Not authenticated" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "✗ Azure CLI: Error" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Azure CLI: Not installed" -ForegroundColor Red
    }
    
    # Google Cloud
    if (Get-Command gcloud -ErrorAction SilentlyContinue) {
        try {
            $gcloudAuth = gcloud auth list 2>$null
            if ($gcloudAuth) {
                Write-Host "✓ Google Cloud SDK: Authenticated" -ForegroundColor Green
            } else {
                Write-Host "⚠ Google Cloud SDK: Not authenticated" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "✗ Google Cloud SDK: Error" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Google Cloud SDK: Not installed" -ForegroundColor Red
    }
}

function Get-DevToolsStatus {
    <#
    .SYNOPSIS
    Shows the status of essential development tools.
    #>
    Write-Host "=== Development Tools Status ===" -ForegroundColor Cyan
    
    $tools = @(
        @{ Name = "Windows Terminal"; Command = "wt --version" },
        @{ Name = "Git"; Command = "git --version" },
        @{ Name = "VS Code"; Command = "code --version" },
        @{ Name = "Docker"; Command = "docker --version" },
        @{ Name = "Oh My Posh"; Command = "oh-my-posh --version" }
    )
    
    foreach ($tool in $tools) {
        try {
            $version = Invoke-Expression $tool.Command 2>$null
            if ($version) {
                Write-Host "✓ $($tool.Name): $($version[0])" -ForegroundColor Green
            }
        } catch {
            Write-Host "✗ $($tool.Name): Not found" -ForegroundColor Red
        }
    }
}

function Start-DevEnvironment {
    <#
    .SYNOPSIS
    Starts a development environment with common tools.
    #>
    Write-Host "Starting development environment..." -ForegroundColor Cyan
    
    # Start Windows Terminal with development profile
    if (Get-Command wt -ErrorAction SilentlyContinue) {
        wt new-tab --profile "PowerShell" --title "Development"
        wt new-tab --profile "Ubuntu" --title "WSL"
        wt new-tab --profile "Git Bash" --title "Git"
    }
}

function Set-DevAliases {
    <#
    .SYNOPSIS
    Sets up development aliases and shortcuts.
    #>
    Write-Host "Setting up development aliases..." -ForegroundColor Cyan
    
    # Common development commands
    Set-Alias -Name ll -Value "Get-ChildItem -Force"
    Set-Alias -Name la -Value "Get-ChildItem -Force -Hidden"
    Set-Alias -Name ls -Value "Get-ChildItem"
    Set-Alias -Name cat -Value "Get-Content"
    Set-Alias -Name grep -Value "Select-String"
    Set-Alias -Name find -Value "Get-ChildItem -Recurse -Name"
    Set-Alias -Name which -Value "Get-Command"
    Set-Alias -Name touch -Value "New-Item -ItemType File -Force"
    Set-Alias -Name mkdir -Value "New-Item -ItemType Directory -Force"
    Set-Alias -Name rmdir -Value "Remove-Item -Recurse -Force"
    Set-Alias -Name cp -Value "Copy-Item"
    Set-Alias -Name mv -Value "Move-Item"
    Set-Alias -Name rm -Value "Remove-Item"
    
    Write-Host "Development aliases set up successfully!" -ForegroundColor Green
}

# Initialize development environment
Set-DevAliases

# Welcome message
Write-Host "`n=== Essential Windows Development Tools ===" -ForegroundColor Magenta
Write-Host "PowerShell profile loaded with development enhancements!" -ForegroundColor Green
Write-Host "`nAvailable commands:" -ForegroundColor Yellow
Write-Host "  Get-CloudStatus    - Check cloud CLI authentication" -ForegroundColor White
Write-Host "  Get-DevToolsStatus - Check development tools status" -ForegroundColor White
Write-Host "  Start-DevEnvironment - Start development environment" -ForegroundColor White
Write-Host "  Set-DevAliases     - Set up development aliases" -ForegroundColor White
Write-Host "`nUse 'Get-CloudStatus' to check your cloud CLI authentication status." -ForegroundColor Cyan
