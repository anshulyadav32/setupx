# Complete Flutter Doctor Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallFlutter = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Flutter Doctor"
    Version = "1.0.0"
    Description = "Complete Flutter Doctor Development Environment"
    ExecutableNames = @("flutter.exe")
    VersionCommands = @("flutter doctor --version")
    TestCommands = @("flutter doctor", "flutter doctor --verbose")
    InstallMethod = "flutter"
    Documentation = "https://docs.flutter.dev/get-started/install/windows"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "FLUTTER DOCTOR COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-FlutterDoctorInstallation {
    <#
    .SYNOPSIS
    Comprehensive Flutter Doctor installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Flutter Doctor installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        FlutterAvailable = $false
        DoctorStatus = @{}
        Issues = @()
        Warnings = @()
    }
    
    # Check Flutter executable
    $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCommand) {
        $result.IsInstalled = $true
        $result.ExecutablePath = $flutterCommand.Source
        $result.Paths += $flutterCommand.Source
        $result.FlutterAvailable = $true
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
        
        # Run flutter doctor
        try {
            $doctorOutput = & flutter doctor 2>$null
            if ($doctorOutput) {
                $result.DoctorStatus = @{
                    Output = $doctorOutput
                    HasIssues = $doctorOutput -match "✗"
                    HasWarnings = $doctorOutput -match "!"
                }
                
                # Parse issues and warnings
                $lines = $doctorOutput -split "`n"
                foreach ($line in $lines) {
                    if ($line -match "✗") {
                        $result.Issues += $line.Trim()
                    } elseif ($line -match "!") {
                        $result.Warnings += $line.Trim()
                    }
                }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-FlutterDoctor {
    <#
    .SYNOPSIS
    Install Flutter Doctor with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallFlutter = $true
    )
    
    Write-ComponentHeader "Installing Flutter Doctor $Version"
    
    # Check if already installed
    $currentInstallation = Test-FlutterDoctorInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Flutter Doctor is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install Flutter if requested
        if ($InstallFlutter) {
            Write-ComponentStep "Installing Flutter..." "INFO"
            
            $flutterScript = "core\cross-platform-flutter\flutter.ps1"
            if (Test-Path $flutterScript) {
                & $flutterScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                Write-ComponentStep "Flutter installed" "SUCCESS"
            } else {
                throw "Flutter installer not found"
            }
        }
        
        # Verify Flutter installation
        $flutterInstallation = Test-FlutterDoctorInstallation
        if (-not $flutterInstallation.IsInstalled) {
            throw "Flutter installation failed"
        }
        
        Write-ComponentStep "Flutter Doctor installation verified successfully!" "SUCCESS"
        Write-ComponentStep "Version: $($flutterInstallation.Version)" "INFO"
        
        # Run flutter doctor
        Write-ComponentStep "Running Flutter Doctor..." "INFO"
        try {
            & flutter doctor
            Write-ComponentStep "Flutter Doctor completed" "SUCCESS"
        } catch {
            Write-ComponentStep "Flutter Doctor failed: $($_.Exception.Message)" "WARNING"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Flutter Doctor: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-FlutterDoctorFunctionality {
    <#
    .SYNOPSIS
    Test Flutter Doctor functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Flutter Doctor Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "flutter doctor",
        "flutter doctor --verbose",
        "flutter doctor --android-licenses",
        "flutter config --list",
        "flutter --version"
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

function Update-FlutterDoctor {
    <#
    .SYNOPSIS
    Update Flutter Doctor to latest version
    #>
    Write-ComponentHeader "Updating Flutter Doctor"
    
    $currentInstallation = Test-FlutterDoctorInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Flutter Doctor is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Flutter Doctor..." "INFO"
    
    try {
        # Update Flutter
        $flutterScript = "core\cross-platform-flutter\flutter.ps1"
        if (Test-Path $flutterScript) {
            & $flutterScript update -Quiet:$Quiet
            Write-ComponentStep "Flutter updated" "SUCCESS"
        }
        
        # Run flutter doctor
        Write-ComponentStep "Running Flutter Doctor..." "INFO"
        try {
            & flutter doctor
            Write-ComponentStep "Flutter Doctor completed" "SUCCESS"
        } catch {
            Write-ComponentStep "Flutter Doctor failed: $($_.Exception.Message)" "WARNING"
        }
        
        Write-ComponentStep "Flutter Doctor update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Flutter Doctor: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-FlutterDoctorPath {
    <#
    .SYNOPSIS
    Fix Flutter Doctor PATH issues
    #>
    Write-ComponentHeader "Fixing Flutter Doctor PATH"
    
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
        Write-ComponentStep "Found Flutter Doctor paths:" "INFO"
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
            Write-ComponentStep "Added Flutter Doctor paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter Doctor paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Flutter Doctor paths found" "WARNING"
    }
}

function Uninstall-FlutterDoctor {
    <#
    .SYNOPSIS
    Uninstall Flutter Doctor
    #>
    Write-ComponentHeader "Uninstalling Flutter Doctor"
    
    $currentInstallation = Test-FlutterDoctorInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Flutter Doctor is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Flutter Doctor from PATH..." "INFO"
    
    # Remove Flutter Doctor paths from environment
    $currentPath = $env:Path
    $flutterPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $flutterPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Flutter Doctor removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Flutter Doctor files may be required" "WARNING"
    
    return $true
}

function Show-FlutterDoctorStatus {
    <#
    .SYNOPSIS
    Show comprehensive Flutter Doctor status
    #>
    Write-ComponentHeader "Flutter Doctor Status Report"
    
    $installation = Test-FlutterDoctorInstallation -Detailed:$Detailed
    $functionality = Test-FlutterDoctorFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Flutter Available: $(if ($installation.FlutterAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
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
        
        if ($installation.Issues.Count -gt 0) {
            Write-Host "`nIssues:" -ForegroundColor Red
            foreach ($issue in $installation.Issues) {
                Write-Host "  - $issue" -ForegroundColor Red
            }
        }
        
        if ($installation.Warnings.Count -gt 0) {
            Write-Host "`nWarnings:" -ForegroundColor Yellow
            foreach ($warning in $installation.Warnings) {
                Write-Host "  - $warning" -ForegroundColor Yellow
            }
        }
    }
}

function Show-FlutterDoctorHelp {
    <#
    .SYNOPSIS
    Show help information for Flutter Doctor component
    #>
    Write-ComponentHeader "Flutter Doctor Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Flutter Doctor" -ForegroundColor White
    Write-Host "  test        - Test Flutter Doctor functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Flutter Doctor" -ForegroundColor White
    Write-Host "  update      - Update Flutter Doctor" -ForegroundColor White
    Write-Host "  check       - Check Flutter Doctor installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Flutter Doctor PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Flutter Doctor" -ForegroundColor White
    Write-Host "  status      - Show Flutter Doctor status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\flutter-doctor.ps1 install                    # Install Flutter Doctor" -ForegroundColor White
    Write-Host "  .\flutter-doctor.ps1 test                       # Test Flutter Doctor" -ForegroundColor White
    Write-Host "  .\flutter-doctor.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\flutter-doctor.ps1 update                     # Update Flutter Doctor" -ForegroundColor White
    Write-Host "  .\flutter-doctor.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\flutter-doctor.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\flutter-doctor.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Flutter Doctor version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallFlutter         - Install Flutter" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-FlutterDoctor -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallFlutter:$InstallFlutter
        if ($result) {
            Write-ComponentStep "Flutter Doctor installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter Doctor installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-FlutterDoctorFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Flutter Doctor functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter Doctor functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Flutter Doctor..." "INFO"
        $result = Install-FlutterDoctor -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallFlutter:$InstallFlutter
        if ($result) {
            Write-ComponentStep "Flutter Doctor reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter Doctor reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-FlutterDoctor
        if ($result) {
            Write-ComponentStep "Flutter Doctor update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter Doctor update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-FlutterDoctorInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Flutter Doctor is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter Doctor is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-FlutterDoctorPath
        Write-ComponentStep "Flutter Doctor PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-FlutterDoctor
        if ($result) {
            Write-ComponentStep "Flutter Doctor uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Flutter Doctor uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-FlutterDoctorStatus
    }
    "help" {
        Show-FlutterDoctorHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-FlutterDoctorHelp
        exit 1
    }
}
