# Complete Ubuntu WSL Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallPackages = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Ubuntu WSL"
    Version = "1.0.0"
    Description = "Complete Ubuntu WSL Distribution"
    ExecutableNames = @("ubuntu.exe", "ubuntu")
    VersionCommands = @("wsl -d Ubuntu -- cat /etc/os-release")
    TestCommands = @("wsl -d Ubuntu -- lsb_release -a", "wsl -d Ubuntu -- uname -a")
    WingetId = "Canonical.Ubuntu"
    ChocoId = "ubuntu"
    DownloadUrl = "https://www.microsoft.com/store/productId/9PDXGNCFSCZV"
    Documentation = "https://ubuntu.com/wsl"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "UBUNTU WSL COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-UbuntuWSLInstallation {
    <#
    .SYNOPSIS
    Comprehensive Ubuntu WSL installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Ubuntu WSL installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        DistributionName = ""
        OSVersion = ""
        KernelVersion = ""
        PackagesInstalled = @()
        UserConfigured = $false
    }
    
    # Check Ubuntu WSL executable
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
            $version = & wsl -d Ubuntu -- cat /etc/os-release 2>$null
            if ($version) {
                $result.Version = $version
                $result.DistributionName = ($version | Where-Object { $_ -match "NAME" } | ForEach-Object { ($_ -split "=")[1] }) -join ", "
                $result.OSVersion = ($version | Where-Object { $_ -match "VERSION" } | ForEach-Object { ($_ -split "=")[1] }) -join ", "
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get kernel version
        try {
            $kernelVersion = & wsl -d Ubuntu -- uname -r 2>$null
            if ($kernelVersion) {
                $result.KernelVersion = $kernelVersion
            }
        } catch {
            # Continue without error
        }
        
        # Check if user is configured
        try {
            $user = & wsl -d Ubuntu -- whoami 2>$null
            if ($user) {
                $result.UserConfigured = $true
            }
        } catch {
            # Continue without error
        }
        
        # Get installed packages
        try {
            $packages = & wsl -d Ubuntu -- dpkg -l 2>$null
            if ($packages) {
                $result.PackagesInstalled = $packages | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[1] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-UbuntuWSL {
    <#
    .SYNOPSIS
    Install Ubuntu WSL with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallPackages = $true
    )
    
    Write-ComponentHeader "Installing Ubuntu WSL $Version"
    
    # Check if already installed
    $currentInstallation = Test-UbuntuWSLInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Ubuntu WSL is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Ubuntu WSL using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Ubuntu WSL installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Ubuntu WSL using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Ubuntu WSL installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Ubuntu WSL manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Ubuntu WSL installation..." "INFO"
        $postInstallVerification = Test-UbuntuWSLInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Ubuntu WSL installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Ubuntu WSL installation verification failed" "WARNING"
            return $false
        }
        
        # Install packages if requested
        if ($InstallPackages) {
            Write-ComponentStep "Installing Ubuntu WSL packages..." "INFO"
            
            $packages = @(
                "curl",
                "wget",
                "git",
                "vim",
                "nano",
                "htop",
                "tree",
                "unzip",
                "zip",
                "build-essential",
                "python3",
                "python3-pip",
                "nodejs",
                "npm",
                "docker.io",
                "docker-compose"
            )
            
            foreach ($package in $packages) {
                try {
                    wsl -d Ubuntu -- apt update
                    wsl -d Ubuntu -- apt install -y $package
                    Write-ComponentStep "  ✓ $package installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $package" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Ubuntu WSL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-UbuntuWSLFunctionality {
    <#
    .SYNOPSIS
    Test Ubuntu WSL functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Ubuntu WSL Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "wsl -d Ubuntu -- lsb_release -a",
        "wsl -d Ubuntu -- uname -a",
        "wsl -d Ubuntu -- whoami",
        "wsl -d Ubuntu -- pwd",
        "wsl -d Ubuntu -- ls -la"
    )
    
    $expectedOutputs = @(
        "Ubuntu",
        "Linux",
        "ubuntu",
        "home",
        "total"
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

function Update-UbuntuWSL {
    <#
    .SYNOPSIS
    Update Ubuntu WSL to latest version
    #>
    Write-ComponentHeader "Updating Ubuntu WSL"
    
    $currentInstallation = Test-UbuntuWSLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Ubuntu WSL is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Ubuntu WSL..." "INFO"
    
    try {
        # Update Ubuntu WSL using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Ubuntu WSL updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Ubuntu WSL updated using Chocolatey" "SUCCESS"
        }
        
        # Update packages
        wsl -d Ubuntu -- apt update
        wsl -d Ubuntu -- apt upgrade -y
        Write-ComponentStep "Ubuntu WSL packages updated" "SUCCESS"
        
        Write-ComponentStep "Ubuntu WSL update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Ubuntu WSL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-UbuntuWSLPath {
    <#
    .SYNOPSIS
    Fix Ubuntu WSL PATH issues
    #>
    Write-ComponentHeader "Fixing Ubuntu WSL PATH"
    
    $ubuntuPaths = @(
        "${env:ProgramFiles}\Windows Subsystem for Linux",
        "${env:ProgramFiles(x86)}\Windows Subsystem for Linux",
        "${env:LOCALAPPDATA}\Microsoft\WindowsApps"
    )
    
    $foundPaths = @()
    foreach ($path in $ubuntuPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Ubuntu WSL paths:" "INFO"
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
            Write-ComponentStep "Added Ubuntu WSL paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Ubuntu WSL paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Ubuntu WSL paths found" "WARNING"
    }
}

function Uninstall-UbuntuWSL {
    <#
    .SYNOPSIS
    Uninstall Ubuntu WSL
    #>
    Write-ComponentHeader "Uninstalling Ubuntu WSL"
    
    $currentInstallation = Test-UbuntuWSLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Ubuntu WSL is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Ubuntu WSL from PATH..." "INFO"
    
    # Remove Ubuntu WSL paths from environment
    $currentPath = $env:Path
    $ubuntuPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $ubuntuPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Ubuntu WSL removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Ubuntu WSL files may be required" "WARNING"
    
    return $true
}

function Show-UbuntuWSLStatus {
    <#
    .SYNOPSIS
    Show comprehensive Ubuntu WSL status
    #>
    Write-ComponentHeader "Ubuntu WSL Status Report"
    
    $installation = Test-UbuntuWSLInstallation -Detailed:$Detailed
    $functionality = Test-UbuntuWSLFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Distribution Name: $($installation.DistributionName)" -ForegroundColor White
    Write-Host "  OS Version: $($installation.OSVersion)" -ForegroundColor White
    Write-Host "  Kernel Version: $($installation.KernelVersion)" -ForegroundColor White
    Write-Host "  User Configured: $(if ($installation.UserConfigured) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.PackagesInstalled.Count -gt 0) {
        Write-Host "`nInstalled Packages:" -ForegroundColor Cyan
        foreach ($package in $installation.PackagesInstalled) {
            Write-Host "  - $package" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-UbuntuWSLHelp {
    <#
    .SYNOPSIS
    Show help information for Ubuntu WSL component
    #>
    Write-ComponentHeader "Ubuntu WSL Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Ubuntu WSL" -ForegroundColor White
    Write-Host "  test        - Test Ubuntu WSL functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Ubuntu WSL" -ForegroundColor White
    Write-Host "  update      - Update Ubuntu WSL and packages" -ForegroundColor White
    Write-Host "  check       - Check Ubuntu WSL installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Ubuntu WSL PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Ubuntu WSL" -ForegroundColor White
    Write-Host "  status      - Show Ubuntu WSL status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\ubuntu.ps1 install                    # Install Ubuntu WSL" -ForegroundColor White
    Write-Host "  .\ubuntu.ps1 test                       # Test Ubuntu WSL" -ForegroundColor White
    Write-Host "  .\ubuntu.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\ubuntu.ps1 update                     # Update Ubuntu WSL" -ForegroundColor White
    Write-Host "  .\ubuntu.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\ubuntu.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\ubuntu.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Ubuntu WSL version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallPackages       - Install packages" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-UbuntuWSL -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallPackages:$InstallPackages
        if ($result) {
            Write-ComponentStep "Ubuntu WSL installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Ubuntu WSL installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-UbuntuWSLFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Ubuntu WSL functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Ubuntu WSL functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Ubuntu WSL..." "INFO"
        $result = Install-UbuntuWSL -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallPackages:$InstallPackages
        if ($result) {
            Write-ComponentStep "Ubuntu WSL reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Ubuntu WSL reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-UbuntuWSL
        if ($result) {
            Write-ComponentStep "Ubuntu WSL update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Ubuntu WSL update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-UbuntuWSLInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Ubuntu WSL is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Ubuntu WSL is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-UbuntuWSLPath
        Write-ComponentStep "Ubuntu WSL PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-UbuntuWSL
        if ($result) {
            Write-ComponentStep "Ubuntu WSL uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Ubuntu WSL uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-UbuntuWSLStatus
    }
    "help" {
        Show-UbuntuWSLHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-UbuntuWSLHelp
        exit 1
    }
}
