# Complete React Native Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallNodeJs = $true
)

# Component Information
$ComponentInfo = @{
    Name = "React Native"
    Version = "1.0.0"
    Description = "Complete React Native Cross-Platform Development Environment"
    ExecutableNames = @("react-native.exe", "react-native")
    VersionCommands = @("react-native --version")
    TestCommands = @("react-native --version", "react-native --help", "react-native init --help")
    InstallMethod = "npm"
    InstallCommands = @("npm install -g react-native-cli")
    Documentation = "https://reactnative.dev/docs/getting-started"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "REACT NATIVE COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-ReactNativeInstallation {
    <#
    .SYNOPSIS
    Comprehensive React Native installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking React Native installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        NodeJsAvailable = $false
        NpmAvailable = $false
        YarnAvailable = $false
        MetroAvailable = $false
    }
    
    # Check React Native executable
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
            $version = & react-native --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check dependencies
        $result.NodeJsAvailable = (Get-Command node -ErrorAction SilentlyContinue) -ne $null
        $result.NpmAvailable = (Get-Command npm -ErrorAction SilentlyContinue) -ne $null
        $result.YarnAvailable = (Get-Command yarn -ErrorAction SilentlyContinue) -ne $null
        $result.MetroAvailable = (Get-Command metro -ErrorAction SilentlyContinue) -ne $null
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-ReactNative {
    <#
    .SYNOPSIS
    Install React Native with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallNodeJs = $true
    )
    
    Write-ComponentHeader "Installing React Native $Version"
    
    # Check if already installed
    $currentInstallation = Test-ReactNativeInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "React Native is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install Node.js if requested
        if ($InstallNodeJs) {
            Write-ComponentStep "Installing Node.js..." "INFO"
            
            $nodeScript = "core\web-development\nodejs.ps1"
            if (Test-Path $nodeScript) {
                & $nodeScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                Write-ComponentStep "Node.js installed" "SUCCESS"
            } else {
                throw "Node.js installer not found"
            }
        }
        
        # Install React Native CLI
        Write-ComponentStep "Installing React Native CLI..." "INFO"
        
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm install -g react-native-cli
            Write-ComponentStep "React Native CLI installed using npm" "SUCCESS"
        } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
            yarn global add react-native-cli
            Write-ComponentStep "React Native CLI installed using yarn" "SUCCESS"
        } else {
            throw "Neither npm nor yarn is available"
        }
        
        # Install additional React Native tools
        Write-ComponentStep "Installing React Native development tools..." "INFO"
        
        $tools = @(
            "metro",
            "react-native-community-cli",
            "react-native-debugger",
            "react-native-tools"
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
        Write-ComponentStep "Verifying React Native installation..." "INFO"
        $postInstallVerification = Test-ReactNativeInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "React Native installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "React Native installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install React Native: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-ReactNativeFunctionality {
    <#
    .SYNOPSIS
    Test React Native functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing React Native Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "react-native --version",
        "react-native --help",
        "react-native init --help",
        "metro --version",
        "node --version"
    )
    
    $expectedOutputs = @(
        "React Native",
        "React Native",
        "React Native",
        "Metro",
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

function Update-ReactNative {
    <#
    .SYNOPSIS
    Update React Native to latest version
    #>
    Write-ComponentHeader "Updating React Native"
    
    $currentInstallation = Test-ReactNativeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "React Native is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating React Native..." "INFO"
    
    try {
        # Update React Native CLI
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            npm install -g react-native-cli@latest
            Write-ComponentStep "React Native CLI updated using npm" "SUCCESS"
        } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
            yarn global add react-native-cli@latest
            Write-ComponentStep "React Native CLI updated using yarn" "SUCCESS"
        }
        
        # Update additional tools
        $tools = @(
            "metro",
            "react-native-community-cli",
            "react-native-debugger",
            "react-native-tools"
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
        
        Write-ComponentStep "React Native update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update React Native: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-ReactNativePath {
    <#
    .SYNOPSIS
    Fix React Native PATH issues
    #>
    Write-ComponentHeader "Fixing React Native PATH"
    
    $reactNativePaths = @(
        "${env:APPDATA}\npm",
        "${env:ProgramFiles}\nodejs",
        "${env:ProgramFiles(x86)}\nodejs"
    )
    
    $foundPaths = @()
    foreach ($path in $reactNativePaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found React Native paths:" "INFO"
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
            Write-ComponentStep "Added React Native paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "React Native paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No React Native paths found" "WARNING"
    }
}

function Uninstall-ReactNative {
    <#
    .SYNOPSIS
    Uninstall React Native
    #>
    Write-ComponentHeader "Uninstalling React Native"
    
    $currentInstallation = Test-ReactNativeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "React Native is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing React Native from PATH..." "INFO"
    
    # Remove React Native paths from environment
    $currentPath = $env:Path
    $reactNativePaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $reactNativePaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Uninstall React Native CLI
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm uninstall -g react-native-cli
        Write-ComponentStep "React Native CLI uninstalled" "SUCCESS"
    } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
        yarn global remove react-native-cli
        Write-ComponentStep "React Native CLI uninstalled" "SUCCESS"
    }
    
    Write-ComponentStep "React Native removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of React Native files may be required" "WARNING"
    
    return $true
}

function Show-ReactNativeStatus {
    <#
    .SYNOPSIS
    Show comprehensive React Native status
    #>
    Write-ComponentHeader "React Native Status Report"
    
    $installation = Test-ReactNativeInstallation -Detailed:$Detailed
    $functionality = Test-ReactNativeFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Node.js Available: $(if ($installation.NodeJsAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  NPM Available: $(if ($installation.NpmAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Yarn Available: $(if ($installation.YarnAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
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

function Show-ReactNativeHelp {
    <#
    .SYNOPSIS
    Show help information for React Native component
    #>
    Write-ComponentHeader "React Native Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install React Native" -ForegroundColor White
    Write-Host "  test        - Test React Native functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall React Native" -ForegroundColor White
    Write-Host "  update      - Update React Native and tools" -ForegroundColor White
    Write-Host "  check       - Check React Native installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix React Native PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall React Native" -ForegroundColor White
    Write-Host "  status      - Show React Native status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\react-native.ps1 install                    # Install React Native" -ForegroundColor White
    Write-Host "  .\react-native.ps1 test                       # Test React Native" -ForegroundColor White
    Write-Host "  .\react-native.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\react-native.ps1 update                     # Update React Native" -ForegroundColor White
    Write-Host "  .\react-native.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\react-native.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\react-native.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - React Native version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallNodeJs         - Install Node.js" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-ReactNative -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallNodeJs:$InstallNodeJs
        if ($result) {
            Write-ComponentStep "React Native installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "React Native installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-ReactNativeFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "React Native functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "React Native functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling React Native..." "INFO"
        $result = Install-ReactNative -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallNodeJs:$InstallNodeJs
        if ($result) {
            Write-ComponentStep "React Native reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "React Native reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-ReactNative
        if ($result) {
            Write-ComponentStep "React Native update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "React Native update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-ReactNativeInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "React Native is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "React Native is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-ReactNativePath
        Write-ComponentStep "React Native PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-ReactNative
        if ($result) {
            Write-ComponentStep "React Native uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "React Native uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-ReactNativeStatus
    }
    "help" {
        Show-ReactNativeHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-ReactNativeHelp
        exit 1
    }
}
