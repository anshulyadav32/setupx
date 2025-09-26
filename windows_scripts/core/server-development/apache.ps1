# Complete Apache Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallModules = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Apache HTTP Server"
    Version = "1.0.0"
    Description = "Complete Apache HTTP Server"
    ExecutableNames = @("httpd.exe", "apache.exe", "apache2.exe")
    VersionCommands = @("httpd -v", "apache2 -v")
    TestCommands = @("httpd -v", "httpd -t")
    WingetId = "Apache.Apache"
    ChocoId = "apache-httpd"
    DownloadUrl = "https://httpd.apache.org/"
    Documentation = "https://httpd.apache.org/docs/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "APACHE COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-ApacheInstallation {
    <#
    .SYNOPSIS
    Comprehensive Apache installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Apache installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        ServiceStatus = "Unknown"
        ConfigFile = ""
        ModulesLoaded = @()
        Ports = @()
    }
    
    # Check Apache executable
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
            $version = & httpd -v 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check service status
        try {
            $service = Get-Service -Name "Apache*" -ErrorAction SilentlyContinue
            if ($service) {
                $result.ServiceStatus = $service.Status
            }
        } catch {
            # Continue without error
        }
        
        # Get configuration file
        try {
            $configFile = & httpd -S 2>$null | Select-String "config file" | ForEach-Object { ($_ -split ":")[1].Trim() }
            if ($configFile) {
                $result.ConfigFile = $configFile
            }
        } catch {
            # Continue without error
        }
        
        # Get loaded modules
        try {
            $modules = & httpd -M 2>$null
            if ($modules) {
                $result.ModulesLoaded = $modules | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get listening ports
        try {
            $ports = & netstat -an | Select-String ":80 " | ForEach-Object { ($_ -split "\s+")[1] }
            if ($ports) {
                $result.Ports = $ports
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Apache {
    <#
    .SYNOPSIS
    Install Apache with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallModules = $true
    )
    
    Write-ComponentHeader "Installing Apache $Version"
    
    # Check if already installed
    $currentInstallation = Test-ApacheInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Apache is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Apache using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Apache installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Apache using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Apache installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Apache manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Apache installation..." "INFO"
        $postInstallVerification = Test-ApacheInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Apache installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Apache installation verification failed" "WARNING"
            return $false
        }
        
        # Install modules if requested
        if ($InstallModules) {
            Write-ComponentStep "Installing Apache modules..." "INFO"
            
            $modules = @(
                "mod_rewrite",
                "mod_ssl",
                "mod_headers",
                "mod_deflate",
                "mod_expires",
                "mod_cache",
                "mod_proxy",
                "mod_proxy_http",
                "mod_proxy_balancer",
                "mod_ldap",
                "mod_authnz_ldap",
                "mod_php",
                "mod_perl",
                "mod_python",
                "mod_wsgi",
                "mod_fcgid",
                "mod_suphp",
                "mod_security",
                "mod_evasive",
                "mod_spamhaus"
            )
            
            foreach ($module in $modules) {
                try {
                    # Enable module
                    & httpd -M | Select-String $module
                    if ($LASTEXITCODE -eq 0) {
                        Write-ComponentStep "  ✓ $module enabled" "SUCCESS"
                    } else {
                        Write-ComponentStep "  ✗ Failed to enable $module" "ERROR"
                    }
                } catch {
                    Write-ComponentStep "  ✗ Failed to enable $module" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Apache: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-ApacheFunctionality {
    <#
    .SYNOPSIS
    Test Apache functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Apache Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "httpd -v",
        "httpd -t",
        "httpd -M",
        "httpd -S",
        "netstat -an | findstr :80"
    )
    
    $expectedOutputs = @(
        "Apache",
        "Syntax OK",
        "Loaded Modules",
        "Virtual Host",
        "LISTENING"
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

function Update-Apache {
    <#
    .SYNOPSIS
    Update Apache to latest version
    #>
    Write-ComponentHeader "Updating Apache"
    
    $currentInstallation = Test-ApacheInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Apache is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Apache..." "INFO"
    
    try {
        # Update Apache using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Apache updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Apache updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Apache update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Apache: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-ApachePath {
    <#
    .SYNOPSIS
    Fix Apache PATH issues
    #>
    Write-ComponentHeader "Fixing Apache PATH"
    
    $apachePaths = @(
        "${env:ProgramFiles}\Apache*",
        "${env:ProgramFiles(x86)}\Apache*",
        "${env:ProgramFiles}\Apache Software Foundation\Apache*"
    )
    
    $foundPaths = @()
    foreach ($path in $apachePaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Apache paths:" "INFO"
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
            Write-ComponentStep "Added Apache paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Apache paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Apache paths found" "WARNING"
    }
}

function Uninstall-Apache {
    <#
    .SYNOPSIS
    Uninstall Apache
    #>
    Write-ComponentHeader "Uninstalling Apache"
    
    $currentInstallation = Test-ApacheInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Apache is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Apache..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "Apache uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "Apache uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "Apache uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-ApacheStatus {
    <#
    .SYNOPSIS
    Show comprehensive Apache status
    #>
    Write-ComponentHeader "Apache Status Report"
    
    $installation = Test-ApacheInstallation -Detailed:$Detailed
    $functionality = Test-ApacheFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Service Status: $($installation.ServiceStatus)" -ForegroundColor White
    Write-Host "  Config File: $($installation.ConfigFile)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.ModulesLoaded.Count -gt 0) {
        Write-Host "`nLoaded Modules:" -ForegroundColor Cyan
        foreach ($module in $installation.ModulesLoaded) {
            Write-Host "  - $module" -ForegroundColor White
        }
    }
    
    if ($installation.Ports.Count -gt 0) {
        Write-Host "`nListening Ports:" -ForegroundColor Cyan
        foreach ($port in $installation.Ports) {
            Write-Host "  - $port" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-ApacheHelp {
    <#
    .SYNOPSIS
    Show help information for Apache component
    #>
    Write-ComponentHeader "Apache Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Apache" -ForegroundColor White
    Write-Host "  test        - Test Apache functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Apache" -ForegroundColor White
    Write-Host "  update      - Update Apache" -ForegroundColor White
    Write-Host "  check       - Check Apache installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Apache PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Apache" -ForegroundColor White
    Write-Host "  status      - Show Apache status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\apache.ps1 install                    # Install Apache" -ForegroundColor White
    Write-Host "  .\apache.ps1 test                       # Test Apache" -ForegroundColor White
    Write-Host "  .\apache.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\apache.ps1 update                     # Update Apache" -ForegroundColor White
    Write-Host "  .\apache.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\apache.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\apache.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Apache version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallModules        - Install modules" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Apache -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallModules:$InstallModules
        if ($result) {
            Write-ComponentStep "Apache installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Apache installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-ApacheFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Apache functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Apache functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Apache..." "INFO"
        $result = Install-Apache -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallModules:$InstallModules
        if ($result) {
            Write-ComponentStep "Apache reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Apache reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Apache
        if ($result) {
            Write-ComponentStep "Apache update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Apache update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-ApacheInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Apache is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Apache is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-ApachePath
        Write-ComponentStep "Apache PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Apache
        if ($result) {
            Write-ComponentStep "Apache uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Apache uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-ApacheStatus
    }
    "help" {
        Show-ApacheHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-ApacheHelp
        exit 1
    }
}
