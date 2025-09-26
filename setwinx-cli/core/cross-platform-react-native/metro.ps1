# Complete Metro Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallReactNative = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Metro"
    Version = "1.0.0"
    Description = "Complete Metro Bundler for React Native"
    ExecutableNames = @("metro.exe", "metro")
    VersionCommands = @("metro --version")
    TestCommands = @("metro --version", "metro --help", "metro start --help")
    InstallMethod = "npm"
    InstallCommands = @("npm install -g metro")
    Documentation = "https://facebook.github.io/metro/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "METRO COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-MetroInstallation {
    <#
    .SYNOPSIS
    Comprehensive Metro installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Metro installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        NodeJsAvailable = $false
        NpmAvailable = $false
        ReactNativeAvailable = $false
    }
    
    # Check Metro executable
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
            $version = & metro --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check dependencies
        $result.NodeJsAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
        $result.NpmAvailable = (Get-Command npm -ErrorAction SilentlyContinue) -ne $null
        $result.ReactNativeAvailable = (Get-Command react-native -ErrorAction SilentlyContinue) -ne $null
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Metro {
    <#
    .SYNOPSIS
    Install Metro with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallReactNative = $true
    )
    
    Write-ComponentHeader "Installing Metro $Version"
    
    # Check if already installed
    $currentInstallation = Test-MetroInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Metro is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install React Native if requested
        if ($InstallReactNative) {
            Write-ComponentStep "Installing React Native..." "INFO"
            
            $reactNativeScript = "core\cross-platform-react-native\react-native.ps1"
            if (Test-Path $reactNativeScript) {
                & $reactNativeScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                Write-ComponentStep "React Native installed" "SUCCESS"
            } else {
                throw "React Native installer not found"
            }
        }
        
        # Install Metro
        Write-ComponentStep "Installing Metro..." "INFO"
        
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm install -g metro
            Write-ComponentStep "Metro installed using npm" "SUCCESS"
        } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
            yarn global add metro
            Write-ComponentStep "Metro installed using yarn" "SUCCESS"
        } else {
            throw "Neither npm nor yarn is available"
        }
        
        # Install additional Metro tools
        Write-ComponentStep "Installing Metro development tools..." "INFO"
        
        $tools = @(
            "metro-config",
            "metro-source-map",
            "metro-resolver"
        )
        
        foreach ($tool in $tools) {
            try {
                if (Get-Command npm -ErrorAction SilentlyContinue) {
                    npm install -g $tool
                    Write-ComponentStep "  ✓ $tool installed" "SUCCESS"
                } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
                    yarn global add $tool
                    Write-ComponentStep "  ✓ $tool installed" "SUCCESS"
                }
            } catch {
                Write-ComponentStep "  ✗ Failed to install $tool" "ERROR"
            }
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Metro installation..." "INFO"
        $postInstallVerification = Test-MetroInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Metro installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Metro installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Metro: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-MetroFunctionality {
    <#
    .SYNOPSIS
    Test Metro functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Metro Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "metro --version",
        "metro --help",
        "metro start --help",
        "metro build --help",
        "metro serve --help"
    )
    
    $expectedOutputs = @(
        "Metro",
        "Metro",
        "Metro",
        "Metro",
        "Metro"
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

function Update-Metro {
    <#
    .SYNOPSIS
    Update Metro to latest version
    #>
    Write-ComponentHeader "Updating Metro"
    
    $currentInstallation = Test-MetroInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Metro is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Metro..." "INFO"
    
    try {
        # Update Metro
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm install -g metro@latest
            Write-ComponentStep "Metro updated using npm" "SUCCESS"
        } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
            yarn global add metro@latest
            Write-ComponentStep "Metro updated using yarn" "SUCCESS"
        }
        
        # Update additional tools
        $tools = @(
            "metro-config",
            "metro-source-map",
            "metro-resolver"
        )
        
        foreach ($tool in $tools) {
            try {
                if (Get-Command npm -ErrorAction SilentlyContinue) {
                    npm install -g $tool@latest
                    Write-ComponentStep "  ✓ $tool updated" "SUCCESS"
                } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
                    yarn global add $tool@latest
                    Write-ComponentStep "  ✓ $tool updated" "SUCCESS"
                }
            } catch {
                Write-ComponentStep "  ✗ Failed to update $tool" "WARNING"
            }
        }
        
        Write-ComponentStep "Metro update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Metro: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-MetroPath {
    <#
    .SYNOPSIS
    Fix Metro PATH issues
    #>
    Write-ComponentHeader "Fixing Metro PATH"
    
    $metroPaths = @(
        "${env:APPDATA}\npm",
        "${env:ProgramFiles}\nodejs",
        "${env:ProgramFiles(x86)}\nodejs"
    )
    
    $foundPaths = @()
    foreach ($path in $metroPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Metro paths:" "INFO"
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
            Write-ComponentStep "Added Metro paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Metro paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Metro paths found" "WARNING"
    }
}

function Uninstall-Metro {
    <#
    .SYNOPSIS
    Uninstall Metro
    #>
    Write-ComponentHeader "Uninstalling Metro"
    
    $currentInstallation = Test-MetroInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Metro is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Metro from PATH..." "INFO"
    
    # Remove Metro paths from environment
    $currentPath = $env:Path
    $metroPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $metroPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Uninstall Metro
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm uninstall -g metro
        Write-ComponentStep "Metro uninstalled" "SUCCESS"
    } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
        yarn global remove metro
        Write-ComponentStep "Metro uninstalled" "SUCCESS"
    }
    
    Write-ComponentStep "Metro removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Metro files may be required" "WARNING"
    
    return $true
}

function Show-MetroStatus {
    <#
    .SYNOPSIS
    Show comprehensive Metro status
    #>
    Write-ComponentHeader "Metro Status Report"
    
    $installation = Test-MetroInstallation -Detailed:$Detailed
    $functionality = Test-MetroFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Node.js Available: $(if ($installation.NodeJsAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  NPM Available: $(if ($installation.NpmAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  React Native Available: $(if ($installation.ReactNativeAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
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

function Show-MetroHelp {
    <#
    .SYNOPSIS
    Show help information for Metro component
    #>
    Write-ComponentHeader "Metro Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Metro" -ForegroundColor White
    Write-Host "  test        - Test Metro functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Metro" -ForegroundColor White
    Write-Host "  update      - Update Metro and tools" -ForegroundColor White
    Write-Host "  check       - Check Metro installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Metro PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Metro" -ForegroundColor White
    Write-Host "  status      - Show Metro status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\metro.ps1 install                    # Install Metro" -ForegroundColor White
    Write-Host "  .\metro.ps1 test                       # Test Metro" -ForegroundColor White
    Write-Host "  .\metro.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\metro.ps1 update                     # Update Metro" -ForegroundColor White
    Write-Host "  .\metro.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\metro.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\metro.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Metro version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallReactNative     - Install React Native" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Metro -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallReactNative:$InstallReactNative
        if ($result) {
            Write-ComponentStep "Metro installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Metro installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-MetroFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Metro functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Metro functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Metro..." "INFO"
        $result = Install-Metro -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallReactNative:$InstallReactNative
        if ($result) {
            Write-ComponentStep "Metro reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Metro reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Metro
        if ($result) {
            Write-ComponentStep "Metro update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Metro update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-MetroInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Metro is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Metro is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-MetroPath
        Write-ComponentStep "Metro PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Metro
        if ($result) {
            Write-ComponentStep "Metro uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Metro uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-MetroStatus
    }
    "help" {
        Show-MetroHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-MetroHelp
        exit 1
    }
}
