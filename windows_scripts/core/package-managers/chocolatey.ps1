# Complete Chocolatey Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Chocolatey"
    Version = "1.0.0"
    Description = "Windows Package Manager"
    ExecutableNames = @("choco.exe", "choco")
    VersionCommands = @("choco --version")
    TestCommands = @("choco --version", "choco list --local-only")
    WingetId = "Chocolatey.Chocolatey"
    ChocoId = "chocolatey"
    DownloadUrl = "https://chocolatey.org/"
    Documentation = "https://docs.chocolatey.org/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "CHOCOLATEY COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-ChocolateyInstallation {
    <#
    .SYNOPSIS
    Comprehensive Chocolatey installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Chocolatey installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        PackagesInstalled = @()
        Sources = @()
    }
    
    # Check Chocolatey executable
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
            $version = & choco --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get installed packages
        try {
            $packages = & choco list --local-only 2>$null
            if ($packages) {
                $result.PackagesInstalled = $packages | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get sources
        try {
            $sources = & choco source list 2>$null
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

function Install-Chocolatey {
    <#
    .SYNOPSIS
    Install Chocolatey with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing Chocolatey $Version"
    
    # Check if already installed
    $currentInstallation = Test-ChocolateyInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Chocolatey is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Set execution policy
        Write-ComponentStep "Setting execution policy..." "INFO"
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        
        # Install using PowerShell script
        Write-ComponentStep "Installing Chocolatey..." "INFO"
        $installScript = "https://chocolatey.org/install.ps1"
        
        if ($Silent) {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($installScript))
        } else {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($installScript))
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Chocolatey installation..." "INFO"
        $postInstallVerification = Test-ChocolateyInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Chocolatey installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Chocolatey installation verification failed" "WARNING"
            return $false
        }
        
        # Install extensions if requested
        if ($InstallExtensions) {
            Write-ComponentStep "Installing Chocolatey extensions..." "INFO"
            
            $extensions = @(
                "chocolatey-core.extension",
                "chocolatey-windowsupdate.extension",
                "chocolatey-dotnetfx.extension",
                "chocolatey-visualstudio.extension"
            )
            
            foreach ($extension in $extensions) {
                try {
                    choco install $extension -y
                    Write-ComponentStep "  ✓ $extension installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $extension" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Chocolatey: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-ChocolateyFunctionality {
    <#
    .SYNOPSIS
    Test Chocolatey functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Chocolatey Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "choco --version",
        "choco list --local-only",
        "choco source list",
        "choco config list",
        "choco feature list"
    )
    
    $expectedOutputs = @(
        "Chocolatey",
        "packages",
        "sources",
        "config",
        "features"
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

function Update-Chocolatey {
    <#
    .SYNOPSIS
    Update Chocolatey to latest version
    #>
    Write-ComponentHeader "Updating Chocolatey"
    
    $currentInstallation = Test-ChocolateyInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Chocolatey is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Chocolatey..." "INFO"
    
    try {
        choco upgrade chocolatey -y
        Write-ComponentStep "Chocolatey updated successfully" "SUCCESS"
        
        # Update all packages
        choco upgrade all -y
        Write-ComponentStep "All packages updated" "SUCCESS"
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Chocolatey: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-ChocolateyPath {
    <#
    .SYNOPSIS
    Fix Chocolatey PATH issues
    #>
    Write-ComponentHeader "Fixing Chocolatey PATH"
    
    $chocolateyPaths = @(
        "${env:ProgramData}\chocolatey\bin",
        "${env:ALLUSERSPROFILE}\chocolatey\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $chocolateyPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Chocolatey paths:" "INFO"
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
            Write-ComponentStep "Added Chocolatey paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Chocolatey paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Chocolatey paths found" "WARNING"
    }
}

function Uninstall-Chocolatey {
    <#
    .SYNOPSIS
    Uninstall Chocolatey
    #>
    Write-ComponentHeader "Uninstalling Chocolatey"
    
    $currentInstallation = Test-ChocolateyInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Chocolatey is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Chocolatey..." "INFO"
    
    try {
        # Remove from PATH
        $currentPath = $env:Path
        $newPath = $currentPath -replace [regex]::Escape("${env:ProgramData}\chocolatey\bin"), ""
        $newPath = $newPath -replace ";;", ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = $newPath
        
        # Remove installation directory
        if (Test-Path "${env:ProgramData}\chocolatey") {
            Remove-Item -Recurse -Force "${env:ProgramData}\chocolatey"
        }
        
        Write-ComponentStep "Chocolatey uninstalled successfully" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to uninstall Chocolatey: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-ChocolateyStatus {
    <#
    .SYNOPSIS
    Show comprehensive Chocolatey status
    #>
    Write-ComponentHeader "Chocolatey Status Report"
    
    $installation = Test-ChocolateyInstallation -Detailed:$Detailed
    $functionality = Test-ChocolateyFunctionality -Detailed:$Detailed
    
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

function Show-ChocolateyHelp {
    <#
    .SYNOPSIS
    Show help information for Chocolatey component
    #>
    Write-ComponentHeader "Chocolatey Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Chocolatey" -ForegroundColor White
    Write-Host "  test        - Test Chocolatey functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Chocolatey" -ForegroundColor White
    Write-Host "  update      - Update Chocolatey and packages" -ForegroundColor White
    Write-Host "  check       - Check Chocolatey installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Chocolatey PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Chocolatey" -ForegroundColor White
    Write-Host "  status      - Show Chocolatey status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\chocolatey.ps1 install                    # Install Chocolatey" -ForegroundColor White
    Write-Host "  .\chocolatey.ps1 test                       # Test Chocolatey" -ForegroundColor White
    Write-Host "  .\chocolatey.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\chocolatey.ps1 update                     # Update Chocolatey" -ForegroundColor White
    Write-Host "  .\chocolatey.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\chocolatey.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\chocolatey.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Chocolatey version to install" -ForegroundColor White
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
        $result = Install-Chocolatey -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Chocolatey installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Chocolatey installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-ChocolateyFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Chocolatey functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chocolatey functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Chocolatey..." "INFO"
        $result = Install-Chocolatey -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Chocolatey reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chocolatey reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Chocolatey
        if ($result) {
            Write-ComponentStep "Chocolatey update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chocolatey update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-ChocolateyInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Chocolatey is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Chocolatey is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-ChocolateyPath
        Write-ComponentStep "Chocolatey PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Chocolatey
        if ($result) {
            Write-ComponentStep "Chocolatey uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chocolatey uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-ChocolateyStatus
    }
    "help" {
        Show-ChocolateyHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-ChocolateyHelp
        exit 1
    }
}