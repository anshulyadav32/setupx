# Package Managers Module - Install, Test, Update, Check, Status, Help
# This module orchestrates all package manager components

param(
    [Parameter(Position=0)]
    [ValidateSet("install", "test", "update", "check", "status", "help")]
    [string]$Action = "install",
    
    [string[]]$Components = @("chocolatey", "winget", "scoop"),
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$Detailed = $false,
    [switch]$Quiet = $false,
    [switch]$All = $false
)

# Module Information
$ModuleInfo = @{
    Name = "Package Managers"
    Version = "1.0.0"
    Description = "Complete Package Manager Installation and Management"
    Components = @{
        "chocolatey" = @{
            Name = "Chocolatey"
            Description = "Windows Package Manager"
            Path = "core/package-managers/chocolatey.ps1"
            Priority = 1
            Required = $true
        }
        "winget" = @{
            Name = "WinGet"
            Description = "Microsoft Windows Package Manager"
            Path = "core/package-managers/winget.ps1"
            Priority = 2
            Required = $true
        }
        "scoop" = @{
            Name = "Scoop"
            Description = "Command-line installer for Windows"
            Path = "core/package-managers/scoop.ps1"
            Priority = 3
            Required = $false
        }
    }
    Dependencies = @{
        "chocolatey" = @()
        "winget" = @()
        "scoop" = @("git")
    }
}

# Core functions
function Write-ModuleHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 70 -ForegroundColor Magenta
        Write-Host "PACKAGE MANAGERS MODULE: $Message" -ForegroundColor Magenta
        Write-Host "=" * 70 -ForegroundColor Magenta
    }
}

function Write-ModuleStep {
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

function Get-SelectedComponents {
    <#
    .SYNOPSIS
    Get the list of components to process based on parameters
    #>
    if ($All) {
        return $ModuleInfo.Components.Keys
    }
    
    if ($Components -contains "all") {
        return $ModuleInfo.Components.Keys
    }
    
    # Validate components
    $validComponents = @()
    foreach ($component in $Components) {
        if ($ModuleInfo.Components.ContainsKey($component)) {
            $validComponents += $component
        } else {
            Write-ModuleStep "Unknown component: $component" "WARNING"
        }
    }
    
    return $validComponents
}

function Install-PackageManagerModule {
    <#
    .SYNOPSIS
    Install package manager components
    #>
    param(
        [string[]]$Components,
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$Detailed = $false
    )
    
    Write-ModuleHeader "Installing Package Manager Components"
    
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
        Total = $Components.Count
    }
    
    # Sort components by priority
    $sortedComponents = $Components | Sort-Object { $ModuleInfo.Components[$_].Priority }
    
    foreach ($component in $sortedComponents) {
        $componentInfo = $ModuleInfo.Components[$component]
        Write-ModuleStep "Installing $($componentInfo.Name)..." "INFO"
        
        try {
            # Check dependencies
            $dependencies = $ModuleInfo.Dependencies[$component]
            if ($dependencies -and $dependencies.Count -gt 0) {
                Write-ModuleStep "Checking dependencies: $($dependencies -join ', ')" "INFO"
                foreach ($dep in $dependencies) {
                    if (-not (Get-Command $dep -ErrorAction SilentlyContinue)) {
                        Write-ModuleStep "Dependency $dep not found. Installing first..." "WARNING"
                        # Install dependency if needed
                    }
                }
            }
            
            # Execute component script
            $scriptPath = Join-Path $PSScriptRoot $componentInfo.Path
            if (Test-Path $scriptPath) {
                $arguments = @("install")
                if ($Silent) { $arguments += "-Silent" }
                if ($Force) { $arguments += "-Force" }
                if ($Detailed) { $arguments += "-Detailed" }
                
                $process = Start-Process -FilePath "powershell" -ArgumentList "-File", $scriptPath, $arguments -Wait -PassThru -NoNewWindow
                
                if ($process.ExitCode -eq 0) {
                    $results.Success += $component
                    Write-ModuleStep "$($componentInfo.Name) installed successfully!" "SUCCESS"
                } else {
                    $results.Failed += $component
                    Write-ModuleStep "$($componentInfo.Name) installation failed!" "ERROR"
                }
            } else {
                $results.Failed += $component
                Write-ModuleStep "Script not found: $scriptPath" "ERROR"
            }
        } catch {
            $results.Failed += $component
            Write-ModuleStep "Error installing $($componentInfo.Name): $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Summary
    Write-ModuleStep "Installation Summary:" "INFO"
    Write-ModuleStep "  Success: $($results.Success.Count)/$($results.Total)" "SUCCESS"
    Write-ModuleStep "  Failed: $($results.Failed.Count)/$($results.Total)" "ERROR"
    Write-ModuleStep "  Skipped: $($results.Skipped.Count)/$($results.Total)" "WARNING"
    
    return $results
}

function Test-PackageManagerModule {
    <#
    .SYNOPSIS
    Test package manager components
    #>
    param(
        [string[]]$Components,
        [switch]$Detailed = $false
    )
    
    Write-ModuleHeader "Testing Package Manager Components"
    
    $results = @{
        Success = @()
        Failed = @()
        Total = $Components.Count
        TestResults = @()
    }
    
    foreach ($component in $Components) {
        $componentInfo = $ModuleInfo.Components[$component]
        Write-ModuleStep "Testing $($componentInfo.Name)..." "INFO"
        
        try {
            $scriptPath = Join-Path $PSScriptRoot $componentInfo.Path
            if (Test-Path $scriptPath) {
                $arguments = @("test")
                if ($Detailed) { $arguments += "-Detailed" }
                
                $process = Start-Process -FilePath "powershell" -ArgumentList "-File", $scriptPath, $arguments -Wait -PassThru -NoNewWindow
                
                if ($process.ExitCode -eq 0) {
                    $results.Success += $component
                    Write-ModuleStep "$($componentInfo.Name) tests passed!" "SUCCESS"
                } else {
                    $results.Failed += $component
                    Write-ModuleStep "$($componentInfo.Name) tests failed!" "ERROR"
                }
            } else {
                $results.Failed += $component
                Write-ModuleStep "Script not found: $scriptPath" "ERROR"
            }
        } catch {
            $results.Failed += $component
            Write-ModuleStep "Error testing $($componentInfo.Name): $($_.Exception.Message)" "ERROR"
        }
    }
    
    return $results
}

function Update-PackageManagerModule {
    <#
    .SYNOPSIS
    Update package manager components
    #>
    param(
        [string[]]$Components
    )
    
    Write-ModuleHeader "Updating Package Manager Components"
    
    $results = @{
        Success = @()
        Failed = @()
        Total = $Components.Count
    }
    
    foreach ($component in $Components) {
        $componentInfo = $ModuleInfo.Components[$component]
        Write-ModuleStep "Updating $($componentInfo.Name)..." "INFO"
        
        try {
            $scriptPath = Join-Path $PSScriptRoot $componentInfo.Path
            if (Test-Path $scriptPath) {
                $process = Start-Process -FilePath "powershell" -ArgumentList "-File", $scriptPath, "update" -Wait -PassThru -NoNewWindow
                
                if ($process.ExitCode -eq 0) {
                    $results.Success += $component
                    Write-ModuleStep "$($componentInfo.Name) updated successfully!" "SUCCESS"
                } else {
                    $results.Failed += $component
                    Write-ModuleStep "$($componentInfo.Name) update failed!" "ERROR"
                }
            } else {
                $results.Failed += $component
                Write-ModuleStep "Script not found: $scriptPath" "ERROR"
            }
        } catch {
            $results.Failed += $component
            Write-ModuleStep "Error updating $($componentInfo.Name): $($_.Exception.Message)" "ERROR"
        }
    }
    
    return $results
}

function Show-PackageManagerStatus {
    <#
    .SYNOPSIS
    Show status of package manager components
    #>
    param(
        [string[]]$Components,
        [switch]$Detailed = $false
    )
    
    Write-ModuleHeader "Package Manager Status Report"
    
    foreach ($component in $Components) {
        $componentInfo = $ModuleInfo.Components[$component]
        Write-ModuleStep "Checking $($componentInfo.Name)..." "INFO"
        
        try {
            $scriptPath = Join-Path $PSScriptRoot $componentInfo.Path
            if (Test-Path $scriptPath) {
                $arguments = @("status")
                if ($Detailed) { $arguments += "-Detailed" }
                
                Start-Process -FilePath "powershell" -ArgumentList "-File", $scriptPath, $arguments -Wait -NoNewWindow
            } else {
                Write-ModuleStep "Script not found: $scriptPath" "ERROR"
            }
        } catch {
            Write-ModuleStep "Error checking $($componentInfo.Name): $($_.Exception.Message)" "ERROR"
        }
    }
}

function Show-PackageManagerHelp {
    <#
    .SYNOPSIS
    Show help information for package manager module
    #>
    Write-ModuleHeader "Package Manager Module Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install package manager components" -ForegroundColor White
    Write-Host "  test        - Test package manager functionality" -ForegroundColor White
    Write-Host "  update      - Update package manager components" -ForegroundColor White
    Write-Host "  check       - Check package manager installation" -ForegroundColor White
    Write-Host "  status      - Show package manager status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nAvailable Components:" -ForegroundColor Cyan
    foreach ($component in $ModuleInfo.Components.GetEnumerator()) {
        $info = $component.Value
        Write-Host "  $($component.Key) - $($info.Name): $($info.Description)" -ForegroundColor White
    }
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\package-managers.ps1 install                    # Install all components" -ForegroundColor White
    Write-Host "  .\package-managers.ps1 install -Components chocolatey,winget  # Install specific components" -ForegroundColor White
    Write-Host "  .\package-managers.ps1 test -Detailed           # Test with detailed output" -ForegroundColor White
    Write-Host "  .\package-managers.ps1 update -All               # Update all components" -ForegroundColor White
    Write-Host "  .\package-managers.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Components <array>  - Components to process" -ForegroundColor White
    Write-Host "  -Silent             - Silent installation" -ForegroundColor White
    Write-Host "  -Force               - Force installation" -ForegroundColor White
    Write-Host "  -Detailed            - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet               - Quiet mode" -ForegroundColor White
    Write-Host "  -All                 - Process all components" -ForegroundColor White
}

# Main execution logic
$selectedComponents = Get-SelectedComponents

if ($selectedComponents.Count -eq 0) {
    Write-ModuleStep "No valid components selected" "ERROR"
    Show-PackageManagerHelp
    exit 1
}

switch ($Action.ToLower()) {
    "install" {
        $result = Install-PackageManagerModule -Components $selectedComponents -Silent:$Silent -Force:$Force -Detailed:$Detailed
        if ($result.Failed.Count -gt 0) {
            Write-ModuleStep "Some installations failed!" "ERROR"
            exit 1
        } else {
            Write-ModuleStep "All package managers installed successfully!" "SUCCESS"
        }
    }
    "test" {
        $result = Test-PackageManagerModule -Components $selectedComponents -Detailed:$Detailed
        if ($result.Failed.Count -gt 0) {
            Write-ModuleStep "Some tests failed!" "ERROR"
            exit 1
        } else {
            Write-ModuleStep "All package manager tests passed!" "SUCCESS"
        }
    }
    "update" {
        $result = Update-PackageManagerModule -Components $selectedComponents
        if ($result.Failed.Count -gt 0) {
            Write-ModuleStep "Some updates failed!" "ERROR"
            exit 1
        } else {
            Write-ModuleStep "All package managers updated successfully!" "SUCCESS"
        }
    }
    "check" {
        $result = Test-PackageManagerModule -Components $selectedComponents -Detailed:$Detailed
        if ($result.Failed.Count -gt 0) {
            Write-ModuleStep "Some package managers are not working!" "ERROR"
            exit 1
        } else {
            Write-ModuleStep "All package managers are working!" "SUCCESS"
        }
    }
    "status" {
        Show-PackageManagerStatus -Components $selectedComponents -Detailed:$Detailed
    }
    "help" {
        Show-PackageManagerHelp
    }
    default {
        Write-ModuleStep "Unknown action: $Action" "ERROR"
        Show-PackageManagerHelp
        exit 1
    }
}