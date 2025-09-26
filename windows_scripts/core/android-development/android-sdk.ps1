# Complete Android SDK Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallPlatforms = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Android SDK"
    Version = "1.0.0"
    Description = "Complete Android SDK Development Environment"
    ExecutableNames = @("sdkmanager.exe", "sdkmanager")
    VersionCommands = @("sdkmanager --version")
    TestCommands = @("sdkmanager --version", "sdkmanager --list")
    InstallMethod = "android-studio"
    Documentation = "https://developer.android.com/studio/command-line/sdkmanager"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "ANDROID SDK COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-AndroidSdkInstallation {
    <#
    .SYNOPSIS
    Comprehensive Android SDK installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Android SDK installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        SDKPath = ""
        PlatformsAvailable = @()
        BuildToolsAvailable = @()
    }
    
    # Check Android SDK path
    $sdkPaths = @(
        "${env:LOCALAPPDATA}\Android\Sdk",
        "${env:ProgramFiles}\Android\Sdk",
        "${env:ProgramFiles(x86)}\Android\Sdk"
    )
    
    foreach ($path in $sdkPaths) {
        if (Test-Path $path) {
            $result.IsInstalled = $true
            $result.SDKPath = $path
            $result.Paths += $path
            break
        }
    }
    
    # Check SDK Manager
    if ($result.IsInstalled) {
        $sdkManagerPaths = @(
            Join-Path $result.SDKPath "cmdline-tools\latest\bin\sdkmanager.bat",
            Join-Path $result.SDKPath "tools\bin\sdkmanager.bat",
            Join-Path $result.SDKPath "bin\sdkmanager.exe"
        )
        
        foreach ($path in $sdkManagerPaths) {
            if (Test-Path $path) {
                $result.ExecutablePath = $path
                break
            }
        }
        
        # Get version information
        if ($result.ExecutablePath) {
            try {
                $version = & $result.ExecutablePath --version 2>$null
                if ($version) {
                    $result.Version = $version
                }
            } catch {
                $result.Version = "Unknown"
            }
        }
        
        # Check available platforms and build tools
        try {
            $listOutput = & $result.ExecutablePath --list 2>$null
            if ($listOutput) {
                $result.PlatformsAvailable = $listOutput | Where-Object { $_ -match "platforms;" } | ForEach-Object { ($_ -split ";")[0] }
                $result.BuildToolsAvailable = $listOutput | Where-Object { $_ -match "build-tools;" } | ForEach-Object { ($_ -split ";")[0] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-AndroidSdk {
    <#
    .SYNOPSIS
    Install Android SDK with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallPlatforms = $true
    )
    
    Write-ComponentHeader "Installing Android SDK $Version"
    
    # Check if already installed
    $currentInstallation = Test-AndroidSdkInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Android SDK is already installed" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Check if Android Studio is installed
        $studioPaths = @(
            "${env:ProgramFiles}\Android\Android Studio\bin\studio.exe",
            "${env:ProgramFiles(x86)}\Android\Android Studio\bin\studio.exe"
        )
        
        $studioInstalled = $false
        foreach ($path in $studioPaths) {
            if (Test-Path $path) {
                $studioInstalled = $true
                break
            }
        }
        
        if (-not $studioInstalled) {
            Write-ComponentStep "Android Studio not found. Installing Android Studio first..." "INFO"
            $studioScript = "core\android-development\android-studio.ps1"
            if (Test-Path $studioScript) {
                & $studioScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
            } else {
                throw "Android Studio installer not found"
            }
        }
        
        # Set up Android SDK
        $sdkPath = "${env:LOCALAPPDATA}\Android\Sdk"
        if (-not (Test-Path $sdkPath)) {
            New-Item -ItemType Directory -Path $sdkPath -Force | Out-Null
        }
        
        # Set environment variables
        [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
        [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")
        
        # Add to PATH
        if ($AddToPath) {
            $sdkToolsPath = Join-Path $sdkPath "tools"
            $sdkPlatformToolsPath = Join-Path $sdkPath "platform-tools"
            $sdkBinPath = Join-Path $sdkPath "bin"
            $sdkCmdlineToolsPath = Join-Path $sdkPath "cmdline-tools\latest\bin"
            
            $currentPath = $env:Path
            $newPath = $currentPath + ";" + $sdkToolsPath + ";" + $sdkPlatformToolsPath + ";" + $sdkBinPath + ";" + $sdkCmdlineToolsPath
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = $newPath
        }
        
        # Download and install command line tools
        Write-ComponentStep "Installing Android SDK command line tools..." "INFO"
        
        $cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
        $cmdlineToolsZip = "$env:TEMP\android-cmdline-tools.zip"
        $cmdlineToolsDir = Join-Path $sdkPath "cmdline-tools"
        $cmdlineToolsLatestDir = Join-Path $cmdlineToolsDir "latest"
        
        # Download command line tools
        Invoke-WebRequest -Uri $cmdlineToolsUrl -OutFile $cmdlineToolsZip -UseBasicParsing
        Write-ComponentStep "Command line tools downloaded" "SUCCESS"
        
        # Extract command line tools
        Expand-Archive -Path $cmdlineToolsZip -DestinationPath $cmdlineToolsDir -Force
        Move-Item (Join-Path $cmdlineToolsDir "cmdline-tools") $cmdlineToolsLatestDir -Force
        Remove-Item $cmdlineToolsZip -Force
        
        Write-ComponentStep "Command line tools installed" "SUCCESS"
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Android SDK installation..." "INFO"
        $postInstallVerification = Test-AndroidSdkInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Android SDK installation verified successfully!" "SUCCESS"
            Write-ComponentStep "SDK Path: $($postInstallVerification.SDKPath)" "INFO"
        } else {
            Write-ComponentStep "Android SDK installation verification failed" "WARNING"
            return $false
        }
        
        # Install platforms and build tools
        if ($InstallPlatforms) {
            Write-ComponentStep "Installing Android platforms and build tools..." "INFO"
            
            $sdkManager = Join-Path $sdkPath "cmdline-tools\latest\bin\sdkmanager.bat"
            if (Test-Path $sdkManager) {
                # Accept licenses
                & $sdkManager --licenses --sdk_root=$sdkPath
                
                # Install essential packages
                $essentialPackages = @(
                    "platform-tools",
                    "build-tools;34.0.0",
                    "platforms;android-34",
                    "platforms;android-33",
                    "platforms;android-32"
                )
                
                foreach ($package in $essentialPackages) {
                    try {
                        & $sdkManager $package --sdk_root=$sdkPath
                        Write-ComponentStep "  ✓ $package installed" "SUCCESS"
                    } catch {
                        Write-ComponentStep "  ✗ Failed to install $package" "ERROR"
                    }
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Android SDK: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-AndroidSdkFunctionality {
    <#
    .SYNOPSIS
    Test Android SDK functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Android SDK Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk`"",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk\\platform-tools\\adb.exe`"",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk\\cmdline-tools\\latest\\bin\\sdkmanager.bat`"",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk\\build-tools`"",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk\\platforms`""
    )
    
    $expectedOutputs = @(
        "True",
        "True",
        "True", 
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
                $testPassed = $output.ToString() -eq $expectedOutput
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

function Update-AndroidSdk {
    <#
    .SYNOPSIS
    Update Android SDK to latest version
    #>
    Write-ComponentHeader "Updating Android SDK"
    
    $currentInstallation = Test-AndroidSdkInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Android SDK is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Android SDK..." "INFO"
    
    try {
        $sdkManager = $currentInstallation.ExecutablePath
        if (Test-Path $sdkManager) {
            # Update SDK Manager
            & $sdkManager --update --sdk_root=$currentInstallation.SDKPath
            Write-ComponentStep "SDK Manager updated" "SUCCESS"
            
            # Update all installed packages
            & $sdkManager --update --sdk_root=$currentInstallation.SDKPath
            Write-ComponentStep "All packages updated" "SUCCESS"
        }
        
        Write-ComponentStep "Android SDK update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Android SDK: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-AndroidSdkPath {
    <#
    .SYNOPSIS
    Fix Android SDK PATH issues
    #>
    Write-ComponentHeader "Fixing Android SDK PATH"
    
    $sdkPath = "${env:LOCALAPPDATA}\Android\Sdk"
    $androidPaths = @(
        Join-Path $sdkPath "tools",
        Join-Path $sdkPath "platform-tools",
        Join-Path $sdkPath "bin",
        Join-Path $sdkPath "cmdline-tools\latest\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $androidPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Android SDK paths:" "INFO"
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
            Write-ComponentStep "Added Android SDK paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Android SDK paths already in environment" "INFO"
        }
        
        # Set environment variables
        [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
        [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")
        Write-ComponentStep "Set ANDROID_HOME to: $sdkPath" "SUCCESS"
    } else {
        Write-ComponentStep "No Android SDK paths found" "WARNING"
    }
}

function Uninstall-AndroidSdk {
    <#
    .SYNOPSIS
    Uninstall Android SDK
    #>
    Write-ComponentHeader "Uninstalling Android SDK"
    
    $currentInstallation = Test-AndroidSdkInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Android SDK is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Android SDK from PATH..." "INFO"
    
    # Remove Android SDK paths from environment
    $currentPath = $env:Path
    $sdkPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $sdkPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Remove environment variables
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $null, "User")
    [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $null, "User")
    
    Write-ComponentStep "Android SDK removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Android SDK files may be required" "WARNING"
    
    return $true
}

function Show-AndroidSdkStatus {
    <#
    .SYNOPSIS
    Show comprehensive Android SDK status
    #>
    Write-ComponentHeader "Android SDK Status Report"
    
    $installation = Test-AndroidSdkInstallation -Detailed:$Detailed
    $functionality = Test-AndroidSdkFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  SDK Path: $($installation.SDKPath)" -ForegroundColor White
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
    
    Write-Host "`nAvailable Platforms:" -ForegroundColor Cyan
    if ($installation.PlatformsAvailable.Count -gt 0) {
        foreach ($platform in $installation.PlatformsAvailable) {
            Write-Host "  - $platform" -ForegroundColor White
        }
    } else {
        Write-Host "  No platforms found" -ForegroundColor Gray
    }
    
    Write-Host "`nAvailable Build Tools:" -ForegroundColor Cyan
    if ($installation.BuildToolsAvailable.Count -gt 0) {
        foreach ($buildTool in $installation.BuildToolsAvailable) {
            Write-Host "  - $buildTool" -ForegroundColor White
        }
    } else {
        Write-Host "  No build tools found" -ForegroundColor Gray
    }
    
    Write-Host "`nEnvironment Variables:" -ForegroundColor Cyan
    Write-Host "  ANDROID_HOME: $([Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User'))" -ForegroundColor White
    Write-Host "  ANDROID_SDK_ROOT: $([Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'User'))" -ForegroundColor White
}

function Show-AndroidSdkHelp {
    <#
    .SYNOPSIS
    Show help information for Android SDK component
    #>
    Write-ComponentHeader "Android SDK Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Android SDK" -ForegroundColor White
    Write-Host "  test        - Test Android SDK functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Android SDK" -ForegroundColor White
    Write-Host "  update      - Update Android SDK and packages" -ForegroundColor White
    Write-Host "  check       - Check Android SDK installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Android SDK PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Android SDK" -ForegroundColor White
    Write-Host "  status      - Show Android SDK status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\android-sdk.ps1 install                    # Install Android SDK" -ForegroundColor White
    Write-Host "  .\android-sdk.ps1 test                       # Test Android SDK" -ForegroundColor White
    Write-Host "  .\android-sdk.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\android-sdk.ps1 update                     # Update Android SDK" -ForegroundColor White
    Write-Host "  .\android-sdk.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\android-sdk.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\android-sdk.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Android SDK version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallPlatforms       - Install Android platforms" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-AndroidSdk -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallPlatforms:$InstallPlatforms
        if ($result) {
            Write-ComponentStep "Android SDK installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Android SDK installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-AndroidSdkFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Android SDK functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android SDK functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Android SDK..." "INFO"
        $result = Install-AndroidSdk -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallPlatforms:$InstallPlatforms
        if ($result) {
            Write-ComponentStep "Android SDK reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android SDK reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-AndroidSdk
        if ($result) {
            Write-ComponentStep "Android SDK update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android SDK update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-AndroidSdkInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Android SDK is installed" "SUCCESS"
        } else {
            Write-ComponentStep "Android SDK is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-AndroidSdkPath
        Write-ComponentStep "Android SDK PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-AndroidSdk
        if ($result) {
            Write-ComponentStep "Android SDK uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android SDK uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-AndroidSdkStatus
    }
    "help" {
        Show-AndroidSdkHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-AndroidSdkHelp
        exit 1
    }
}
