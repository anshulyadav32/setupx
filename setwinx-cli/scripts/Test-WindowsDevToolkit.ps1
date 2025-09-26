#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Development Toolkit - Testing Script
.DESCRIPTION
    Provides comprehensive testing functionality for the Windows Development Toolkit.
    Tests installation, configuration, and functionality of development tools.
    
.PARAMETER Category
    The category of tools to test
    
.PARAMETER Tools
    Specific tools to test (optional)
    
.PARAMETER Detailed
    Provide detailed test output
    
.PARAMETER Silent
    Run in silent mode with minimal output
    
.PARAMETER LogLevel
    Logging level (Debug, Info, Warning, Error, Critical)
    
.PARAMETER OutputFile
    Path to save test results
    
.EXAMPLE
    .\Test-WindowsDevToolkit.ps1 -Category package-managers
    
.EXAMPLE
    .\Test-WindowsDevToolkit.ps1 -Category all -Detailed
    
.EXAMPLE
    .\Test-WindowsDevToolkit.ps1 -Category development-tools -Tools @("git", "nodejs") -OutputFile "test-results.json"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("package-managers", "development-tools", "cloud-tools", "applications", "ai-tools", "all")]
    [string]$Category,
    
    [string[]]$Tools = @(),
    
    [switch]$Detailed,
    
    [switch]$Silent,
    
    [ValidateSet("Debug", "Info", "Warning", "Error", "Critical")]
    [string]$LogLevel = "Info",
    
    [string]$OutputFile = "",
    
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
        Write-Host "Windows Development Toolkit - Testing" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Category: $Category" -ForegroundColor Yellow
        if ($Tools.Count -gt 0) {
            Write-Host "Tools: $($Tools -join ', ')" -ForegroundColor Yellow
        }
        Write-Host "Detailed: $Detailed" -ForegroundColor Yellow
        Write-Host "Log Level: $LogLevel" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Prepare options
    $options = @{
        Tools = $Tools
        Detailed = $Detailed
        Silent = $Silent
        LogLevel = $LogLevel
    }
    
    # Execute tests
    $results = Test-ToolkitCategory -Category $Category -Options $options
    
    # Display results
    if (-not $Silent) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Testing completed!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        # Show summary
        if ($results -is [hashtable]) {
            Write-Host "Test Results Summary:" -ForegroundColor Cyan
            foreach ($key in $results.Keys) {
                $value = $results[$key]
                if ($value -is [hashtable]) {
                    $successCount = ($value.Values | Where-Object { $_.IsInstalled -or $_.Success }).Count
                    $totalCount = $value.Count
                    $status = if ($successCount -eq $totalCount) { "✓" } else { "✗" }
                    Write-Host "  $status $key`: $successCount/$totalCount successful" -ForegroundColor White
                } else {
                    Write-Host "  $key`: $value" -ForegroundColor White
                }
            }
        }
        
        # Show detailed results if requested
        if ($Detailed -and $results -is [hashtable]) {
            Write-Host ""
            Write-Host "Detailed Test Results:" -ForegroundColor Cyan
            Write-Host "=====================" -ForegroundColor Cyan
            
            foreach ($key in $results.Keys) {
                $value = $results[$key]
                if ($value -is [hashtable]) {
                    Write-Host ""
                    Write-Host "$key`:" -ForegroundColor Yellow
                    foreach ($tool in $value.Keys) {
                        $toolResult = $value[$tool]
                        $status = if ($toolResult.IsInstalled) { "✓" } else { "✗" }
                        $version = if ($toolResult.Version -ne "Unknown") { " (v$($toolResult.Version))" } else { "" }
                        Write-Host "  $status $tool$version" -ForegroundColor White
                        
                        if ($toolResult.AdditionalInfo -and $toolResult.AdditionalInfo.FunctionalityTest) {
                            $funcTest = $toolResult.AdditionalInfo.FunctionalityTest
                            $funcStatus = if ($funcTest.OverallSuccess) { "✓" } else { "✗" }
                            Write-Host "    Functionality: $funcStatus ($($funcTest.PassedTests)/$($funcTest.TotalTests))" -ForegroundColor Gray
                        }
                    }
                }
            }
        }
    }
    
    # Save results to file
    if ($OutputFile) {
        $results | ConvertTo-Json -Depth 5 | Set-Content $OutputFile -Encoding UTF8
        if (-not $Silent) {
            Write-Host "Results saved to: $OutputFile" -ForegroundColor Gray
        }
    } elseif (-not $Silent) {
        $defaultOutputFile = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $results | ConvertTo-Json -Depth 5 | Set-Content $defaultOutputFile -Encoding UTF8
        Write-Host "Results saved to: $defaultOutputFile" -ForegroundColor Gray
    }
    
    # Determine exit code
    $overallSuccess = $true
    if ($results -is [hashtable]) {
        foreach ($key in $results.Keys) {
            $value = $results[$key]
            if ($value -is [hashtable]) {
                $successCount = ($value.Values | Where-Object { $_.IsInstalled -or $_.Success }).Count
                $totalCount = $value.Count
                if ($successCount -ne $totalCount) {
                    $overallSuccess = $false
                    break
                }
            }
        }
    }
    
    if ($overallSuccess) {
        if (-not $Silent) {
            Write-Host ""
            Write-Host "All tests passed successfully!" -ForegroundColor Green
        }
        exit 0
    } else {
        if (-not $Silent) {
            Write-Host ""
            Write-Host "Some tests failed. Check the results above." -ForegroundColor Yellow
        }
        exit 1
    }
}
catch {
    if (-not $Silent) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Testing failed!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
    }
    
    exit 1
}
