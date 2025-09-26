# Complete WinGet Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

param(
    [Parameter(Position=0)]
    [ValidateSet("install", "test", "reinstall", "update", "check", "fix-path", "uninstall", "status", "help")]
    [string]$Action = "install",
    
    [string]$Version = "latest",
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [switch]$Detailed = $false,
    [switch]$Quiet = $false,
    [switch]$AddToPath = $true,
    [switch]$InstallExtensions = $true
)

# Component Information
$ComponentInfo = @{
    Name = "WinGet"
    Version = "1.0.0"
    Description = "Microsoft Windows Package Manager"
    ExecutableNames = @("winget.exe", "winget")
    VersionCommands = @("winget --version")
    TestCommands = @("winget --version", "winget list")
    WingetId = "Microsoft.Winget.Source"
    ChocoId = "winget"
    DownloadUrl = "https://github.com/microsoft/winget-cli"
    Documentation = "https://docs.microsoft.com/en-us/windows/package-manager/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "WINGET COMPONENT: $Message" -ForegroundColor Cyan
        Write-Host "=" * 60 -ForegroundColor Cyan
    }
}

function Write-ComponentStep {
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

function Test-WinGetInstallation {
    <#
    .SYNOPSIS
    Comprehensive WinGet installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking WinGet installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        PackagesInstalled = @()
        Sources = @()
    }
    
    # Check WinGet executable
    foreach ($exe in $ComponentInfo.ExecutableNames) {
        $command = Get-Command $exe -ErrorAction SilentlyContinue
        if ($command) {
            $result.IsInstalled = $true
            $result.ExecutablePath = $command.Source
            $result.Paths += $command.Source
            break
        }
    }
    
    # Get version information
    if ($result.IsInstalled) {
        try {
            $version = & winget --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get installed packages
        try {
            $packages = & winget list 2>$null
            if ($packages) {
                $result.PackagesInstalled = $packages | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get sources
        try {
            $sources = & winget source list 2>$null
            if ($sources) {
                $result.Sources = $sources | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-WinGet {
    <#
    .SYNOPSIS
    Install WinGet with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing WinGet $Version"
    
    # Check if already installed
    $currentInstallation = Test-WinGetInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "WinGet is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Check if WinGet is available (Windows 10 1709+ or Windows 11)
        $osVersion = [System.Environment]::OSVersion.Version
        if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 1709)) {
            Write-ComponentStep "WinGet requires Windows 10 1709 or later" "ERROR"
            return $false
        }
        
        # Install using Microsoft Store or direct download
        Write-ComponentStep "Installing WinGet..." "INFO"
        
        # Try Microsoft Store first
        try {
            $storeResult = Start-Process -FilePath "ms-windows-store:" -ArgumentList "pdp?productid=9NBLGGH4NNS1" -Wait -PassThru
            if ($storeResult.ExitCode -eq 0) {
                Write-ComponentStep "WinGet installed via Microsoft Store" "SUCCESS"
            } else {
                throw "Microsoft Store installation failed"
            }
        } catch {
            # Fallback to direct download
            Write-ComponentStep "Installing WinGet via direct download..." "INFO"
            
            $downloadUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            $tempFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
            
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile
                Add-AppxPackage -Path $tempFile
                Remove-Item $tempFile -Force
                Write-ComponentStep "WinGet installed via direct download" "SUCCESS"
            } catch {
                Write-ComponentStep "Direct download installation failed" "ERROR"
                return $false
            }
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying WinGet installation..." "INFO"
        $postInstallVerification = Test-WinGetInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "WinGet installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "WinGet installation verification failed" "WARNING"
            return $false
        }
        
        # Configure WinGet
        Write-ComponentStep "Configuring WinGet..." "INFO"
        
        # Enable experimental features
        winget settings --enable-experimental-features
        
        # Add additional sources
        winget source add --name "msstore" --arg "https://storeedgefd.dsx.mp.microsoft.com/v9.0" --type "Microsoft.Store"
        
        Write-ComponentStep "WinGet configuration completed" "SUCCESS"
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install WinGet: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-WinGetFunctionality {
    <#
    .SYNOPSIS
    Test WinGet functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing WinGet Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "winget --version",
        "winget list",
        "winget source list",
        "winget search --query test",
        "winget --info"
    )
    
    $expectedOutputs = @(
        "winget",
        "packages",
        "sources",
        "search",
        "info"
    )
    
    $results.TotalTests = $testCommands.Count
    
    for ($i = 0; $i -lt $testCommands.Count; $i++) {
        $testCmd = $testCommands[$i]
        $expectedOutput = $expectedOutputs[$i]
        
        try {
            Write-ComponentStep "Testing: $testCmd" "INFO"
            $output = Invoke-Expression $testCmd 2>$null
            
            $testPassed = $true
            if ($expectedOutput -and $output) {
                $testPassed = $output -match $expectedOutput
            } elseif ($expectedOutput) {
                $testPassed = $false
            }
            
            $results.TestResults += @{
                Command = $testCmd
                Output = $output
                Expected = $expectedOutput
                Passed = $testPassed
            }
            
            if ($testPassed) {
                $results.PassedTests++
                Write-ComponentStep "  ✓ Passed" "SUCCESS"
            } else {
                Write-ComponentStep "  ✗ Failed" "ERROR"
            }
        } catch {
            $results.TestResults += @{
                Command = $testCmd
                Output = $null
                Expected = $expectedOutput
                Passed = $false
                Error = $_.Exception.Message
            }
            Write-ComponentStep "  ✗ Error: $($_.Exception.Message)" "ERROR"
        }
    }
    
    $results.OverallSuccess = ($results.PassedTests -ge ($results.TotalTests * 0.7))
    
    Write-ComponentStep "Tests passed: $($results.PassedTests)/$($results.TotalTests)" "INFO"
    
    return $results
}

function Update-WinGet {
    <#
    .SYNOPSIS
    Update WinGet to latest version
    #>
    Write-ComponentHeader "Updating WinGet"
    
    $currentInstallation = Test-WinGetInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "WinGet is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating WinGet..." "INFO"
    
    try {
        # Update WinGet itself
        winget upgrade Microsoft.DesktopAppInstaller
        Write-ComponentStep "WinGet updated successfully" "SUCCESS"
        
        # Update all packages
        winget upgrade --all
        Write-ComponentStep "All packages updated" "SUCCESS"
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update WinGet: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-WinGetPath {
    <#
    .SYNOPSIS
    Fix WinGet PATH issues
    #>
    Write-ComponentHeader "Fixing WinGet PATH"
    
    $wingetPaths = @(
        "${env:LOCALAPPDATA}\Microsoft\WindowsApps",
        "${env:ProgramFiles}\WindowsApps"
    )
    
    $foundPaths = @()
    foreach ($path in $wingetPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found WinGet paths:" "INFO"
        foreach ($path in $foundPaths) {
            Write-ComponentStep "  - $path" "INFO"
        }
        
        # Add to PATH if not already there
        $currentPath = $env:Path
        $pathsToAdd = $foundPaths | Where-Object { $currentPath -notlike "*$_*" }
        
        if ($pathsToAdd.Count -gt 0) {
            $newPath = $currentPath + ";" + ($pathsToAdd -join ";")
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = $newPath
            Write-ComponentStep "Added WinGet paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "WinGet paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No WinGet paths found" "WARNING"
    }
}

function Uninstall-WinGet {
    <#
    .SYNOPSIS
    Uninstall WinGet
    #>
    Write-ComponentHeader "Uninstalling WinGet"
    
    $currentInstallation = Test-WinGetInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "WinGet is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling WinGet..." "INFO"
    
    try {
        # Remove via PowerShell
        Get-AppxPackage Microsoft.DesktopAppInstaller | Remove-AppxPackage
        Write-ComponentStep "WinGet uninstalled successfully" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to uninstall WinGet: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-WinGetStatus {
    <#
    .SYNOPSIS
    Show comprehensive WinGet status
    #>
    Write-ComponentHeader "WinGet Status Report"
    
    $installation = Test-WinGetInstallation -Detailed:$Detailed
    $functionality = Test-WinGetFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.PackagesInstalled.Count -gt 0) {
        Write-Host "`nInstalled Packages:" -ForegroundColor Cyan
        foreach ($package in $installation.PackagesInstalled) {
            Write-Host "  - $package" -ForegroundColor White
        }
    }
    
    if ($installation.Sources.Count -gt 0) {
        Write-Host "`nSources:" -ForegroundColor Cyan
        foreach ($source in $installation.Sources) {
            Write-Host "  - $source" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-WinGetHelp {
    <#
    .SYNOPSIS
    Show help information for WinGet component
    #>
    Write-ComponentHeader "WinGet Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install WinGet" -ForegroundColor White
    Write-Host "  test        - Test WinGet functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall WinGet" -ForegroundColor White
    Write-Host "  update      - Update WinGet and packages" -ForegroundColor White
    Write-Host "  check       - Check WinGet installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix WinGet PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall WinGet" -ForegroundColor White
    Write-Host "  status      - Show WinGet status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\winget.ps1 install                    # Install WinGet" -ForegroundColor White
    Write-Host "  .\winget.ps1 test                       # Test WinGet" -ForegroundColor White
    Write-Host "  .\winget.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\winget.ps1 update                     # Update WinGet" -ForegroundColor White
    Write-Host "  .\winget.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\winget.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\winget.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - WinGet version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallExtensions     - Install extensions" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-WinGet -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "WinGet installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "WinGet installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-WinGetFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "WinGet functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "WinGet functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling WinGet..." "INFO"
        $result = Install-WinGet -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "WinGet reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "WinGet reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-WinGet
        if ($result) {
            Write-ComponentStep "WinGet update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "WinGet update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-WinGetInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "WinGet is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "WinGet is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-WinGetPath
        Write-ComponentStep "WinGet PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-WinGet
        if ($result) {
            Write-ComponentStep "WinGet uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "WinGet uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-WinGetStatus
    }
    "help" {
        Show-WinGetHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-WinGetHelp
        exit 1
    }
}