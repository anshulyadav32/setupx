# Complete Android Studio Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallSDK = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Android Studio"
    Version = "1.0.0"
    Description = "Complete Android Studio Development Environment"
    ExecutableNames = @("studio.exe", "studio64.exe")
    VersionCommands = @()
    TestCommands = @("Test-Path `"${env:ProgramFiles}\\Android\\Android Studio\\bin\\studio.exe`"", "Test-Path `"${env:ProgramFiles(x86)}\\Android\\Android Studio\\bin\\studio.exe`"")
    WingetId = "Google.AndroidStudio"
    ChocoId = "androidstudio"
    DownloadUrl = "https://developer.android.com/studio"
    Documentation = "https://developer.android.com/studio"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "ANDROID STUDIO COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-AndroidStudioInstallation {
    <#
    .SYNOPSIS
    Comprehensive Android Studio installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Android Studio installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        SDKPath = ""
        SDKAvailable = $false
    }
    
    # Check Android Studio executable
    $studioPaths = @(
        "${env:ProgramFiles}\Android\Android Studio\bin\studio.exe",
        "${env:ProgramFiles(x86)}\Android\Android Studio\bin\studio.exe",
        "${env:LOCALAPPDATA}\Android\Sdk\bin\studio.exe"
    )
    
    foreach ($path in $studioPaths) {
        if (Test-Path $path) {
            $result.IsInstalled = $true
            $result.ExecutablePath = $path
            $result.Paths += $path
            break
        }
    }
    
    # Check Android SDK
    $sdkPaths = @(
        "${env:LOCALAPPDATA}\Android\Sdk",
        "${env:ProgramFiles}\Android\Sdk",
        "${env:ProgramFiles(x86)}\Android\Sdk"
    )
    
    foreach ($path in $sdkPaths) {
        if (Test-Path $path) {
            $result.SDKPath = $path
            $result.SDKAvailable = $true
            break
        }
    }
    
    if ($result.IsInstalled) {
        $result.Status = "Installed"
        $result.Version = "Android Studio (Installed)"
    }
    
    return $result
}

function Install-AndroidStudio {
    <#
    .SYNOPSIS
    Install Android Studio with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallSDK = $true
    )
    
    Write-ComponentHeader "Installing Android Studio $Version"
    
    # Check if already installed
    $currentInstallation = Test-AndroidStudioInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Android Studio is already installed" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Android Studio using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Android Studio installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Android Studio using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Android Studio installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Android Studio manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 10
        
        # Verify installation
        Write-ComponentStep "Verifying Android Studio installation..." "INFO"
        $postInstallVerification = Test-AndroidStudioInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Android Studio installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Executable: $($postInstallVerification.ExecutablePath)" "INFO"
        } else {
            Write-ComponentStep "Android Studio installation verification failed" "WARNING"
            return $false
        }
        
        # Install Android SDK if requested
        if ($InstallSDK) {
            Write-ComponentStep "Installing Android SDK..." "INFO"
            
            $sdkPath = "${env:LOCALAPPDATA}\Android\Sdk"
            if (-not (Test-Path $sdkPath)) {
                New-Item -ItemType Directory -Path $sdkPath -Force | Out-Null
            }
            
            # Set environment variables
            [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
            [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")
            
            # Add to PATH
            $sdkToolsPath = Join-Path $sdkPath "tools"
            $sdkPlatformToolsPath = Join-Path $sdkPath "platform-tools"
            $sdkBinPath = Join-Path $sdkPath "bin"
            
            $currentPath = $env:Path
            $newPath = $currentPath + ";" + $sdkToolsPath + ";" + $sdkPlatformToolsPath + ";" + $sdkBinPath
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = $newPath
            
            Write-ComponentStep "Android SDK environment configured" "SUCCESS"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Android Studio: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-AndroidStudioFunctionality {
    <#
    .SYNOPSIS
    Test Android Studio functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Android Studio Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "Test-Path `"${env:ProgramFiles}\\Android\\Android Studio\\bin\\studio.exe`"",
        "Test-Path `"${env:ProgramFiles(x86)}\\Android\\Android Studio\\bin\\studio.exe`"",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk`"",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk\\platform-tools\\adb.exe`"",
        "Test-Path `"${env:LOCALAPPDATA}\\Android\\Sdk\\tools\\sdkmanager.exe`""
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

function Update-AndroidStudio {
    <#
    .SYNOPSIS
    Update Android Studio to latest version
    #>
    Write-ComponentHeader "Updating Android Studio"
    
    $currentInstallation = Test-AndroidStudioInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Android Studio is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Android Studio..." "INFO"
    
    try {
        # Update Android Studio using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Android Studio updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Android Studio updated using Chocolatey" "SUCCESS"
        }
        
        # Update Android SDK
        if ($currentInstallation.SDKAvailable) {
            Write-ComponentStep "Updating Android SDK..." "INFO"
            $sdkManager = Join-Path $currentInstallation.SDKPath "cmdline-tools\latest\bin\sdkmanager.bat"
            if (Test-Path $sdkManager) {
                & $sdkManager --update
                Write-ComponentStep "Android SDK updated" "SUCCESS"
            }
        }
        
        Write-ComponentStep "Android Studio update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Android Studio: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-AndroidStudioPath {
    <#
    .SYNOPSIS
    Fix Android Studio PATH issues
    #>
    Write-ComponentHeader "Fixing Android Studio PATH"
    
    $androidPaths = @(
        "${env:ProgramFiles}\Android\Android Studio\bin",
        "${env:ProgramFiles(x86)}\Android\Android Studio\bin",
        "${env:LOCALAPPDATA}\Android\Sdk\tools",
        "${env:LOCALAPPDATA}\Android\Sdk\platform-tools",
        "${env:LOCALAPPDATA}\Android\Sdk\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $androidPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Android Studio paths:" "INFO"
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
            Write-ComponentStep "Added Android Studio paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Android Studio paths already in environment" "INFO"
        }
        
        # Set ANDROID_HOME
        $sdkPath = "${env:LOCALAPPDATA}\Android\Sdk"
        if (Test-Path $sdkPath) {
            [Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
            [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")
            Write-ComponentStep "Set ANDROID_HOME to: $sdkPath" "SUCCESS"
        }
    } else {
        Write-ComponentStep "No Android Studio paths found" "WARNING"
    }
}

function Uninstall-AndroidStudio {
    <#
    .SYNOPSIS
    Uninstall Android Studio
    #>
    Write-ComponentHeader "Uninstalling Android Studio"
    
    $currentInstallation = Test-AndroidStudioInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Android Studio is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Android Studio from PATH..." "INFO"
    
    # Remove Android Studio paths from environment
    $currentPath = $env:Path
    $androidPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $androidPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Remove environment variables
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $null, "User")
    [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $null, "User")
    
    Write-ComponentStep "Android Studio removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Android Studio files may be required" "WARNING"
    
    return $true
}

function Show-AndroidStudioStatus {
    <#
    .SYNOPSIS
    Show comprehensive Android Studio status
    #>
    Write-ComponentHeader "Android Studio Status Report"
    
    $installation = Test-AndroidStudioInstallation -Detailed:$Detailed
    $functionality = Test-AndroidStudioFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  SDK Path: $($installation.SDKPath)" -ForegroundColor White
    Write-Host "  SDK Available: $(if ($installation.SDKAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    Write-Host "`nEnvironment Variables:" -ForegroundColor Cyan
    Write-Host "  ANDROID_HOME: $([Environment]::GetEnvironmentVariable('ANDROID_HOME', 'User'))" -ForegroundColor White
    Write-Host "  ANDROID_SDK_ROOT: $([Environment]::GetEnvironmentVariable('ANDROID_SDK_ROOT', 'User'))" -ForegroundColor White
}

function Show-AndroidStudioHelp {
    <#
    .SYNOPSIS
    Show help information for Android Studio component
    #>
    Write-ComponentHeader "Android Studio Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Android Studio" -ForegroundColor White
    Write-Host "  test        - Test Android Studio functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Android Studio" -ForegroundColor White
    Write-Host "  update      - Update Android Studio and SDK" -ForegroundColor White
    Write-Host "  check       - Check Android Studio installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Android Studio PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Android Studio" -ForegroundColor White
    Write-Host "  status      - Show Android Studio status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\android-studio.ps1 install                    # Install Android Studio" -ForegroundColor White
    Write-Host "  .\android-studio.ps1 test                       # Test Android Studio" -ForegroundColor White
    Write-Host "  .\android-studio.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\android-studio.ps1 update                     # Update Android Studio" -ForegroundColor White
    Write-Host "  .\android-studio.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\android-studio.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\android-studio.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Android Studio version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallSDK            - Install Android SDK" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-AndroidStudio -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallSDK:$InstallSDK
        if ($result) {
            Write-ComponentStep "Android Studio installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Android Studio installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-AndroidStudioFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Android Studio functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android Studio functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Android Studio..." "INFO"
        $result = Install-AndroidStudio -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallSDK:$InstallSDK
        if ($result) {
            Write-ComponentStep "Android Studio reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android Studio reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-AndroidStudio
        if ($result) {
            Write-ComponentStep "Android Studio update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android Studio update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-AndroidStudioInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Android Studio is installed" "SUCCESS"
        } else {
            Write-ComponentStep "Android Studio is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-AndroidStudioPath
        Write-ComponentStep "Android Studio PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-AndroidStudio
        if ($result) {
            Write-ComponentStep "Android Studio uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Android Studio uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-AndroidStudioStatus
    }
    "help" {
        Show-AndroidStudioHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-AndroidStudioHelp
        exit 1
    }
}
