# Complete Dart Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Dart"
    Version = "1.0.0"
    Description = "Complete Dart Programming Language Environment"
    ExecutableNames = @("dart.exe", "dart")
    VersionCommands = @("dart --version")
    TestCommands = @("dart --version", "dart --help", "dart analyze --help")
    WingetId = "Google.Dart"
    ChocoId = "dart"
    DownloadUrl = "https://dart.dev/get-dart"
    Documentation = "https://dart.dev/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "DART COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-DartInstallation {
    <#
    .SYNOPSIS
    Comprehensive Dart installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Dart installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        FlutterAvailable = $false
        PubAvailable = $false
    }
    
    # Check Dart executable
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
            $version = & dart --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check Flutter availability
        $result.FlutterAvailable = (Get-Command flutter -ErrorAction SilentlyContinue) -ne $null
        
        # Check Pub availability
        $result.PubAvailable = (Get-Command pub -ErrorAction SilentlyContinue) -ne $null
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Dart {
    <#
    .SYNOPSIS
    Install Dart with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallFlutter = $true
    )
    
    Write-ComponentHeader "Installing Dart $Version"
    
    # Check if already installed
    $currentInstallation = Test-DartInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Dart is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Dart using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Dart installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Dart using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Dart installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Dart manually..." "INFO"
            
            # Download Dart SDK
            $dartUrl = "https://storage.googleapis.com/dart-archive/channels/stable/release/latest/windows/dart_windows_x64.zip"
            $dartZip = "$env:TEMP\dart.zip"
            $dartDir = "${env:ProgramFiles}\dart"
            
            # Create Dart directory
            if (-not (Test-Path $dartDir)) {
                New-Item -ItemType Directory -Path $dartDir -Force | Out-Null
            }
            
            # Download Dart
            Invoke-WebRequest -Uri $dartUrl -OutFile $dartZip -UseBasicParsing
            Write-ComponentStep "Dart downloaded" "SUCCESS"
            
            # Extract Dart
            Expand-Archive -Path $dartZip -DestinationPath $dartDir -Force
            Remove-Item $dartZip -Force
            
            Write-ComponentStep "Dart extracted" "SUCCESS"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Dart installation..." "INFO"
        $postInstallVerification = Test-DartInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Dart installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Dart installation verification failed" "WARNING"
            return $false
        }
        
        # Install Flutter if requested
        if ($InstallFlutter) {
            Write-ComponentStep "Installing Flutter..." "INFO"
            
            $flutterScript = "core\cross-platform-flutter\flutter.ps1"
            if (Test-Path $flutterScript) {
                & $flutterScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                Write-ComponentStep "Flutter installed" "SUCCESS"
            } else {
                Write-ComponentStep "Flutter installer not found" "WARNING"
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Dart: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-DartFunctionality {
    <#
    .SYNOPSIS
    Test Dart functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Dart Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "dart --version",
        "dart --help",
        "dart analyze --help",
        "dart pub --help",
        "dart compile --help"
    )
    
    $expectedOutputs = @(
        "Dart",
        "Dart",
        "Dart",
        "Dart",
        "Dart"
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

function Update-Dart {
    <#
    .SYNOPSIS
    Update Dart to latest version
    #>
    Write-ComponentHeader "Updating Dart"
    
    $currentInstallation = Test-DartInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Dart is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Dart..." "INFO"
    
    try {
        # Update Dart using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Dart updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Dart updated using Chocolatey" "SUCCESS"
        }
        
        # Update Flutter
        $flutterScript = "core\cross-platform-flutter\flutter.ps1"
        if (Test-Path $flutterScript) {
            & $flutterScript update -Quiet:$Quiet
            Write-ComponentStep "Flutter updated" "SUCCESS"
        }
        
        Write-ComponentStep "Dart update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Dart: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-DartPath {
    <#
    .SYNOPSIS
    Fix Dart PATH issues
    #>
    Write-ComponentHeader "Fixing Dart PATH"
    
    $dartPaths = @(
        "${env:ProgramFiles}\dart\bin",
        "${env:ProgramFiles(x86)}\dart\bin",
        "${env:LOCALAPPDATA}\dart\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $dartPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Dart paths:" "INFO"
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
            Write-ComponentStep "Added Dart paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Dart paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Dart paths found" "WARNING"
    }
}

function Uninstall-Dart {
    <#
    .SYNOPSIS
    Uninstall Dart
    #>
    Write-ComponentHeader "Uninstalling Dart"
    
    $currentInstallation = Test-DartInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Dart is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Dart from PATH..." "INFO"
    
    # Remove Dart paths from environment
    $currentPath = $env:Path
    $dartPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $dartPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Dart removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Dart files may be required" "WARNING"
    
    return $true
}

function Show-DartStatus {
    <#
    .SYNOPSIS
    Show comprehensive Dart status
    #>
    Write-ComponentHeader "Dart Status Report"
    
    $installation = Test-DartInstallation -Detailed:$Detailed
    $functionality = Test-DartFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Flutter Available: $(if ($installation.FlutterAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Pub Available: $(if ($installation.PubAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-DartHelp {
    <#
    .SYNOPSIS
    Show help information for Dart component
    #>
    Write-ComponentHeader "Dart Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Dart" -ForegroundColor White
    Write-Host "  test        - Test Dart functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Dart" -ForegroundColor White
    Write-Host "  update      - Update Dart and Flutter" -ForegroundColor White
    Write-Host "  check       - Check Dart installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Dart PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Dart" -ForegroundColor White
    Write-Host "  status      - Show Dart status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\dart.ps1 install                    # Install Dart" -ForegroundColor White
    Write-Host "  .\dart.ps1 test                       # Test Dart" -ForegroundColor White
    Write-Host "  .\dart.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\dart.ps1 update                     # Update Dart" -ForegroundColor White
    Write-Host "  .\dart.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\dart.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\dart.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Dart version to install" -ForegroundColor White
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
        $result = Install-Dart -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallFlutter:$InstallFlutter
        if ($result) {
            Write-ComponentStep "Dart installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Dart installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-DartFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Dart functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Dart functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Dart..." "INFO"
        $result = Install-Dart -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallFlutter:$InstallFlutter
        if ($result) {
            Write-ComponentStep "Dart reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Dart reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Dart
        if ($result) {
            Write-ComponentStep "Dart update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Dart update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-DartInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Dart is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Dart is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-DartPath
        Write-ComponentStep "Dart PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Dart
        if ($result) {
            Write-ComponentStep "Dart uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Dart uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-DartStatus
    }
    "help" {
        Show-DartHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-DartHelp
        exit 1
    }
}
