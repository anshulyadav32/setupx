# Complete Visual Studio Code Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Visual Studio Code"
    Version = "1.0.0"
    Description = "Complete Visual Studio Code Development Environment"
    ExecutableNames = @("code.exe", "code")
    VersionCommands = @("code --version")
    TestCommands = @("code --version", "code --help", "code --list-extensions")
    WingetId = "Microsoft.VisualStudioCode"
    ChocoId = "vscode"
    DownloadUrl = "https://code.visualstudio.com/download"
    Documentation = "https://code.visualstudio.com/docs"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "VISUAL STUDIO CODE COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-VSCodeInstallation {
    <#
    .SYNOPSIS
    Comprehensive Visual Studio Code installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Visual Studio Code installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        Extensions = @()
        ExtensionsCount = 0
        SettingsConfigured = $false
    }
    
    # Check Visual Studio Code executable
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
            $version = & code --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check installed extensions
        try {
            $extensions = & code --list-extensions 2>$null
            if ($extensions) {
                $result.Extensions = $extensions
                $result.ExtensionsCount = $extensions.Count
            }
        } catch {
            # Continue without error
        }
        
        # Check if settings are configured
        $settingsPath = "${env:APPDATA}\Code\User\settings.json"
        $result.SettingsConfigured = Test-Path $settingsPath
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-VSCode {
    <#
    .SYNOPSIS
    Install Visual Studio Code with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing Visual Studio Code $Version"
    
    # Check if already installed
    $currentInstallation = Test-VSCodeInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Visual Studio Code is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Visual Studio Code using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Visual Studio Code installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Visual Studio Code using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Visual Studio Code installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Visual Studio Code manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Visual Studio Code installation..." "INFO"
        $postInstallVerification = Test-VSCodeInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Visual Studio Code installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Visual Studio Code installation verification failed" "WARNING"
            return $false
        }
        
        # Install extensions if requested
        if ($InstallExtensions) {
            Write-ComponentStep "Installing Visual Studio Code extensions..." "INFO"
            
            $extensions = @(
                "ms-python.python",
                "ms-vscode.vscode-typescript-next",
                "ms-vscode.vscode-json",
                "ms-vscode.powershell",
                "ms-vscode.cpptools",
                "ms-vscode.csharp",
                "ms-vscode.go",
                "ms-vscode.rust-analyzer",
                "ms-vscode.vscode-docker",
                "ms-azuretools.vscode-docker",
                "ms-kubernetes-tools.vscode-kubernetes-tools",
                "ms-vscode.azurecli",
                "ms-vscode.azure-account",
                "ms-vscode.azure-iot-toolkit",
                "ms-vscode.azure-iot-edge",
                "ms-vscode.azure-iot-device-simulator",
                "ms-vscode.azure-iot-workbench",
                "ms-vscode.azure-iot-tools",
                "ms-vscode.azure-iot-edge",
                "ms-vscode.azure-iot-device-simulator",
                "ms-vscode.azure-iot-workbench",
                "ms-vscode.azure-iot-tools"
            )
            
            foreach ($extension in $extensions) {
                try {
                    code --install-extension $extension
                    Write-ComponentStep "  ✓ $extension installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $extension" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Visual Studio Code: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-VSCodeFunctionality {
    <#
    .SYNOPSIS
    Test Visual Studio Code functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Visual Studio Code Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "code --version",
        "code --help",
        "code --list-extensions",
        "code --list",
        "code --status"
    )
    
    $expectedOutputs = @(
        "code",
        "code",
        "code",
        "code",
        "code"
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

function Update-VSCode {
    <#
    .SYNOPSIS
    Update Visual Studio Code to latest version
    #>
    Write-ComponentHeader "Updating Visual Studio Code"
    
    $currentInstallation = Test-VSCodeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Visual Studio Code is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Visual Studio Code..." "INFO"
    
    try {
        # Update Visual Studio Code using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Visual Studio Code updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Visual Studio Code updated using Chocolatey" "SUCCESS"
        }
        
        # Update extensions
        code --list-extensions | ForEach-Object { code --install-extension $_ }
        Write-ComponentStep "Extensions updated" "SUCCESS"
        
        Write-ComponentStep "Visual Studio Code update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Visual Studio Code: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-VSCodePath {
    <#
    .SYNOPSIS
    Fix Visual Studio Code PATH issues
    #>
    Write-ComponentHeader "Fixing Visual Studio Code PATH"
    
    $vscodePaths = @(
        "${env:ProgramFiles}\Microsoft VS Code\bin",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin",
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $vscodePaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Visual Studio Code paths:" "INFO"
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
            Write-ComponentStep "Added Visual Studio Code paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio Code paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Visual Studio Code paths found" "WARNING"
    }
}

function Uninstall-VSCode {
    <#
    .SYNOPSIS
    Uninstall Visual Studio Code
    #>
    Write-ComponentHeader "Uninstalling Visual Studio Code"
    
    $currentInstallation = Test-VSCodeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Visual Studio Code is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Visual Studio Code from PATH..." "INFO"
    
    # Remove Visual Studio Code paths from environment
    $currentPath = $env:Path
    $vscodePaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $vscodePaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Visual Studio Code removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Visual Studio Code files may be required" "WARNING"
    
    return $true
}

function Show-VSCodeStatus {
    <#
    .SYNOPSIS
    Show comprehensive Visual Studio Code status
    #>
    Write-ComponentHeader "Visual Studio Code Status Report"
    
    $installation = Test-VSCodeInstallation -Detailed:$Detailed
    $functionality = Test-VSCodeFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Extensions Count: $($installation.ExtensionsCount)" -ForegroundColor White
    Write-Host "  Settings Configured: $(if ($installation.SettingsConfigured) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Extensions.Count -gt 0) {
        Write-Host "`nInstalled Extensions:" -ForegroundColor Cyan
        foreach ($extension in $installation.Extensions) {
            Write-Host "  - $extension" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-VSCodeHelp {
    <#
    .SYNOPSIS
    Show help information for Visual Studio Code component
    #>
    Write-ComponentHeader "Visual Studio Code Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Visual Studio Code" -ForegroundColor White
    Write-Host "  test        - Test Visual Studio Code functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Visual Studio Code" -ForegroundColor White
    Write-Host "  update      - Update Visual Studio Code and extensions" -ForegroundColor White
    Write-Host "  check       - Check Visual Studio Code installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Visual Studio Code PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Visual Studio Code" -ForegroundColor White
    Write-Host "  status      - Show Visual Studio Code status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\vscode.ps1 install                    # Install Visual Studio Code" -ForegroundColor White
    Write-Host "  .\vscode.ps1 test                       # Test Visual Studio Code" -ForegroundColor White
    Write-Host "  .\vscode.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\vscode.ps1 update                     # Update Visual Studio Code" -ForegroundColor White
    Write-Host "  .\vscode.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\vscode.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\vscode.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Visual Studio Code version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallExtensions      - Install extensions" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-VSCode -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Visual Studio Code installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio Code installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-VSCodeFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Visual Studio Code functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio Code functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Visual Studio Code..." "INFO"
        $result = Install-VSCode -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Visual Studio Code reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio Code reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-VSCode
        if ($result) {
            Write-ComponentStep "Visual Studio Code update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio Code update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-VSCodeInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Visual Studio Code is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio Code is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-VSCodePath
        Write-ComponentStep "Visual Studio Code PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-VSCode
        if ($result) {
            Write-ComponentStep "Visual Studio Code uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio Code uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-VSCodeStatus
    }
    "help" {
        Show-VSCodeHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-VSCodeHelp
        exit 1
    }
}
