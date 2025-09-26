# Complete ADB Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallPlatformTools = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Android Debug Bridge (ADB)"
    Version = "1.0.0"
    Description = "Complete Android Debug Bridge Development Environment"
    ExecutableNames = @("adb.exe", "adb")
    VersionCommands = @("adb version")
    TestCommands = @("adb version", "adb devices")
    InstallMethod = "android-sdk"
    Documentation = "https://developer.android.com/studio/command-line/adb"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "ADB COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-AdbInstallation {
    <#
    .SYNOPSIS
    Comprehensive ADB installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking ADB installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        SDKPath = ""
        DevicesConnected = @()
    }
    
    # Check ADB executable
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
            $version = & adb version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check for connected devices
        try {
            $devices = & adb devices 2>$null
            if ($devices) {
                $result.DevicesConnected = $devices | Where-Object { $_ -match "device$" } | ForEach-Object { ($_ -split "\t")[0] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Adb {
    <#
    .SYNOPSIS
    Install ADB with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallPlatformTools = $true
    )
    
    Write-ComponentHeader "Installing ADB $Version"
    
    # Check if already installed
    $currentInstallation = Test-AdbInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "ADB is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Check if Android SDK is installed
        $sdkPaths = @(
            "${env:LOCALAPPDATA}\Android\Sdk",
            "${env:ProgramFiles}\Android\Sdk",
            "${env:ProgramFiles(x86)}\Android\Sdk"
        )
        
        $sdkInstalled = $false
        $sdkPath = ""
        foreach ($path in $sdkPaths) {
            if (Test-Path $path) {
                $sdkInstalled = $true
                $sdkPath = $path
                break
            }
        }
        
        if (-not $sdkInstalled) {
            Write-ComponentStep "Android SDK not found. Installing Android SDK first..." "INFO"
            $sdkScript = "core\android-development\android-sdk.ps1"
            if (Test-Path $sdkScript) {
                & $sdkScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
            } else {
                throw "Android SDK installer not found"
            }
        }
        
        # Install platform tools (includes ADB)
        if ($InstallPlatformTools) {
            Write-ComponentStep "Installing Android platform tools (includes ADB)..." "INFO"
            
            $sdkManagerPaths = @(
                Join-Path $sdkPath "cmdline-tools\latest\bin\sdkmanager.bat",
                Join-Path $sdkPath "tools\bin\sdkmanager.bat",
                Join-Path $sdkPath "bin\sdkmanager.exe"
            )
            
            $sdkManager = $null
            foreach ($path in $sdkManagerPaths) {
                if (Test-Path $path) {
                    $sdkManager = $path
                    break
                }
            }
            
            if ($sdkManager) {
                # Accept licenses
                & $sdkManager --licenses --sdk_root=$sdkPath
                
                # Install platform tools
                & $sdkManager "platform-tools" --sdk_root=$sdkPath
                Write-ComponentStep "Platform tools installed" "SUCCESS"
            } else {
                throw "SDK Manager not found"
            }
        }
        
        # Set up environment variables
        [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
        [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")
        
        # Add to PATH
        if ($AddToPath) {
            $platformToolsPath = Join-Path $sdkPath "platform-tools"
            $currentPath = $env:Path
            $newPath = $currentPath + ";" + $platformToolsPath
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = $newPath
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying ADB installation..." "INFO"
        $postInstallVerification = Test-AdbInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "ADB installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "ADB installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install ADB: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-AdbFunctionality {
    <#
    .SYNOPSIS
    Test ADB functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing ADB Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "adb version",
        "adb devices",
        "adb --help",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk\\platform-tools\\adb.exe`"",
        "Test-Path `"${env:ProgramFiles}\\Android\\Sdk\\platform-tools\\adb.exe`""
    )
    
    $expectedOutputs = @(
        "Android Debug Bridge",
        "List of devices",
        "Android Debug Bridge",
        "True",
        "True"
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

function Update-Adb {
    <#
    .SYNOPSIS
    Update ADB to latest version
    #>
    Write-ComponentHeader "Updating ADB"
    
    $currentInstallation = Test-AdbInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "ADB is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating ADB..." "INFO"
    
    try {
        # Update platform tools (includes ADB)
        $sdkPath = "${env:LOCALAPPDATA}\Android\Sdk"
        $sdkManagerPaths = @(
            Join-Path $sdkPath "cmdline-tools\latest\bin\sdkmanager.bat",
            Join-Path $sdkPath "tools\bin\sdkmanager.bat",
            Join-Path $sdkPath "bin\sdkmanager.exe"
        )
        
        $sdkManager = $null
        foreach ($path in $sdkManagerPaths) {
            if (Test-Path $path) {
                $sdkManager = $path
                break
            }
        }
        
        if ($sdkManager) {
            # Update platform tools
            & $sdkManager "platform-tools" --sdk_root=$sdkPath
            Write-ComponentStep "ADB updated" "SUCCESS"
        }
        
        Write-ComponentStep "ADB update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update ADB: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-AdbPath {
    <#
    .SYNOPSIS
    Fix ADB PATH issues
    #>
    Write-ComponentHeader "Fixing ADB PATH"
    
    $sdkPaths = @(
        "${env:LOCALAPPDATA}\Android\Sdk",
        "${env:ProgramFiles}\Android\Sdk",
        "${env:ProgramFiles(x86)}\Android\Sdk"
    )
    
    $foundPaths = @()
    foreach ($sdkPath in $sdkPaths) {
        $platformToolsPath = Join-Path $sdkPath "platform-tools"
        if (Test-Path $platformToolsPath) {
            $foundPaths += $platformToolsPath
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found ADB paths:" "INFO"
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
            Write-ComponentStep "Added ADB paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "ADB paths already in environment" "INFO"
        }
        
        # Set environment variables
        $sdkPath = $foundPaths[0].Replace("\platform-tools", "")
        [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
        [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")
        Write-ComponentStep "Set ANDROID_HOME to: $sdkPath" "SUCCESS"
    } else {
        Write-ComponentStep "No ADB paths found" "WARNING"
    }
}

function Uninstall-Adb {
    <#
    .SYNOPSIS
    Uninstall ADB
    #>
    Write-ComponentHeader "Uninstalling ADB"
    
    $currentInstallation = Test-AdbInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "ADB is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing ADB from PATH..." "INFO"
    
    # Remove ADB paths from environment
    $currentPath = $env:Path
    $adbPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $adbPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "ADB removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of ADB files may be required" "WARNING"
    
    return $true
}

function Show-AdbStatus {
    <#
    .SYNOPSIS
    Show comprehensive ADB status
    #>
    Write-ComponentHeader "ADB Status Report"
    
    $installation = Test-AdbInstallation -Detailed:$Detailed
    $functionality = Test-AdbFunctionality -Detailed:$Detailed
    
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
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    Write-Host "`nConnected Devices:" -ForegroundColor Cyan
    if ($installation.DevicesConnected.Count -gt 0) {
        foreach ($device in $installation.DevicesConnected) {
            Write-Host "  - $device" -ForegroundColor White
        }
    } else {
        Write-Host "  No devices connected" -ForegroundColor Gray
    }
    
    Write-Host "`nEnvironment Variables:" -ForegroundColor Cyan
    Write-Host "  ANDROID_HOME: $([Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User'))" -ForegroundColor White
    Write-Host "  ANDROID_SDK_ROOT: $([Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'User'))" -ForegroundColor White
}

function Show-AdbHelp {
    <#
    .SYNOPSIS
    Show help information for ADB component
    #>
    Write-ComponentHeader "ADB Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install ADB" -ForegroundColor White
    Write-Host "  test        - Test ADB functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall ADB" -ForegroundColor White
    Write-Host "  update      - Update ADB" -ForegroundColor White
    Write-Host "  check       - Check ADB installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix ADB PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall ADB" -ForegroundColor White
    Write-Host "  status      - Show ADB status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\adb.ps1 install                    # Install ADB" -ForegroundColor White
    Write-Host "  .\adb.ps1 test                       # Test ADB" -ForegroundColor White
    Write-Host "  .\adb.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\adb.ps1 update                     # Update ADB" -ForegroundColor White
    Write-Host "  .\adb.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\adb.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\adb.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - ADB version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallPlatformTools   - Install platform tools" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Adb -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallPlatformTools:$InstallPlatformTools
        if ($result) {
            Write-ComponentStep "ADB installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "ADB installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-AdbFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "ADB functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "ADB functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling ADB..." "INFO"
        $result = Install-Adb -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallPlatformTools:$InstallPlatformTools
        if ($result) {
            Write-ComponentStep "ADB reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "ADB reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Adb
        if ($result) {
            Write-ComponentStep "ADB update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "ADB update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-AdbInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "ADB is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "ADB is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-AdbPath
        Write-ComponentStep "ADB PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Adb
        if ($result) {
            Write-ComponentStep "ADB uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "ADB uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-AdbStatus
    }
    "help" {
        Show-AdbHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-AdbHelp
        exit 1
    }
}
