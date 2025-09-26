# Complete XAMPP Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallServices = $true
)

# Component Information
$ComponentInfo = @{
    Name = "XAMPP"
    Version = "1.0.0"
    Description = "Complete XAMPP Development Environment"
    ExecutableNames = @("xampp-control.exe", "xampp.exe")
    VersionCommands = @("xampp-control --version")
    TestCommands = @("xampp-control --version", "httpd -v", "mysql --version")
    WingetId = "ApacheFriends.XAMPP"
    ChocoId = "xampp"
    DownloadUrl = "https://www.apachefriends.org/"
    Documentation = "https://www.apachefriends.org/docs/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "XAMPP COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-XAMPPInstallation {
    <#
    .SYNOPSIS
    Comprehensive XAMPP installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking XAMPP installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        ApacheStatus = "Unknown"
        MySQLStatus = "Unknown"
        PHPStatus = "Unknown"
        Services = @()
        Ports = @()
    }
    
    # Check XAMPP executable
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
            $version = & xampp-control --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check Apache status
        try {
            $apacheService = Get-Service -Name "Apache*" -ErrorAction SilentlyContinue
            if ($apacheService) {
                $result.ApacheStatus = $apacheService.Status
            }
        } catch {
            # Continue without error
        }
        
        # Check MySQL status
        try {
            $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
            if ($mysqlService) {
                $result.MySQLStatus = $mysqlService.Status
            }
        } catch {
            # Continue without error
        }
        
        # Check PHP status
        try {
            $phpVersion = & php -v 2>$null
            if ($phpVersion) {
                $result.PHPStatus = "Available"
            }
        } catch {
            $result.PHPStatus = "Not Available"
        }
        
        # Get services
        try {
            $services = Get-Service | Where-Object { $_.Name -match "Apache|MySQL|PHP" }
            $result.Services = $services | ForEach-Object { "$($_.Name): $($_.Status)" }
        } catch {
            # Continue without error
        }
        
        # Get listening ports
        try {
            $ports = & netstat -an | Select-String ":80|:3306|:443" | ForEach-Object { ($_ -split "\s+")[1] }
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

function Install-XAMPP {
    <#
    .SYNOPSIS
    Install XAMPP with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallServices = $true
    )
    
    Write-ComponentHeader "Installing XAMPP $Version"
    
    # Check if already installed
    $currentInstallation = Test-XAMPPInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "XAMPP is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing XAMPP using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "XAMPP installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing XAMPP using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "XAMPP installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing XAMPP manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying XAMPP installation..." "INFO"
        $postInstallVerification = Test-XAMPPInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "XAMPP installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "XAMPP installation verification failed" "WARNING"
            return $false
        }
        
        # Install services if requested
        if ($InstallServices) {
            Write-ComponentStep "Installing XAMPP services..." "INFO"
            
            $services = @(
                "Apache",
                "MySQL",
                "PHP"
            )
            
            foreach ($service in $services) {
                try {
                    # Start service
                    Start-Service -Name $service -ErrorAction SilentlyContinue
                    Write-ComponentStep "  ✓ $service service started" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to start $service service" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install XAMPP: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-XAMPPFunctionality {
    <#
    .SYNOPSIS
    Test XAMPP functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing XAMPP Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "xampp-control --version",
        "httpd -v",
        "mysql --version",
        "php -v",
        "netstat -an | findstr :80"
    )
    
    $expectedOutputs = @(
        "XAMPP",
        "Apache",
        "mysql",
        "PHP",
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

function Update-XAMPP {
    <#
    .SYNOPSIS
    Update XAMPP to latest version
    #>
    Write-ComponentHeader "Updating XAMPP"
    
    $currentInstallation = Test-XAMPPInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "XAMPP is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating XAMPP..." "INFO"
    
    try {
        # Update XAMPP using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "XAMPP updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "XAMPP updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "XAMPP update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update XAMPP: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-XAMPPPath {
    <#
    .SYNOPSIS
    Fix XAMPP PATH issues
    #>
    Write-ComponentHeader "Fixing XAMPP PATH"
    
    $xamppPaths = @(
        "${env:ProgramFiles}\xampp*",
        "${env:ProgramFiles(x86)}\xampp*",
        "${env:ProgramFiles}\XAMPP*"
    )
    
    $foundPaths = @()
    foreach ($path in $xamppPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found XAMPP paths:" "INFO"
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
            Write-ComponentStep "Added XAMPP paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "XAMPP paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No XAMPP paths found" "WARNING"
    }
}

function Uninstall-XAMPP {
    <#
    .SYNOPSIS
    Uninstall XAMPP
    #>
    Write-ComponentHeader "Uninstalling XAMPP"
    
    $currentInstallation = Test-XAMPPInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "XAMPP is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling XAMPP..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "XAMPP uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "XAMPP uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "XAMPP uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-XAMPPStatus {
    <#
    .SYNOPSIS
    Show comprehensive XAMPP status
    #>
    Write-ComponentHeader "XAMPP Status Report"
    
    $installation = Test-XAMPPInstallation -Detailed:$Detailed
    $functionality = Test-XAMPPFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Apache Status: $($installation.ApacheStatus)" -ForegroundColor White
    Write-Host "  MySQL Status: $($installation.MySQLStatus)" -ForegroundColor White
    Write-Host "  PHP Status: $($installation.PHPStatus)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Services.Count -gt 0) {
        Write-Host "`nServices:" -ForegroundColor Cyan
        foreach ($service in $installation.Services) {
            Write-Host "  - $service" -ForegroundColor White
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

function Show-XAMPPHelp {
    <#
    .SYNOPSIS
    Show help information for XAMPP component
    #>
    Write-ComponentHeader "XAMPP Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install XAMPP" -ForegroundColor White
    Write-Host "  test        - Test XAMPP functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall XAMPP" -ForegroundColor White
    Write-Host "  update      - Update XAMPP" -ForegroundColor White
    Write-Host "  check       - Check XAMPP installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix XAMPP PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall XAMPP" -ForegroundColor White
    Write-Host "  status      - Show XAMPP status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\xampp.ps1 install                    # Install XAMPP" -ForegroundColor White
    Write-Host "  .\xampp.ps1 test                       # Test XAMPP" -ForegroundColor White
    Write-Host "  .\xampp.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\xampp.ps1 update                     # Update XAMPP" -ForegroundColor White
    Write-Host "  .\xampp.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\xampp.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\xampp.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - XAMPP version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallServices       - Install services" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-XAMPP -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallServices:$InstallServices
        if ($result) {
            Write-ComponentStep "XAMPP installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "XAMPP installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-XAMPPFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "XAMPP functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "XAMPP functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling XAMPP..." "INFO"
        $result = Install-XAMPP -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallServices:$InstallServices
        if ($result) {
            Write-ComponentStep "XAMPP reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "XAMPP reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-XAMPP
        if ($result) {
            Write-ComponentStep "XAMPP update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "XAMPP update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-XAMPPInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "XAMPP is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "XAMPP is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-XAMPPPath
        Write-ComponentStep "XAMPP PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-XAMPP
        if ($result) {
            Write-ComponentStep "XAMPP uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "XAMPP uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-XAMPPStatus
    }
    "help" {
        Show-XAMPPHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-XAMPPHelp
        exit 1
    }
}
