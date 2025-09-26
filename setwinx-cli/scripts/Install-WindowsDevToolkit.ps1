#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Development Toolkit - Main Installation Script
.DESCRIPTION
    Provides a unified interface for installing, configuring, and testing Windows development tools.
    This is the main entry point for the Windows Development Toolkit v2.0
    
.PARAMETER Action
    The action to perform (install, test, configure, all)
    
.PARAMETER Category
    The category of tools to work with
    
.PARAMETER Tools
    Specific tools to install (optional)
    
.PARAMETER Force
    Force reinstallation of existing tools
    
.PARAMETER Silent
    Run in silent mode with minimal output
    
.PARAMETER ConfigFile
    Path to custom configuration file
    
.PARAMETER LogLevel
    Logging level (Debug, Info, Warning, Error, Critical)
    
.EXAMPLE
    .\Install-WindowsDevToolkit.ps1 -Action install -Category package-managers
    
.EXAMPLE
    .\Install-WindowsDevToolkit.ps1 -Action all -Category development-tools -Force
    
.EXAMPLE
    .\Install-WindowsDevToolkit.ps1 -Action test -Category all -LogLevel Debug
    
.EXAMPLE
    .\Install-WindowsDevToolkit.ps1 -Action configure -Category terminal -Tools @("powershell", "windows-terminal")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("install", "test", "configure", "all")]
    [string]$Action,
    
    [Parameter(Mandatory)]
    [ValidateSet("package-managers", "development-tools", "cloud-tools", "applications", "ai-tools", "all")]
    [string]$Category,
    
    [string[]]$Tools = @(),
    
    [switch]$Force,
    
    [switch]$Silent,
    
    [string]$ConfigFile = "",
    
    [ValidateSet("Debug", "Info", "Warning", "Error", "Critical")]
    [string]$LogLevel = "Info",
    
    [switch]$WhatIf,
    
    [switch]$Verbose
)

# Initialize
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleRoot = Join-Path (Split-Path $ScriptRoot) "src"

# Import main toolkit module
$ToolkitModule = Join-Path $ModuleRoot "Core\WindowsDevToolkit.psm1"
if (-not (Test-Path $ToolkitModule)) {
    throw "Toolkit module not found at: $ToolkitModule"
}

Import-Module $ToolkitModule -Force

# Main execution
try {
    # Display header
    if (-not $Silent) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Windows Development Toolkit v2.0" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Action: $Action" -ForegroundColor Yellow
        Write-Host "Category: $Category" -ForegroundColor Yellow
        if ($Tools.Count -gt 0) {
            Write-Host "Tools: $($Tools -join ', ')" -ForegroundColor Yellow
        }
        Write-Host "Log Level: $LogLevel" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Initialize toolkit
    $toolkit = Initialize-WindowsDevToolkit
    
    # Prepare options
    $options = @{
        Force = $Force
        Silent = $Silent
        Tools = $Tools
        WhatIf = $WhatIf
        LogLevel = $LogLevel
    }
    
    if ($ConfigFile) {
        $options.ConfigFile = $ConfigFile
    }
    
    # Execute action
    $results = switch ($Action) {
        "install" {
            if ($Category -eq "all") {
                $categories = @("package-managers", "development-tools", "cloud-tools", "applications", "ai-tools")
                $allResults = @{}
                foreach ($cat in $categories) {
                    if (-not $Silent) {
                        Write-Host "Installing $cat..." -ForegroundColor Magenta
                    }
                    $allResults[$cat] = Install-ToolkitCategory -Category $cat -Options $options
                }
                $allResults
            } else {
                Install-ToolkitCategory -Category $Category -Options $options
            }
        }
        "test" {
            if ($Category -eq "all") {
                $categories = @("package-managers", "development-tools", "cloud-tools", "applications", "ai-tools")
                $allResults = @{}
                foreach ($cat in $categories) {
                    if (-not $Silent) {
                        Write-Host "Testing $cat..." -ForegroundColor Magenta
                    }
                    $allResults[$cat] = Test-ToolkitCategory -Category $cat -Options $options
                }
                $allResults
            } else {
                Test-ToolkitCategory -Category $Category -Options $options
            }
        }
        "configure" {
            if ($Category -eq "all") {
                $categories = @("terminal", "powershell", "tools", "ai-tools")
                $allResults = @{}
                foreach ($cat in $categories) {
                    if (-not $Silent) {
                        Write-Host "Configuring $cat..." -ForegroundColor Magenta
                    }
                    $allResults[$cat] = Set-ToolkitConfiguration -Category $cat -Options $options
                }
                $allResults
            } else {
                Set-ToolkitConfiguration -Category $Category -Options $options
            }
        }
        "all" {
            # Install, configure, then test
            if (-not $Silent) {
                Write-Host "Performing complete setup..." -ForegroundColor Magenta
            }
            
            $installResults = if ($Category -eq "all") {
                $categories = @("package-managers", "development-tools", "cloud-tools", "applications", "ai-tools")
                $allResults = @{}
                foreach ($cat in $categories) {
                    if (-not $Silent) {
                        Write-Host "Installing $cat..." -ForegroundColor Magenta
                    }
                    $allResults[$cat] = Install-ToolkitCategory -Category $cat -Options $options
                }
                $allResults
            } else {
                Install-ToolkitCategory -Category $Category -Options $options
            }
            
            $configResults = Set-ToolkitConfiguration -Category "tools" -Options $options
            $testResults = Test-ToolkitCategory -Category $Category -Options $options
            
            @{
                Install = $installResults
                Configure = $configResults
                Test = $testResults
            }
        }
    }
    
    # Display results
    if (-not $Silent) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Execution completed successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        # Show summary
        if ($results -is [hashtable]) {
            Write-Host "Results Summary:" -ForegroundColor Cyan
            foreach ($key in $results.Keys) {
                $value = $results[$key]
                if ($value -is [hashtable]) {
                    $successCount = ($value.Values | Where-Object { $_.IsInstalled -or $_.Success }).Count
                    $totalCount = $value.Count
                    Write-Host "  $key`: $successCount/$totalCount successful" -ForegroundColor White
                } else {
                    Write-Host "  $key`: $value" -ForegroundColor White
                }
            }
        }
    }
    
    # Save results to file if not silent
    if (-not $Silent) {
        $resultsFile = "toolkit-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $results | ConvertTo-Json -Depth 5 | Set-Content $resultsFile -Encoding UTF8
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Gray
    }
    
    exit 0
}
catch {
    if (-not $Silent) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Execution failed!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
    }
    
    exit 1
}
