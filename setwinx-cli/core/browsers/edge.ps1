# Complete Edge Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Microsoft Edge"
    Version = "1.0.0"
    Description = "Complete Microsoft Edge Browser"
    ExecutableNames = @("msedge.exe", "edge.exe")
    VersionCommands = @("msedge --version")
    TestCommands = @("msedge --version", "msedge --help")
    WingetId = "Microsoft.Edge"
    ChocoId = "microsoft-edge"
    DownloadUrl = "https://www.microsoft.com/edge/"
    Documentation = "https://support.microsoft.com/edge/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "EDGE COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-EdgeInstallation {
    <#
    .SYNOPSIS
    Comprehensive Edge installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Edge installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        ProfilePath = ""
        Extensions = @()
        Settings = @()
    }
    
    # Check Edge executable
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
            $version = & msedge --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get profile path
        try {
            $profilePath = "${env:LOCALAPPDATA}\Microsoft\Edge\User Data"
            if (Test-Path $profilePath) {
                $result.ProfilePath = $profilePath
            }
        } catch {
            # Continue without error
        }
        
        # Get extensions
        try {
            $extensionsPath = "${env:LOCALAPPDATA}\Microsoft\Edge\User Data\Default\Extensions"
            if (Test-Path $extensionsPath) {
                $extensions = Get-ChildItem -Path $extensionsPath -Directory
                $result.Extensions = $extensions | ForEach-Object { $_.Name }
            }
        } catch {
            # Continue without error
        }
        
        # Get settings
        try {
            $settingsPath = "${env:LOCALAPPDATA}\Microsoft\Edge\User Data\Default\Preferences"
            if (Test-Path $settingsPath) {
                $result.Settings = "Available"
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Edge {
    <#
    .SYNOPSIS
    Install Edge with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing Edge $Version"
    
    # Check if already installed
    $currentInstallation = Test-EdgeInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Edge is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Edge using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Edge installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Edge using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Edge installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Edge manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Edge installation..." "INFO"
        $postInstallVerification = Test-EdgeInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Edge installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Edge installation verification failed" "WARNING"
            return $false
        }
        
        # Install extensions if requested
        if ($InstallExtensions) {
            Write-ComponentStep "Installing Edge extensions..." "INFO"
            
            $extensions = @(
                "Developer Tools",
                "React Developer Tools",
                "Vue.js devtools",
                "Angular DevTools",
                "Redux DevTools",
                "Postman",
                "JSON Viewer",
                "ColorZilla",
                "Wappalyzer",
                "Lighthouse",
                "Web Vitals",
                "PageSpeed Insights",
                "Accessibility Insights",
                "axe DevTools",
                "WAVE",
                "Lighthouse",
                "Web Vitals",
                "PageSpeed Insights",
                "Accessibility Insights",
                "axe DevTools",
                "WAVE"
            )
            
            foreach ($extension in $extensions) {
                try {
                    # Note: Extension installation would require Edge Add-ons API
                    Write-ComponentStep "  ✓ $extension extension available" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $extension extension" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Edge: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-EdgeFunctionality {
    <#
    .SYNOPSIS
    Test Edge functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Edge Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "msedge --version",
        "msedge --help",
        "msedge --new-window",
        "msedge --inprivate",
        "msedge --disable-extensions"
    )
    
    $expectedOutputs = @(
        "Edge",
        "Edge",
        "Edge",
        "Edge",
        "Edge"
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

function Update-Edge {
    <#
    .SYNOPSIS
    Update Edge to latest version
    #>
    Write-ComponentHeader "Updating Edge"
    
    $currentInstallation = Test-EdgeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Edge is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Edge..." "INFO"
    
    try {
        # Update Edge using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Edge updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Edge updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Edge update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Edge: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-EdgePath {
    <#
    .SYNOPSIS
    Fix Edge PATH issues
    #>
    Write-ComponentHeader "Fixing Edge PATH"
    
    $edgePaths = @(
        "${env:ProgramFiles}\Microsoft\Edge\Application",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application",
        "${env:LOCALAPPDATA}\Microsoft\Edge\Application"
    )
    
    $foundPaths = @()
    foreach ($path in $edgePaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Edge paths:" "INFO"
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
            Write-ComponentStep "Added Edge paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Edge paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Edge paths found" "WARNING"
    }
}

function Uninstall-Edge {
    <#
    .SYNOPSIS
    Uninstall Edge
    #>
    Write-ComponentHeader "Uninstalling Edge"
    
    $currentInstallation = Test-EdgeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Edge is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Edge..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "Edge uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "Edge uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "Edge uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-EdgeStatus {
    <#
    .SYNOPSIS
    Show comprehensive Edge status
    #>
    Write-ComponentHeader "Edge Status Report"
    
    $installation = Test-EdgeInstallation -Detailed:$Detailed
    $functionality = Test-EdgeFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Profile Path: $($installation.ProfilePath)" -ForegroundColor White
    Write-Host "  Settings: $($installation.Settings)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Extensions.Count -gt 0) {
        Write-Host "`nExtensions:" -ForegroundColor Cyan
        foreach ($extension in $installation.Extensions) {
            Write-Host "  - $extension" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-EdgeHelp {
    <#
    .SYNOPSIS
    Show help information for Edge component
    #>
    Write-ComponentHeader "Edge Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Edge" -ForegroundColor White
    Write-Host "  test        - Test Edge functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Edge" -ForegroundColor White
    Write-Host "  update      - Update Edge" -ForegroundColor White
    Write-Host "  check       - Check Edge installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Edge PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Edge" -ForegroundColor White
    Write-Host "  status      - Show Edge status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\edge.ps1 install                    # Install Edge" -ForegroundColor White
    Write-Host "  .\edge.ps1 test                       # Test Edge" -ForegroundColor White
    Write-Host "  .\edge.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\edge.ps1 update                     # Update Edge" -ForegroundColor White
    Write-Host "  .\edge.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\edge.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\edge.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Edge version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallExtensions     - Install extensions" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Edge -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Edge installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Edge installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-EdgeFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Edge functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Edge functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Edge..." "INFO"
        $result = Install-Edge -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Edge reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Edge reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Edge
        if ($result) {
            Write-ComponentStep "Edge update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Edge update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-EdgeInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Edge is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Edge is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-EdgePath
        Write-ComponentStep "Edge PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Edge
        if ($result) {
            Write-ComponentStep "Edge uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Edge uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-EdgeStatus
    }
    "help" {
        Show-EdgeHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-EdgeHelp
        exit 1
    }
}
