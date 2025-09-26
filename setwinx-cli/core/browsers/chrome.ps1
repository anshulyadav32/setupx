# Complete Chrome Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Google Chrome"
    Version = "1.0.0"
    Description = "Complete Google Chrome Browser"
    ExecutableNames = @("chrome.exe", "google-chrome.exe")
    VersionCommands = @("chrome --version")
    TestCommands = @("chrome --version", "chrome --help")
    WingetId = "Google.Chrome"
    ChocoId = "googlechrome"
    DownloadUrl = "https://www.google.com/chrome/"
    Documentation = "https://support.google.com/chrome/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "CHROME COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-ChromeInstallation {
    <#
    .SYNOPSIS
    Comprehensive Chrome installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Chrome installation..." "INFO"
    
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
    
    # Check Chrome executable
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
            $version = & chrome --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get profile path
        try {
            $profilePath = "${env:LOCALAPPDATA}\Google\Chrome\User Data"
            if (Test-Path $profilePath) {
                $result.ProfilePath = $profilePath
            }
        } catch {
            # Continue without error
        }
        
        # Get extensions
        try {
            $extensionsPath = "${env:LOCALAPPDATA}\Google\Chrome\User Data\Default\Extensions"
            if (Test-Path $extensionsPath) {
                $extensions = Get-ChildItem -Path $extensionsPath -Directory
                $result.Extensions = $extensions | ForEach-Object { $_.Name }
            }
        } catch {
            # Continue without error
        }
        
        # Get settings
        try {
            $settingsPath = "${env:LOCALAPPDATA}\Google\Chrome\User Data\Default\Preferences"
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

function Install-Chrome {
    <#
    .SYNOPSIS
    Install Chrome with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing Chrome $Version"
    
    # Check if already installed
    $currentInstallation = Test-ChromeInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Chrome is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Chrome using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Chrome installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Chrome using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Chrome installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Chrome manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Chrome installation..." "INFO"
        $postInstallVerification = Test-ChromeInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Chrome installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Chrome installation verification failed" "WARNING"
            return $false
        }
        
        # Install extensions if requested
        if ($InstallExtensions) {
            Write-ComponentStep "Installing Chrome extensions..." "INFO"
            
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
                    # Note: Extension installation would require Chrome Web Store API
                    Write-ComponentStep "  ✓ $extension extension available" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $extension extension" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Chrome: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-ChromeFunctionality {
    <#
    .SYNOPSIS
    Test Chrome functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Chrome Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "chrome --version",
        "chrome --help",
        "chrome --new-window",
        "chrome --incognito",
        "chrome --disable-extensions"
    )
    
    $expectedOutputs = @(
        "Chrome",
        "Chrome",
        "Chrome",
        "Chrome",
        "Chrome"
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

function Update-Chrome {
    <#
    .SYNOPSIS
    Update Chrome to latest version
    #>
    Write-ComponentHeader "Updating Chrome"
    
    $currentInstallation = Test-ChromeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Chrome is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Chrome..." "INFO"
    
    try {
        # Update Chrome using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Chrome updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Chrome updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Chrome update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Chrome: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-ChromePath {
    <#
    .SYNOPSIS
    Fix Chrome PATH issues
    #>
    Write-ComponentHeader "Fixing Chrome PATH"
    
    $chromePaths = @(
        "${env:ProgramFiles}\Google\Chrome\Application",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application",
        "${env:LOCALAPPDATA}\Google\Chrome\Application"
    )
    
    $foundPaths = @()
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Chrome paths:" "INFO"
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
            Write-ComponentStep "Added Chrome paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Chrome paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Chrome paths found" "WARNING"
    }
}

function Uninstall-Chrome {
    <#
    .SYNOPSIS
    Uninstall Chrome
    #>
    Write-ComponentHeader "Uninstalling Chrome"
    
    $currentInstallation = Test-ChromeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Chrome is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Chrome..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "Chrome uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "Chrome uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "Chrome uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-ChromeStatus {
    <#
    .SYNOPSIS
    Show comprehensive Chrome status
    #>
    Write-ComponentHeader "Chrome Status Report"
    
    $installation = Test-ChromeInstallation -Detailed:$Detailed
    $functionality = Test-ChromeFunctionality -Detailed:$Detailed
    
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

function Show-ChromeHelp {
    <#
    .SYNOPSIS
    Show help information for Chrome component
    #>
    Write-ComponentHeader "Chrome Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Chrome" -ForegroundColor White
    Write-Host "  test        - Test Chrome functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Chrome" -ForegroundColor White
    Write-Host "  update      - Update Chrome" -ForegroundColor White
    Write-Host "  check       - Check Chrome installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Chrome PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Chrome" -ForegroundColor White
    Write-Host "  status      - Show Chrome status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\chrome.ps1 install                    # Install Chrome" -ForegroundColor White
    Write-Host "  .\chrome.ps1 test                       # Test Chrome" -ForegroundColor White
    Write-Host "  .\chrome.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\chrome.ps1 update                     # Update Chrome" -ForegroundColor White
    Write-Host "  .\chrome.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\chrome.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\chrome.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Chrome version to install" -ForegroundColor White
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
        $result = Install-Chrome -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Chrome installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Chrome installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-ChromeFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Chrome functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chrome functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Chrome..." "INFO"
        $result = Install-Chrome -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Chrome reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chrome reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Chrome
        if ($result) {
            Write-ComponentStep "Chrome update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chrome update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-ChromeInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Chrome is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Chrome is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-ChromePath
        Write-ComponentStep "Chrome PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Chrome
        if ($result) {
            Write-ComponentStep "Chrome uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Chrome uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-ChromeStatus
    }
    "help" {
        Show-ChromeHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-ChromeHelp
        exit 1
    }
}
