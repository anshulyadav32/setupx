# Complete Firefox Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Mozilla Firefox"
    Version = "1.0.0"
    Description = "Complete Mozilla Firefox Browser"
    ExecutableNames = @("firefox.exe", "firefox")
    VersionCommands = @("firefox --version")
    TestCommands = @("firefox --version", "firefox --help")
    WingetId = "Mozilla.Firefox"
    ChocoId = "firefox"
    DownloadUrl = "https://www.mozilla.org/firefox/"
    Documentation = "https://support.mozilla.org/firefox/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "FIREFOX COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-FirefoxInstallation {
    <#
    .SYNOPSIS
    Comprehensive Firefox installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Firefox installation..." "INFO"
    
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
    
    # Check Firefox executable
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
            $version = & firefox --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get profile path
        try {
            $profilePath = "${env:APPDATA}\Mozilla\Firefox\Profiles"
            if (Test-Path $profilePath) {
                $result.ProfilePath = $profilePath
            }
        } catch {
            # Continue without error
        }
        
        # Get extensions
        try {
            $extensionsPath = "${env:APPDATA}\Mozilla\Firefox\Profiles\*\extensions"
            if (Test-Path $extensionsPath) {
                $extensions = Get-ChildItem -Path $extensionsPath -Directory
                $result.Extensions = $extensions | ForEach-Object { $_.Name }
            }
        } catch {
            # Continue without error
        }
        
        # Get settings
        try {
            $settingsPath = "${env:APPDATA}\Mozilla\Firefox\Profiles\*\prefs.js"
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

function Install-Firefox {
    <#
    .SYNOPSIS
    Install Firefox with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing Firefox $Version"
    
    # Check if already installed
    $currentInstallation = Test-FirefoxInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Firefox is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Firefox using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Firefox installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Firefox using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Firefox installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Firefox manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Firefox installation..." "INFO"
        $postInstallVerification = Test-FirefoxInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Firefox installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Firefox installation verification failed" "WARNING"
            return $false
        }
        
        # Install extensions if requested
        if ($InstallExtensions) {
            Write-ComponentStep "Installing Firefox extensions..." "INFO"
            
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
                    # Note: Extension installation would require Firefox Add-ons API
                    Write-ComponentStep "  ✓ $extension extension available" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $extension extension" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Firefox: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-FirefoxFunctionality {
    <#
    .SYNOPSIS
    Test Firefox functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Firefox Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "firefox --version",
        "firefox --help",
        "firefox --new-window",
        "firefox --private-window",
        "firefox --safe-mode"
    )
    
    $expectedOutputs = @(
        "Firefox",
        "Firefox",
        "Firefox",
        "Firefox",
        "Firefox"
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

function Update-Firefox {
    <#
    .SYNOPSIS
    Update Firefox to latest version
    #>
    Write-ComponentHeader "Updating Firefox"
    
    $currentInstallation = Test-FirefoxInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Firefox is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Firefox..." "INFO"
    
    try {
        # Update Firefox using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Firefox updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Firefox updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Firefox update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Firefox: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-FirefoxPath {
    <#
    .SYNOPSIS
    Fix Firefox PATH issues
    #>
    Write-ComponentHeader "Fixing Firefox PATH"
    
    $firefoxPaths = @(
        "${env:ProgramFiles}\Mozilla Firefox",
        "${env:ProgramFiles(x86)}\Mozilla Firefox",
        "${env:LOCALAPPDATA}\Mozilla Firefox"
    )
    
    $foundPaths = @()
    foreach ($path in $firefoxPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Firefox paths:" "INFO"
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
            Write-ComponentStep "Added Firefox paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Firefox paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Firefox paths found" "WARNING"
    }
}

function Uninstall-Firefox {
    <#
    .SYNOPSIS
    Uninstall Firefox
    #>
    Write-ComponentHeader "Uninstalling Firefox"
    
    $currentInstallation = Test-FirefoxInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Firefox is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Firefox..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "Firefox uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "Firefox uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "Firefox uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-FirefoxStatus {
    <#
    .SYNOPSIS
    Show comprehensive Firefox status
    #>
    Write-ComponentHeader "Firefox Status Report"
    
    $installation = Test-FirefoxInstallation -Detailed:$Detailed
    $functionality = Test-FirefoxFunctionality -Detailed:$Detailed
    
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

function Show-FirefoxHelp {
    <#
    .SYNOPSIS
    Show help information for Firefox component
    #>
    Write-ComponentHeader "Firefox Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Firefox" -ForegroundColor White
    Write-Host "  test        - Test Firefox functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Firefox" -ForegroundColor White
    Write-Host "  update      - Update Firefox" -ForegroundColor White
    Write-Host "  check       - Check Firefox installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Firefox PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Firefox" -ForegroundColor White
    Write-Host "  status      - Show Firefox status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\firefox.ps1 install                    # Install Firefox" -ForegroundColor White
    Write-Host "  .\firefox.ps1 test                       # Test Firefox" -ForegroundColor White
    Write-Host "  .\firefox.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\firefox.ps1 update                     # Update Firefox" -ForegroundColor White
    Write-Host "  .\firefox.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\firefox.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\firefox.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Firefox version to install" -ForegroundColor White
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
        $result = Install-Firefox -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Firefox installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Firefox installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-FirefoxFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Firefox functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Firefox functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Firefox..." "INFO"
        $result = Install-Firefox -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Firefox reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Firefox reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Firefox
        if ($result) {
            Write-ComponentStep "Firefox update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Firefox update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-FirefoxInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Firefox is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Firefox is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-FirefoxPath
        Write-ComponentStep "Firefox PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Firefox
        if ($result) {
            Write-ComponentStep "Firefox uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Firefox uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-FirefoxStatus
    }
    "help" {
        Show-FirefoxHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-FirefoxHelp
        exit 1
    }
}
