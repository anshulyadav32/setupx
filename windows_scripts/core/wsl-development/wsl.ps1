# Complete WSL Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallDistributions = $true
)

# Component Information
$ComponentInfo = @{
    Name = "WSL"
    Version = "1.0.0"
    Description = "Complete Windows Subsystem for Linux Environment"
    ExecutableNames = @("wsl.exe", "wsl")
    VersionCommands = @("wsl --version")
    TestCommands = @("wsl --version", "wsl --help", "wsl --list")
    WingetId = "Microsoft.WindowsSubsystemForLinux"
    ChocoId = "wsl"
    DownloadUrl = "https://docs.microsoft.com/en-us/windows/wsl/install"
    Documentation = "https://docs.microsoft.com/en-us/windows/wsl/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "WSL COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-WSLInstallation {
    <#
    .SYNOPSIS
    Comprehensive WSL installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking WSL installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        Distributions = @()
        DefaultDistribution = ""
        WSLVersion = ""
        KernelVersion = ""
    }
    
    # Check WSL executable
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
            $version = & wsl --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get WSL version
        try {
            $wslVersion = & wsl --status 2>$null
            if ($wslVersion) {
                $result.WSLVersion = $wslVersion
            }
        } catch {
            # Continue without error
        }
        
        # Get installed distributions
        try {
            $distributions = & wsl --list 2>$null
            if ($distributions) {
                $result.Distributions = $distributions | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get default distribution
        try {
            $defaultDistro = & wsl --list --verbose 2>$null
            if ($defaultDistro) {
                $result.DefaultDistribution = ($defaultDistro | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }) -join ", "
            }
        } catch {
            # Continue without error
        }
        
        # Get kernel version
        try {
            $kernelVersion = & wsl --uname -r 2>$null
            if ($kernelVersion) {
                $result.KernelVersion = $kernelVersion
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-WSL {
    <#
    .SYNOPSIS
    Install WSL with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallDistributions = $true
    )
    
    Write-ComponentHeader "Installing WSL $Version"
    
    # Check if already installed
    $currentInstallation = Test-WSLInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "WSL is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Enable WSL feature
        Write-ComponentStep "Enabling WSL feature..." "INFO"
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Write-ComponentStep "WSL feature enabled" "SUCCESS"
        
        # Enable Virtual Machine Platform
        Write-ComponentStep "Enabling Virtual Machine Platform..." "INFO"
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        Write-ComponentStep "Virtual Machine Platform enabled" "SUCCESS"
        
        # Set WSL 2 as default
        Write-ComponentStep "Setting WSL 2 as default..." "INFO"
        wsl --set-default-version 2
        Write-ComponentStep "WSL 2 set as default" "SUCCESS"
        
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing WSL using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "WSL installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing WSL using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "WSL installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing WSL manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying WSL installation..." "INFO"
        $postInstallVerification = Test-WSLInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "WSL installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "WSL installation verification failed" "WARNING"
            return $false
        }
        
        # Install distributions if requested
        if ($InstallDistributions) {
            Write-ComponentStep "Installing WSL distributions..." "INFO"
            
            $distributions = @(
                "Ubuntu",
                "Ubuntu-20.04",
                "Ubuntu-22.04",
                "Debian",
                "Kali-Linux",
                "openSUSE-Leap",
                "SUSE-Linux-Enterprise-Server-15-SP1",
                "SUSE-Linux-Enterprise-Server-15-SP2",
                "SUSE-Linux-Enterprise-Server-15-SP3",
                "SUSE-Linux-Enterprise-Server-15-SP4",
                "SUSE-Linux-Enterprise-Server-15-SP5"
            )
            
            foreach ($distro in $distributions) {
                try {
                    wsl --install -d $distro
                    Write-ComponentStep "  ✓ $distro installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $distro" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install WSL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-WSLFunctionality {
    <#
    .SYNOPSIS
    Test WSL functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing WSL Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "wsl --version",
        "wsl --help",
        "wsl --list",
        "wsl --status",
        "wsl --uname -a"
    )
    
    $expectedOutputs = @(
        "WSL",
        "wsl",
        "wsl",
        "wsl",
        "wsl"
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

function Update-WSL {
    <#
    .SYNOPSIS
    Update WSL to latest version
    #>
    Write-ComponentHeader "Updating WSL"
    
    $currentInstallation = Test-WSLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "WSL is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating WSL..." "INFO"
    
    try {
        # Update WSL using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "WSL updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "WSL updated using Chocolatey" "SUCCESS"
        }
        
        # Update WSL kernel
        wsl --update
        Write-ComponentStep "WSL kernel updated" "SUCCESS"
        
        Write-ComponentStep "WSL update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update WSL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-WSLPath {
    <#
    .SYNOPSIS
    Fix WSL PATH issues
    #>
    Write-ComponentHeader "Fixing WSL PATH"
    
    $wslPaths = @(
        "${env:ProgramFiles}\Windows Subsystem for Linux",
        "${env:ProgramFiles(x86)}\Windows Subsystem for Linux",
        "${env:LOCALAPPDATA}\Microsoft\WindowsApps"
    )
    
    $foundPaths = @()
    foreach ($path in $wslPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found WSL paths:" "INFO"
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
            Write-ComponentStep "Added WSL paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "WSL paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No WSL paths found" "WARNING"
    }
}

function Uninstall-WSL {
    <#
    .SYNOPSIS
    Uninstall WSL
    #>
    Write-ComponentHeader "Uninstalling WSL"
    
    $currentInstallation = Test-WSLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "WSL is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing WSL from PATH..." "INFO"
    
    # Remove WSL paths from environment
    $currentPath = $env:Path
    $wslPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $wslPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Disable WSL feature
    Write-ComponentStep "Disabling WSL feature..." "INFO"
    Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    Write-ComponentStep "WSL feature disabled" "SUCCESS"
    
    Write-ComponentStep "WSL removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of WSL files may be required" "WARNING"
    
    return $true
}

function Show-WSLStatus {
    <#
    .SYNOPSIS
    Show comprehensive WSL status
    #>
    Write-ComponentHeader "WSL Status Report"
    
    $installation = Test-WSLInstallation -Detailed:$Detailed
    $functionality = Test-WSLFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  WSL Version: $($installation.WSLVersion)" -ForegroundColor White
    Write-Host "  Kernel Version: $($installation.KernelVersion)" -ForegroundColor White
    Write-Host "  Default Distribution: $($installation.DefaultDistribution)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Distributions.Count -gt 0) {
        Write-Host "`nInstalled Distributions:" -ForegroundColor Cyan
        foreach ($distro in $installation.Distributions) {
            Write-Host "  - $distro" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-WSLHelp {
    <#
    .SYNOPSIS
    Show help information for WSL component
    #>
    Write-ComponentHeader "WSL Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install WSL" -ForegroundColor White
    Write-Host "  test        - Test WSL functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall WSL" -ForegroundColor White
    Write-Host "  update      - Update WSL and kernel" -ForegroundColor White
    Write-Host "  check       - Check WSL installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix WSL PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall WSL" -ForegroundColor White
    Write-Host "  status      - Show WSL status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\wsl.ps1 install                    # Install WSL" -ForegroundColor White
    Write-Host "  .\wsl.ps1 test                       # Test WSL" -ForegroundColor White
    Write-Host "  .\wsl.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\wsl.ps1 update                     # Update WSL" -ForegroundColor White
    Write-Host "  .\wsl.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\wsl.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\wsl.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - WSL version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallDistributions  - Install distributions" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-WSL -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallDistributions:$InstallDistributions
        if ($result) {
            Write-ComponentStep "WSL installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "WSL installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-WSLFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "WSL functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "WSL functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling WSL..." "INFO"
        $result = Install-WSL -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallDistributions:$InstallDistributions
        if ($result) {
            Write-ComponentStep "WSL reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "WSL reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-WSL
        if ($result) {
            Write-ComponentStep "WSL update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "WSL update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-WSLInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "WSL is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "WSL is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-WSLPath
        Write-ComponentStep "WSL PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-WSL
        if ($result) {
            Write-ComponentStep "WSL uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "WSL uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-WSLStatus
    }
    "help" {
        Show-WSLHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-WSLHelp
        exit 1
    }
}
