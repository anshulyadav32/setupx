# Frontend Development Super-Module - Multiple modules with CLI interface

param(
    [Parameter(Position=0)]
    [ValidateSet("install", "test", "update", "check", "status", "help")]
    [string]$Action = "install",
    
    [string[]]$Modules = @("all"),
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$Detailed = $false,
    [switch]$Quiet = $false
)

# Super-Module Information
$SuperModuleInfo = @{
    Name = "Frontend Development"
    Version = "1.0.0"
    Description = "Complete Frontend Development Environment"
    Modules = @{
        "web-development" = @{
            Name = "Web Development"
            Description = "Web development tools and frameworks"
            Required = $true
            Priority = 1
            Script = "modules\web-development.ps1"
        }
        "cross-platform-flutter" = @{
            Name = "Flutter Development"
            Description = "Flutter cross-platform development"
            Required = $false
            Priority = 2
            Script = "modules\cross-platform-flutter.ps1"
        }
        "cross-platform-react-native" = @{
            Name = "React Native Development"
            Description = "React Native cross-platform development"
            Required = $false
            Priority = 3
            Script = "modules\cross-platform-react-native.ps1"
        }
        "browsers" = @{
            Name = "Web Browsers"
            Description = "Web browsers for testing"
            Required = $true
            Priority = 4
            Script = "modules\browsers.ps1"
        }
    }
}

function Write-SuperModuleHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Magenta
        Write-Host "FRONTEND DEVELOPMENT SUPER-MODULE: $Message" -ForegroundColor Magenta
        Write-Host "=" * 60 -ForegroundColor Magenta
    }
}

function Write-SuperModuleStep {
    param([string]$Message, [string]$Status = "INFO")
    if (-not $Quiet) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        switch ($Status) {
            "SUCCESS" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
            "ERROR" { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
            "WARNING" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
            "INFO" { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan }
        }
    }
}

function Install-FrontendDevelopmentSuperModule {
    <#
    .SYNOPSIS
    Install complete frontend development environment
    #>
    param([string[]]$Modules = @("all"))
    
    Write-SuperModuleHeader "Installing Frontend Development Environment"
    
    $results = @{}
    $modulesToInstall = @()
    
    # Determine modules to install
    if ($Modules -contains "all") {
        $modulesToInstall = $SuperModuleInfo.Modules.Keys
    } else {
        $modulesToInstall = $Modules
    }
    
    # Sort by priority
    $modulesToInstall = $modulesToInstall | Sort-Object { $SuperModuleInfo.Modules[$_].Priority }
    
    Write-SuperModuleStep "Installing modules: $($modulesToInstall -join ', ')" "INFO"
    
    foreach ($module in $modulesToInstall) {
        if ($SuperModuleInfo.Modules.ContainsKey($module)) {
            $moduleInfo = $SuperModuleInfo.Modules[$module]
            Write-SuperModuleStep "Installing $($moduleInfo.Name)..." "INFO"
            
            $moduleScript = $moduleInfo.Script
            if (Test-Path $moduleScript) {
                try {
                    $result = & $moduleScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                    $results[$module] = $result
                    Write-SuperModuleStep "$($moduleInfo.Name) installed successfully" "SUCCESS"
                } catch {
                    Write-SuperModuleStep "Failed to install $($moduleInfo.Name): $($_.Exception.Message)" "ERROR"
                    $results[$module] = $false
                }
            } else {
                Write-SuperModuleStep "Module script not found: $moduleScript" "ERROR"
                $results[$module] = $false
            }
        } else {
            Write-SuperModuleStep "Unknown module: $module" "WARNING"
        }
    }
    
    return $results
}

function Test-FrontendDevelopmentSuperModule {
    <#
    .SYNOPSIS
    Test frontend development environment
    #>
    param([string[]]$Modules = @("all"))
    
    Write-SuperModuleHeader "Testing Frontend Development Environment"
    
    $results = @{}
    $modulesToTest = @()
    
    if ($Modules -contains "all") {
        $modulesToTest = $SuperModuleInfo.Modules.Keys
    } else {
        $modulesToTest = $Modules
    }
    
    foreach ($module in $modulesToTest) {
        if ($SuperModuleInfo.Modules.ContainsKey($module)) {
            $moduleInfo = $SuperModuleInfo.Modules[$module]
            Write-SuperModuleStep "Testing $($moduleInfo.Name)..." "INFO"
            
            $moduleScript = $moduleInfo.Script
            if (Test-Path $moduleScript) {
                try {
                    $result = & $moduleScript test -Quiet:$Quiet
                    $results[$module] = $result
                    Write-SuperModuleStep "$($moduleInfo.Name) test completed" "SUCCESS"
                } catch {
                    Write-SuperModuleStep "Failed to test $($moduleInfo.Name): $($_.Exception.Message)" "ERROR"
                    $results[$module] = $false
                }
            } else {
                Write-SuperModuleStep "Module script not found: $moduleScript" "ERROR"
                $results[$module] = $false
            }
        }
    }
    
    return $results
}

function Update-FrontendDevelopmentSuperModule {
    <#
    .SYNOPSIS
    Update frontend development environment
    #>
    param([string[]]$Modules = @("all"))
    
    Write-SuperModuleHeader "Updating Frontend Development Environment"
    
    $results = @{}
    $modulesToUpdate = @()
    
    if ($Modules -contains "all") {
        $modulesToUpdate = $SuperModuleInfo.Modules.Keys
    } else {
        $modulesToUpdate = $Modules
    }
    
    foreach ($module in $modulesToUpdate) {
        if ($SuperModuleInfo.Modules.ContainsKey($module)) {
            $moduleInfo = $SuperModuleInfo.Modules[$module]
            Write-SuperModuleStep "Updating $($moduleInfo.Name)..." "INFO"
            
            $moduleScript = $moduleInfo.Script
            if (Test-Path $moduleScript) {
                try {
                    $result = & $moduleScript update -Quiet:$Quiet
                    $results[$module] = $result
                    Write-SuperModuleStep "$($moduleInfo.Name) updated successfully" "SUCCESS"
                } catch {
                    Write-SuperModuleStep "Failed to update $($moduleInfo.Name): $($_.Exception.Message)" "ERROR"
                    $results[$module] = $false
                }
            } else {
                Write-SuperModuleStep "Module script not found: $moduleScript" "ERROR"
                $results[$module] = $false
            }
        }
    }
    
    return $results
}

function Show-FrontendDevelopmentStatus {
    <#
    .SYNOPSIS
    Show frontend development environment status
    #>
    Write-SuperModuleHeader "Frontend Development Environment Status"
    
    $results = @{}
    
    foreach ($module in $SuperModuleInfo.Modules.Keys) {
        $moduleInfo = $SuperModuleInfo.Modules[$module]
        Write-SuperModuleStep "Checking $($moduleInfo.Name)..." "INFO"
        
        $moduleScript = $moduleInfo.Script
        if (Test-Path $moduleScript) {
            try {
                $result = & $moduleScript status -Quiet:$Quiet
                $results[$module] = $result
            } catch {
                Write-SuperModuleStep "Failed to check $($moduleInfo.Name): $($_.Exception.Message)" "ERROR"
                $results[$module] = $false
            }
        } else {
            Write-SuperModuleStep "Module script not found: $moduleScript" "ERROR"
            $results[$module] = $false
        }
    }
    
    return $results
}

function Show-FrontendDevelopmentHelp {
    <#
    .SYNOPSIS
    Show help for frontend development super-module
    #>
    Write-SuperModuleHeader "Frontend Development Super-Module Help"
    
    Write-Host "`nAvailable Modules:" -ForegroundColor Cyan
    foreach ($module in $SuperModuleInfo.Modules.Keys) {
        $info = $SuperModuleInfo.Modules[$module]
        $required = if ($info.Required) { "Required" } else { "Optional" }
        Write-Host "  $module - $($info.Name) ($required)" -ForegroundColor White
        Write-Host "    $($info.Description)" -ForegroundColor Gray
    }
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\super-modules\frontend-development.ps1 install                    # Install all modules" -ForegroundColor White
    Write-Host "  .\super-modules\frontend-development.ps1 install -Modules web-development,browsers # Install specific modules" -ForegroundColor White
    Write-Host "  .\super-modules\frontend-development.ps1 test                       # Test all modules" -ForegroundColor White
    Write-Host "  .\super-modules\frontend-development.ps1 update                      # Update all modules" -ForegroundColor White
    Write-Host "  .\super-modules\frontend-development.ps1 status                     # Show status" -ForegroundColor White
    Write-Host "  .\super-modules\frontend-development.ps1 help                        # Show this help" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-FrontendDevelopmentSuperModule -Modules $Modules
        Write-SuperModuleStep "Frontend Development Super-Module installation completed!" "SUCCESS"
    }
    "test" {
        $result = Test-FrontendDevelopmentSuperModule -Modules $Modules
        Write-SuperModuleStep "Frontend Development Super-Module testing completed!" "SUCCESS"
    }
    "update" {
        $result = Update-FrontendDevelopmentSuperModule -Modules $Modules
        Write-SuperModuleStep "Frontend Development Super-Module update completed!" "SUCCESS"
    }
    "check" {
        $result = Show-FrontendDevelopmentStatus
        Write-SuperModuleStep "Frontend Development Super-Module status check completed!" "SUCCESS"
    }
    "status" {
        $result = Show-FrontendDevelopmentStatus
        Write-SuperModuleStep "Frontend Development Super-Module status completed!" "SUCCESS"
    }
    "help" {
        Show-FrontendDevelopmentHelp
    }
    default {
        Write-SuperModuleStep "Unknown action: $Action" "ERROR"
        Show-FrontendDevelopmentHelp
        exit 1
    }
}
