# Complete Hermes Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Hermes"
    Version = "1.0.0"
    Description = "Complete Hermes JavaScript Engine for React Native"
    ExecutableNames = @("hermes.exe", "hermes")
    VersionCommands = @("hermes --version")
    TestCommands = @("hermes --version", "hermes --help", "hermesc --version")
    InstallMethod = "npm"
    InstallCommands = @("npm install -g hermes")
    Documentation = "https://hermesengine.dev/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "HERMES COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-HermesInstallation {
    <#
    .SYNOPSIS
    Comprehensive Hermes installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Hermes installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        NodeJsAvailable = $false
        NpmAvailable = $false
        ReactNativeAvailable = $false
        MetroAvailable = $false
    }
    
    # Check Hermes executable
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
            $version = & hermes --version 2>$null
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
        $result.MetroAvailable = (Get-Command metro -ErrorAction SilentlyContinue) -ne $null
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Hermes {
    <#
    .SYNOPSIS
    Install Hermes with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallReactNative = $true
    )
    
    Write-ComponentHeader "Installing Hermes $Version"
    
    # Check if already installed
    $currentInstallation = Test-HermesInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Hermes is already installed: $($currentInstallation.Version)" "WARNING"
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
        
        # Install Hermes
        Write-ComponentStep "Installing Hermes..." "INFO"
        
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm install -g hermes
            Write-ComponentStep "Hermes installed using npm" "SUCCESS"
        } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
            yarn global add hermes
            Write-ComponentStep "Hermes installed using yarn" "SUCCESS"
        } else {
            throw "Neither npm nor yarn is available"
        }
        
        # Install additional Hermes tools
        Write-ComponentStep "Installing Hermes development tools..." "INFO"
        
        $tools = @(
            "hermes-engine",
            "hermes-parser",
            "hermes-eslint"
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
        Write-ComponentStep "Verifying Hermes installation..." "INFO"
        $postInstallVerification = Test-HermesInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Hermes installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Hermes installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Hermes: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-HermesFunctionality {
    <#
    .SYNOPSIS
    Test Hermes functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Hermes Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "hermes --version",
        "hermes --help",
        "hermesc --version",
        "hermesc --help",
        "node --version"
    )
    
    $expectedOutputs = @(
        "Hermes",
        "Hermes",
        "Hermes",
        "Hermes",
        "v"
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

function Update-Hermes {
    <#
    .SYNOPSIS
    Update Hermes to latest version
    #>
    Write-ComponentHeader "Updating Hermes"
    
    $currentInstallation = Test-HermesInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Hermes is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Hermes..." "INFO"
    
    try {
        # Update Hermes
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm install -g hermes@latest
            Write-ComponentStep "Hermes updated using npm" "SUCCESS"
        } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
            yarn global add hermes@latest
            Write-ComponentStep "Hermes updated using yarn" "SUCCESS"
        }
        
        # Update additional tools
        $tools = @(
            "hermes-engine",
            "hermes-parser",
            "hermes-eslint"
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
        
        Write-ComponentStep "Hermes update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Hermes: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-HermesPath {
    <#
    .SYNOPSIS
    Fix Hermes PATH issues
    #>
    Write-ComponentHeader "Fixing Hermes PATH"
    
    $hermesPaths = @(
        "${env:APPDATA}\npm",
        "${env:ProgramFiles}\nodejs",
        "${env:ProgramFiles(x86)}\nodejs"
    )
    
    $foundPaths = @()
    foreach ($path in $hermesPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Hermes paths:" "INFO"
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
            Write-ComponentStep "Added Hermes paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Hermes paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Hermes paths found" "WARNING"
    }
}

function Uninstall-Hermes {
    <#
    .SYNOPSIS
    Uninstall Hermes
    #>
    Write-ComponentHeader "Uninstalling Hermes"
    
    $currentInstallation = Test-HermesInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Hermes is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Hermes from PATH..." "INFO"
    
    # Remove Hermes paths from environment
    $currentPath = $env:Path
    $hermesPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $hermesPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Uninstall Hermes
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm uninstall -g hermes
        Write-ComponentStep "Hermes uninstalled" "SUCCESS"
    } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
        yarn global remove hermes
        Write-ComponentStep "Hermes uninstalled" "SUCCESS"
    }
    
    Write-ComponentStep "Hermes removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Hermes files may be required" "WARNING"
    
    return $true
}

function Show-HermesStatus {
    <#
    .SYNOPSIS
    Show comprehensive Hermes status
    #>
    Write-ComponentHeader "Hermes Status Report"
    
    $installation = Test-HermesInstallation -Detailed:$Detailed
    $functionality = Test-HermesFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Node.js Available: $(if ($installation.NodeJsAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  NPM Available: $(if ($installation.NpmAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  React Native Available: $(if ($installation.ReactNativeAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Metro Available: $(if ($installation.MetroAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
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

function Show-HermesHelp {
    <#
    .SYNOPSIS
    Show help information for Hermes component
    #>
    Write-ComponentHeader "Hermes Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Hermes" -ForegroundColor White
    Write-Host "  test        - Test Hermes functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Hermes" -ForegroundColor White
    Write-Host "  update      - Update Hermes and tools" -ForegroundColor White
    Write-Host "  check       - Check Hermes installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Hermes PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Hermes" -ForegroundColor White
    Write-Host "  status      - Show Hermes status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\hermes.ps1 install                    # Install Hermes" -ForegroundColor White
    Write-Host "  .\hermes.ps1 test                       # Test Hermes" -ForegroundColor White
    Write-Host "  .\hermes.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\hermes.ps1 update                     # Update Hermes" -ForegroundColor White
    Write-Host "  .\hermes.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\hermes.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\hermes.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Hermes version to install" -ForegroundColor White
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
        $result = Install-Hermes -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallReactNative:$InstallReactNative
        if ($result) {
            Write-ComponentStep "Hermes installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Hermes installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-HermesFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Hermes functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Hermes functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Hermes..." "INFO"
        $result = Install-Hermes -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallReactNative:$InstallReactNative
        if ($result) {
            Write-ComponentStep "Hermes reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Hermes reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Hermes
        if ($result) {
            Write-ComponentStep "Hermes update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Hermes update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-HermesInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Hermes is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Hermes is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-HermesPath
        Write-ComponentStep "Hermes PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Hermes
        if ($result) {
            Write-ComponentStep "Hermes uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Hermes uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-HermesStatus
    }
    "help" {
        Show-HermesHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-HermesHelp
        exit 1
    }
}
