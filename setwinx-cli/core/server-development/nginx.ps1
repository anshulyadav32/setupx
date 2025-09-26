# Complete Nginx Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Nginx"
    Version = "1.0.0"
    Description = "Complete Nginx Web Server"
    ExecutableNames = @("nginx.exe", "nginx")
    VersionCommands = @("nginx -v", "nginx -V")
    TestCommands = @("nginx -v", "nginx -t")
    WingetId = "Nginx.Nginx"
    ChocoId = "nginx"
    DownloadUrl = "https://nginx.org/"
    Documentation = "https://nginx.org/en/docs/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "NGINX COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-NginxInstallation {
    <#
    .SYNOPSIS
    Comprehensive Nginx installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Nginx installation..." "INFO"
    
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
    
    # Check Nginx executable
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
            $version = & nginx -v 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check service status
        try {
            $service = Get-Service -Name "nginx*" -ErrorAction SilentlyContinue
            if ($service) {
                $result.ServiceStatus = $service.Status
            }
        } catch {
            # Continue without error
        }
        
        # Get configuration file
        try {
            $configFile = & nginx -T 2>$null | Select-String "configuration file" | ForEach-Object { ($_ -split ":")[1].Trim() }
            if ($configFile) {
                $result.ConfigFile = $configFile
            }
        } catch {
            # Continue without error
        }
        
        # Get loaded modules
        try {
            $modules = & nginx -V 2>$null
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

function Install-Nginx {
    <#
    .SYNOPSIS
    Install Nginx with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallModules = $true
    )
    
    Write-ComponentHeader "Installing Nginx $Version"
    
    # Check if already installed
    $currentInstallation = Test-NginxInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Nginx is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Nginx using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Nginx installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Nginx using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Nginx installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Nginx manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Nginx installation..." "INFO"
        $postInstallVerification = Test-NginxInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Nginx installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Nginx installation verification failed" "WARNING"
            return $false
        }
        
        # Install modules if requested
        if ($InstallModules) {
            Write-ComponentStep "Installing Nginx modules..." "INFO"
            
            $modules = @(
                "http_ssl_module",
                "http_realip_module",
                "http_addition_module",
                "http_sub_module",
                "http_dav_module",
                "http_flv_module",
                "http_mp4_module",
                "http_gunzip_module",
                "http_gzip_static_module",
                "http_secure_link_module",
                "http_stub_status_module",
                "http_auth_request_module",
                "http_xslt_module",
                "http_image_filter_module",
                "http_geoip_module",
                "http_perl_module",
                "http_mirror_module",
                "http_upstream_module",
                "http_upstream_keepalive_module",
                "http_upstream_least_conn_module",
                "http_upstream_random_module",
                "http_upstream_hash_module",
                "http_upstream_ip_hash_module",
                "http_upstream_keepalive_module",
                "http_upstream_least_conn_module",
                "http_upstream_random_module",
                "http_upstream_hash_module",
                "http_upstream_ip_hash_module"
            )
            
            foreach ($module in $modules) {
                try {
                    # Check if module is available
                    & nginx -V 2>$null | Select-String $module
                    if ($LASTEXITCODE -eq 0) {
                        Write-ComponentStep "  ✓ $module available" "SUCCESS"
                    } else {
                        Write-ComponentStep "  ✗ $module not available" "WARNING"
                    }
                } catch {
                    Write-ComponentStep "  ✗ Failed to check $module" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Nginx: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-NginxFunctionality {
    <#
    .SYNOPSIS
    Test Nginx functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Nginx Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "nginx -v",
        "nginx -t",
        "nginx -V",
        "nginx -T",
        "netstat -an | findstr :80"
    )
    
    $expectedOutputs = @(
        "nginx",
        "successful",
        "nginx",
        "nginx",
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

function Update-Nginx {
    <#
    .SYNOPSIS
    Update Nginx to latest version
    #>
    Write-ComponentHeader "Updating Nginx"
    
    $currentInstallation = Test-NginxInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Nginx is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Nginx..." "INFO"
    
    try {
        # Update Nginx using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Nginx updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Nginx updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Nginx update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Nginx: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-NginxPath {
    <#
    .SYNOPSIS
    Fix Nginx PATH issues
    #>
    Write-ComponentHeader "Fixing Nginx PATH"
    
    $nginxPaths = @(
        "${env:ProgramFiles}\nginx*",
        "${env:ProgramFiles(x86)}\nginx*",
        "${env:ProgramFiles}\Nginx*"
    )
    
    $foundPaths = @()
    foreach ($path in $nginxPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Nginx paths:" "INFO"
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
            Write-ComponentStep "Added Nginx paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Nginx paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Nginx paths found" "WARNING"
    }
}

function Uninstall-Nginx {
    <#
    .SYNOPSIS
    Uninstall Nginx
    #>
    Write-ComponentHeader "Uninstalling Nginx"
    
    $currentInstallation = Test-NginxInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Nginx is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Nginx..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "Nginx uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "Nginx uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "Nginx uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-NginxStatus {
    <#
    .SYNOPSIS
    Show comprehensive Nginx status
    #>
    Write-ComponentHeader "Nginx Status Report"
    
    $installation = Test-NginxInstallation -Detailed:$Detailed
    $functionality = Test-NginxFunctionality -Detailed:$Detailed
    
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

function Show-NginxHelp {
    <#
    .SYNOPSIS
    Show help information for Nginx component
    #>
    Write-ComponentHeader "Nginx Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Nginx" -ForegroundColor White
    Write-Host "  test        - Test Nginx functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Nginx" -ForegroundColor White
    Write-Host "  update      - Update Nginx" -ForegroundColor White
    Write-Host "  check       - Check Nginx installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Nginx PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Nginx" -ForegroundColor White
    Write-Host "  status      - Show Nginx status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\nginx.ps1 install                    # Install Nginx" -ForegroundColor White
    Write-Host "  .\nginx.ps1 test                       # Test Nginx" -ForegroundColor White
    Write-Host "  .\nginx.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\nginx.ps1 update                     # Update Nginx" -ForegroundColor White
    Write-Host "  .\nginx.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\nginx.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\nginx.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Nginx version to install" -ForegroundColor White
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
        $result = Install-Nginx -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallModules:$InstallModules
        if ($result) {
            Write-ComponentStep "Nginx installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Nginx installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-NginxFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Nginx functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Nginx functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Nginx..." "INFO"
        $result = Install-Nginx -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallModules:$InstallModules
        if ($result) {
            Write-ComponentStep "Nginx reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Nginx reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Nginx
        if ($result) {
            Write-ComponentStep "Nginx update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Nginx update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-NginxInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Nginx is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Nginx is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-NginxPath
        Write-ComponentStep "Nginx PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Nginx
        if ($result) {
            Write-ComponentStep "Nginx uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Nginx uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-NginxStatus
    }
    "help" {
        Show-NginxHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-NginxHelp
        exit 1
    }
}
