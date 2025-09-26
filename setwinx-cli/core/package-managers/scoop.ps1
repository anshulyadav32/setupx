# Complete Scoop Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Scoop"
    Version = "1.0.0"
    Description = "Command-line installer for Windows"
    ExecutableNames = @("scoop.exe", "scoop")
    VersionCommands = @("scoop --version")
    TestCommands = @("scoop --version", "scoop list")
    WingetId = "ScoopInstaller.Scoop"
    ChocoId = "scoop"
    DownloadUrl = "https://scoop.sh/"
    Documentation = "https://github.com/ScoopInstaller/Scoop"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "SCOOP COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-ScoopInstallation {
    <#
    .SYNOPSIS
    Comprehensive Scoop installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Scoop installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        PackagesInstalled = @()
        Buckets = @()
    }
    
    # Check Scoop executable
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
            $version = & scoop --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get installed packages
        try {
            $packages = & scoop list 2>$null
            if ($packages) {
                $result.PackagesInstalled = $packages | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get buckets
        try {
            $buckets = & scoop bucket list 2>$null
            if ($buckets) {
                $result.Buckets = $buckets | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Scoop {
    <#
    .SYNOPSIS
    Install Scoop with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing Scoop $Version"
    
    # Check if already installed
    $currentInstallation = Test-ScoopInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Scoop is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Set execution policy
        Write-ComponentStep "Setting execution policy..." "INFO"
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        
        # Install Scoop
        Write-ComponentStep "Installing Scoop..." "INFO"
        
        if ($Silent) {
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        } else {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Scoop installation..." "INFO"
        $postInstallVerification = Test-ScoopInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Scoop installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Scoop installation verification failed" "WARNING"
            return $false
        }
        
        # Configure Scoop
        Write-ComponentStep "Configuring Scoop..." "INFO"
        
        # Add essential buckets
        $buckets = @(
            "main",
            "extras",
            "versions",
            "nirsoft",
            "php",
            "nerd-fonts",
            "nonportable",
            "java"
        )
        
        foreach ($bucket in $buckets) {
            try {
                scoop bucket add $bucket
                Write-ComponentStep "  ✓ Added bucket: $bucket" "SUCCESS"
            } catch {
                Write-ComponentStep "  ✗ Failed to add bucket: $bucket" "ERROR"
            }
        }
        
        # Install essential tools
        if ($InstallExtensions) {
            Write-ComponentStep "Installing essential Scoop tools..." "INFO"
            
            $essentialTools = @(
                "git",
                "7zip",
                "curl",
                "wget",
                "aria2",
                "sudo",
                "which",
                "less",
                "jq",
                "fzf"
            )
            
            foreach ($tool in $essentialTools) {
                try {
                    scoop install $tool
                    Write-ComponentStep "  ✓ $tool installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $tool" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Scoop: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-ScoopFunctionality {
    <#
    .SYNOPSIS
    Test Scoop functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Scoop Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "scoop --version",
        "scoop list",
        "scoop bucket list",
        "scoop config list",
        "scoop status"
    )
    
    $expectedOutputs = @(
        "scoop",
        "packages",
        "buckets",
        "config",
        "status"
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

function Update-Scoop {
    <#
    .SYNOPSIS
    Update Scoop to latest version
    #>
    Write-ComponentHeader "Updating Scoop"
    
    $currentInstallation = Test-ScoopInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Scoop is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Scoop..." "INFO"
    
    try {
        # Update Scoop itself
        scoop update
        Write-ComponentStep "Scoop updated successfully" "SUCCESS"
        
        # Update all packages
        scoop update *
        Write-ComponentStep "All packages updated" "SUCCESS"
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Scoop: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-ScoopPath {
    <#
    .SYNOPSIS
    Fix Scoop PATH issues
    #>
    Write-ComponentHeader "Fixing Scoop PATH"
    
    $scoopPaths = @(
        "${env:USERPROFILE}\scoop\shims",
        "${env:USERPROFILE}\scoop\apps\scoop\current\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $scoopPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Scoop paths:" "INFO"
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
            Write-ComponentStep "Added Scoop paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Scoop paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Scoop paths found" "WARNING"
    }
}

function Uninstall-Scoop {
    <#
    .SYNOPSIS
    Uninstall Scoop
    #>
    Write-ComponentHeader "Uninstalling Scoop"
    
    $currentInstallation = Test-ScoopInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Scoop is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Scoop..." "INFO"
    
    try {
        # Remove from PATH
        $currentPath = $env:Path
        $newPath = $currentPath -replace [regex]::Escape("${env:USERPROFILE}\scoop\shims"), ""
        $newPath = $newPath -replace ";;", ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = $newPath
        
        # Remove installation directory
        if (Test-Path "${env:USERPROFILE}\scoop") {
            Remove-Item -Recurse -Force "${env:USERPROFILE}\scoop"
        }
        
        Write-ComponentStep "Scoop uninstalled successfully" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to uninstall Scoop: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-ScoopStatus {
    <#
    .SYNOPSIS
    Show comprehensive Scoop status
    #>
    Write-ComponentHeader "Scoop Status Report"
    
    $installation = Test-ScoopInstallation -Detailed:$Detailed
    $functionality = Test-ScoopFunctionality -Detailed:$Detailed
    
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
    
    if ($installation.Buckets.Count -gt 0) {
        Write-Host "`nBuckets:" -ForegroundColor Cyan
        foreach ($bucket in $installation.Buckets) {
            Write-Host "  - $bucket" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-ScoopHelp {
    <#
    .SYNOPSIS
    Show help information for Scoop component
    #>
    Write-ComponentHeader "Scoop Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Scoop" -ForegroundColor White
    Write-Host "  test        - Test Scoop functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Scoop" -ForegroundColor White
    Write-Host "  update      - Update Scoop and packages" -ForegroundColor White
    Write-Host "  check       - Check Scoop installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Scoop PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Scoop" -ForegroundColor White
    Write-Host "  status      - Show Scoop status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\scoop.ps1 install                    # Install Scoop" -ForegroundColor White
    Write-Host "  .\scoop.ps1 test                       # Test Scoop" -ForegroundColor White
    Write-Host "  .\scoop.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\scoop.ps1 update                     # Update Scoop" -ForegroundColor White
    Write-Host "  .\scoop.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\scoop.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\scoop.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Scoop version to install" -ForegroundColor White
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
        $result = Install-Scoop -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Scoop installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Scoop installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-ScoopFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Scoop functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Scoop functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Scoop..." "INFO"
        $result = Install-Scoop -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Scoop reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Scoop reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Scoop
        if ($result) {
            Write-ComponentStep "Scoop update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Scoop update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-ScoopInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Scoop is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Scoop is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-ScoopPath
        Write-ComponentStep "Scoop PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Scoop
        if ($result) {
            Write-ComponentStep "Scoop uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Scoop uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-ScoopStatus
    }
    "help" {
        Show-ScoopHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-ScoopHelp
        exit 1
    }
}
