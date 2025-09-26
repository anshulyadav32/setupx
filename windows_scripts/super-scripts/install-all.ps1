# Install Everything - Complete Windows Development Environment

param(
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$Detailed = $false,
    [switch]$Quiet = $false,
    [string[]]$SuperModules = @("all")
)

# Super-Script Information
$SuperScriptInfo = @{
    Name = "Complete Windows Development Environment"
    Version = "1.0.0"
    Description = "Install everything for Windows development"
    SuperModules = @{
        "frontend-development" = @{
            Name = "Frontend Development"
            Description = "Complete frontend development environment"
            Required = $false
            Priority = 1
            Script = "super-modules\frontend-development.ps1"
        }
        "backend-development" = @{
            Name = "Backend Development"
            Description = "Complete backend development environment"
            Required = $false
            Priority = 2
            Script = "super-modules\backend-development.ps1"
        }
        "mobile-development" = @{
            Name = "Mobile Development"
            Description = "Complete mobile development environment"
            Required = $false
            Priority = 3
            Script = "super-modules\mobile-development.ps1"
        }
        "cloud-development" = @{
            Name = "Cloud Development"
            Description = "Complete cloud development environment"
            Required = $false
            Priority = 4
            Script = "super-modules\cloud-development.ps1"
        }
        "ai-development" = @{
            Name = "AI Development"
            Description = "Complete AI development environment"
            Required = $false
            Priority = 5
            Script = "super-modules\ai-development.ps1"
        }
        "server-development" = @{
            Name = "Server Development"
            Description = "Complete server development environment"
            Required = $false
            Priority = 6
            Script = "super-modules\server-development.ps1"
        }
        "basic-development" = @{
            Name = "Basic Development"
            Description = "Basic development tools"
            Required = $true
            Priority = 7
            Script = "super-modules\basic-development.ps1"
        }
    }
}

function Write-SuperScriptHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
        Write-Host "WINDOWS DEVELOPMENT TOOLKIT: $Message" -ForegroundColor Yellow
        Write-Host "=" * 60 -ForegroundColor Yellow
    }
}

function Write-SuperScriptStep {
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

function Install-AllSuperModules {
    <#
    .SYNOPSIS
    Install all super-modules
    #>
    param([string[]]$SuperModules = @("all"))
    
    Write-SuperScriptHeader "Installing Complete Windows Development Environment"
    
    $results = @{}
    $superModulesToInstall = @()
    
    # Determine super-modules to install
    if ($SuperModules -contains "all") {
        $superModulesToInstall = $SuperScriptInfo.SuperModules.Keys
    } else {
        $superModulesToInstall = $SuperModules
    }
    
    # Sort by priority
    $superModulesToInstall = $superModulesToInstall | Sort-Object { $SuperScriptInfo.SuperModules[$_].Priority }
    
    Write-SuperScriptStep "Installing super-modules: $($superModulesToInstall -join ', ')" "INFO"
    
    foreach ($superModule in $superModulesToInstall) {
        if ($SuperScriptInfo.SuperModules.ContainsKey($superModule)) {
            $superModuleInfo = $SuperScriptInfo.SuperModules[$superModule]
            Write-SuperScriptStep "Installing $($superModuleInfo.Name)..." "INFO"
            
            $superModuleScript = $superModuleInfo.Script
            if (Test-Path $superModuleScript) {
                try {
                    $result = & $superModuleScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                    $results[$superModule] = $result
                    Write-SuperScriptStep "$($superModuleInfo.Name) installed successfully" "SUCCESS"
                } catch {
                    Write-SuperScriptStep "Failed to install $($superModuleInfo.Name): $($_.Exception.Message)" "ERROR"
                    $results[$superModule] = $false
                }
            } else {
                Write-SuperScriptStep "Super-module script not found: $superModuleScript" "ERROR"
                $results[$superModule] = $false
            }
        } else {
            Write-SuperScriptStep "Unknown super-module: $superModule" "WARNING"
        }
    }
    
    return $results
}

function Test-AllSuperModules {
    <#
    .SYNOPSIS
    Test all super-modules
    #>
    param([string[]]$SuperModules = @("all"))
    
    Write-SuperScriptHeader "Testing Complete Windows Development Environment"
    
    $results = @{}
    $superModulesToTest = @()
    
    if ($SuperModules -contains "all") {
        $superModulesToTest = $SuperScriptInfo.SuperModules.Keys
    } else {
        $superModulesToTest = $SuperModules
    }
    
    foreach ($superModule in $superModulesToTest) {
        if ($SuperScriptInfo.SuperModules.ContainsKey($superModule)) {
            $superModuleInfo = $SuperScriptInfo.SuperModules[$superModule]
            Write-SuperScriptStep "Testing $($superModuleInfo.Name)..." "INFO"
            
            $superModuleScript = $superModuleInfo.Script
            if (Test-Path $superModuleScript) {
                try {
                    $result = & $superModuleScript test -Quiet:$Quiet
                    $results[$superModule] = $result
                    Write-SuperScriptStep "$($superModuleInfo.Name) test completed" "SUCCESS"
                } catch {
                    Write-SuperScriptStep "Failed to test $($superModuleInfo.Name): $($_.Exception.Message)" "ERROR"
                    $results[$superModule] = $false
                }
            } else {
                Write-SuperScriptStep "Super-module script not found: $superModuleScript" "ERROR"
                $results[$superModule] = $false
            }
        }
    }
    
    return $results
}

function Update-AllSuperModules {
    <#
    .SYNOPSIS
    Update all super-modules
    #>
    param([string[]]$SuperModules = @("all"))
    
    Write-SuperScriptHeader "Updating Complete Windows Development Environment"
    
    $results = @{}
    $superModulesToUpdate = @()
    
    if ($SuperModules -contains "all") {
        $superModulesToUpdate = $SuperScriptInfo.SuperModules.Keys
    } else {
        $superModulesToUpdate = $SuperModules
    }
    
    foreach ($superModule in $superModulesToUpdate) {
        if ($SuperScriptInfo.SuperModules.ContainsKey($superModule)) {
            $superModuleInfo = $SuperScriptInfo.SuperModules[$superModule]
            Write-SuperScriptStep "Updating $($superModuleInfo.Name)..." "INFO"
            
            $superModuleScript = $superModuleInfo.Script
            if (Test-Path $superModuleScript) {
                try {
                    $result = & $superModuleScript update -Quiet:$Quiet
                    $results[$superModule] = $result
                    Write-SuperScriptStep "$($superModuleInfo.Name) updated successfully" "SUCCESS"
                } catch {
                    Write-SuperScriptStep "Failed to update $($superModuleInfo.Name): $($_.Exception.Message)" "ERROR"
                    $results[$superModule] = $false
                }
            } else {
                Write-SuperScriptStep "Super-module script not found: $superModuleScript" "ERROR"
                $results[$superModule] = $false
            }
        }
    }
    
    return $results
}

function Show-AllSuperModulesStatus {
    <#
    .SYNOPSIS
    Show status of all super-modules
    #>
    Write-SuperScriptHeader "Complete Windows Development Environment Status"
    
    $results = @{}
    
    foreach ($superModule in $SuperScriptInfo.SuperModules.Keys) {
        $superModuleInfo = $SuperScriptInfo.SuperModules[$superModule]
        Write-SuperScriptStep "Checking $($superModuleInfo.Name)..." "INFO"
        
        $superModuleScript = $superModuleInfo.Script
        if (Test-Path $superModuleScript) {
            try {
                $result = & $superModuleScript status -Quiet:$Quiet
                $results[$superModule] = $result
            } catch {
                Write-SuperScriptStep "Failed to check $($superModuleInfo.Name): $($_.Exception.Message)" "ERROR"
                $results[$superModule] = $false
            }
        } else {
            Write-SuperScriptStep "Super-module script not found: $superModuleScript" "ERROR"
            $results[$superModule] = $false
        }
    }
    
    return $results
}

function Show-InstallAllHelp {
    <#
    .SYNOPSIS
    Show help for install-all super-script
    #>
    Write-SuperScriptHeader "Install All Super-Script Help"
    
    Write-Host "`nAvailable Super-Modules:" -ForegroundColor Cyan
    foreach ($superModule in $SuperScriptInfo.SuperModules.Keys) {
        $info = $SuperScriptInfo.SuperModules[$superModule]
        $required = if ($info.Required) { "Required" } else { "Optional" }
        Write-Host "  $superModule - $($info.Name) ($required)" -ForegroundColor White
        Write-Host "    $($info.Description)" -ForegroundColor Gray
    }
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\super-scripts\install-all.ps1                                    # Install everything" -ForegroundColor White
    Write-Host "  .\super-scripts\install-all.ps1 -SuperModules frontend-development,backend-development # Install specific super-modules" -ForegroundColor White
    Write-Host "  .\super-scripts\test-all.ps1                                       # Test everything" -ForegroundColor White
    Write-Host "  .\super-scripts\update-all.ps1                                     # Update everything" -ForegroundColor White
    Write-Host "  .\super-scripts\status-all.ps1                                     # Show status of everything" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -SuperModules <modules> - Specific super-modules to install" -ForegroundColor White
}

# Main execution logic
Write-SuperScriptHeader "Starting Complete Installation"

$result = Install-AllSuperModules -SuperModules $SuperModules

Write-SuperScriptStep "Complete Windows Development Environment installation completed!" "SUCCESS"
