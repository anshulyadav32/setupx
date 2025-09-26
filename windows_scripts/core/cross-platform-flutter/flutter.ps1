# Complete Flutter Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallDart = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Flutter"
    Version = "1.0.0"
    Description = "Complete Flutter Cross-Platform Development Environment"
    ExecutableNames = @("flutter.exe", "flutter")
    VersionCommands = @("flutter --version")
    TestCommands = @("flutter --version", "flutter doctor", "flutter --help")
    WingetId = "Google.Flutter"
    ChocoId = "flutter"
    DownloadUrl = "https://docs.flutter.dev/get-started/install/windows"
    Documentation = "https://docs.flutter.dev/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "FLUTTER COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-FlutterInstallation {
    <#
    .SYNOPSIS
    Comprehensive Flutter installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Flutter installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        FlutterPath = ""
        DartAvailable = $false
        DoctorStatus = @{}
    }
    
    # Check Flutter executable
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
            $version = & flutter --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check Dart availability
        $result.DartAvailable = (Get-Command dart -ErrorAction SilentlyContinue) -ne $null
        
        # Run flutter doctor
        try {
            $doctorOutput = & flutter doctor 2>$null
            if ($doctorOutput) {
                $result.DoctorStatus = @{
                    Output = $doctorOutput
                    HasIssues = $doctorOutput -match "✗"
                    HasWarnings = $doctorOutput -match "!"
                }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Flutter {
    <#
    .SYNOPSIS
    Install Flutter with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallDart = $true
    )
    
    Write-ComponentHeader "Installing Flutter $Version"
    
    # Check if already installed
    $currentInstallation = Test-FlutterInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Flutter is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Flutter using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Flutter installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Flutter using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Flutter installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Flutter manually..." "INFO"
            
            # Download Flutter SDK
            $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip"
            $flutterZip = "$env:TEMP\flutter.zip"
            $flutterDir = "${env:ProgramFiles}\flutter"
            
            # Create Flutter directory
            if (-not (Test-Path $flutterDir)) {
                New-Item -ItemType Directory -Path $flutterDir -Force | Out-Null
            }
            
            # Download Flutter
            Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
            Write-ComponentStep "Flutter downloaded" "SUCCESS"
            
            # Extract Flutter
            Expand-Archive -Path $flutterZip -DestinationPath $flutterDir -Force
            Remove-Item $flutterZip -Force
            
            Write-ComponentStep "Flutter extracted" "SUCCESS"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Flutter installation..." "INFO"
        $postInstallVerification = Test-FlutterInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Flutter installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Flutter installation verification failed" "WARNING"
            return $false
        }
        
        # Install Dart if requested
        if ($InstallDart) {
            Write-ComponentStep "Installing Dart..." "INFO"
            
            $dartScript = "core\cross-platform-flutter\dart.ps1"
            if (Test-Path $dartScript) {
                & $dartScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                Write-ComponentStep "Dart installed" "SUCCESS"
            } else {
                Write-ComponentStep "Dart installer not found" "WARNING"
            }
        }
        
        # Run flutter doctor
        Write-ComponentStep "Running Flutter doctor..." "INFO"
        try {
            & flutter doctor
            Write-ComponentStep "Flutter doctor completed" "SUCCESS"
        } catch {
            Write-ComponentStep "Flutter doctor failed: $($_.Exception.Message)" "WARNING"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Flutter: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-FlutterFunctionality {
    <#
    .SYNOPSIS
    Test Flutter functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Flutter Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "flutter --version",
        "flutter --help",
        "flutter doctor",
        "flutter config --list",
        "flutter create --help"
    )
    
    $expectedOutputs = @(
        "Flutter",
        "Flutter",
        "Flutter",
        "Flutter",
        "Flutter"
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

function Update-Flutter {
    <#
    .SYNOPSIS
    Update Flutter to latest version
    #>
    Write-ComponentHeader "Updating Flutter"
    
    $currentInstallation = Test-FlutterInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Flutter is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Flutter..." "INFO"
    
    try {
        # Update Flutter using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Flutter updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Flutter updated using Chocolatey" "SUCCESS"
        }
        # Update using Flutter itself
        else {
            flutter upgrade
            Write-ComponentStep "Flutter updated using Flutter" "SUCCESS"
        }
        
        # Update Dart
        $dartScript = "core\cross-platform-flutter\dart.ps1"
        if (Test-Path $dartScript) {
            & $dartScript update -Quiet:$Quiet
            Write-ComponentStep "Dart updated" "SUCCESS"
        }
        
        Write-ComponentStep "Flutter update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Flutter: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-FlutterPath {
    <#
    .SYNOPSIS
    Fix Flutter PATH issues
    #>
    Write-ComponentHeader "Fixing Flutter PATH"
    
    $flutterPaths = @(
        "${env:ProgramFiles}\flutter\bin",
        "${env:ProgramFiles(x86)}\flutter\bin",
        "${env:LOCALAPPDATA}\flutter\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $flutterPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Flutter paths:" "INFO"
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
            Write-ComponentStep "Added Flutter paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Flutter paths found" "WARNING"
    }
}

function Uninstall-Flutter {
    <#
    .SYNOPSIS
    Uninstall Flutter
    #>
    Write-ComponentHeader "Uninstalling Flutter"
    
    $currentInstallation = Test-FlutterInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Flutter is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Flutter from PATH..." "INFO"
    
    # Remove Flutter paths from environment
    $currentPath = $env:Path
    $flutterPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $flutterPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Flutter removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Flutter files may be required" "WARNING"
    
    return $true
}

function Show-FlutterStatus {
    <#
    .SYNOPSIS
    Show comprehensive Flutter status
    #>
    Write-ComponentHeader "Flutter Status Report"
    
    $installation = Test-FlutterInstallation -Detailed:$Detailed
    $functionality = Test-FlutterFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Dart Available: $(if ($installation.DartAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.DoctorStatus.Count -gt 0) {
        Write-Host "`nFlutter Doctor Status:" -ForegroundColor Cyan
        Write-Host "  Has Issues: $(if ($installation.DoctorStatus.HasIssues) { 'Yes' } else { 'No' })" -ForegroundColor White
        Write-Host "  Has Warnings: $(if ($installation.DoctorStatus.HasWarnings) { 'Yes' } else { 'No' })" -ForegroundColor White
    }
}

function Show-FlutterHelp {
    <#
    .SYNOPSIS
    Show help information for Flutter component
    #>
    Write-ComponentHeader "Flutter Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Flutter" -ForegroundColor White
    Write-Host "  test        - Test Flutter functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Flutter" -ForegroundColor White
    Write-Host "  update      - Update Flutter and Dart" -ForegroundColor White
    Write-Host "  check       - Check Flutter installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Flutter PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Flutter" -ForegroundColor White
    Write-Host "  status      - Show Flutter status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\flutter.ps1 install                    # Install Flutter" -ForegroundColor White
    Write-Host "  .\flutter.ps1 test                       # Test Flutter" -ForegroundColor White
    Write-Host "  .\flutter.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\flutter.ps1 update                     # Update Flutter" -ForegroundColor White
    Write-Host "  .\flutter.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\flutter.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\flutter.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Flutter version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallDart           - Install Dart" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Flutter -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallDart:$InstallDart
        if ($result) {
            Write-ComponentStep "Flutter installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-FlutterFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Flutter functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Flutter..." "INFO"
        $result = Install-Flutter -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallDart:$InstallDart
        if ($result) {
            Write-ComponentStep "Flutter reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Flutter
        if ($result) {
            Write-ComponentStep "Flutter update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-FlutterInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Flutter is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-FlutterPath
        Write-ComponentStep "Flutter PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Flutter
        if ($result) {
            Write-ComponentStep "Flutter uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-FlutterStatus
    }
    "help" {
        Show-FlutterHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-FlutterHelp
        exit 1
    }
}
