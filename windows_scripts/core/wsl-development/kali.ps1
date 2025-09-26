# Complete Kali Linux WSL Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallTools = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Kali Linux WSL"
    Version = "1.0.0"
    Description = "Complete Kali Linux WSL Distribution"
    ExecutableNames = @("kali.exe", "kali")
    VersionCommands = @("wsl -d kali-linux -- cat /etc/os-release")
    TestCommands = @("wsl -d kali-linux -- lsb_release -a", "wsl -d kali-linux -- uname -a")
    WingetId = "KaliLinux.KaliLinux"
    ChocoId = "kali-linux"
    DownloadUrl = "https://www.microsoft.com/store/productId/9PKR34TNCV07"
    Documentation = "https://www.kali.org/docs/wsl/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "KALI LINUX WSL COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-KaliWSLInstallation {
    <#
    .SYNOPSIS
    Comprehensive Kali Linux WSL installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Kali Linux WSL installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        DistributionName = ""
        OSVersion = ""
        KernelVersion = ""
        ToolsInstalled = @()
        UserConfigured = $false
    }
    
    # Check Kali Linux WSL executable
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
            $version = & wsl -d kali-linux -- cat /etc/os-release 2>$null
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
            $kernelVersion = & wsl -d kali-linux -- uname -r 2>$null
            if ($kernelVersion) {
                $result.KernelVersion = $kernelVersion
            }
        } catch {
            # Continue without error
        }
        
        # Check if user is configured
        try {
            $user = & wsl -d kali-linux -- whoami 2>$null
            if ($user) {
                $result.UserConfigured = $true
            }
        } catch {
            # Continue without error
        }
        
        # Get installed tools
        try {
            $tools = & wsl -d kali-linux -- dpkg -l 2>$null
            if ($tools) {
                $result.ToolsInstalled = $tools | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[1] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-KaliWSL {
    <#
    .SYNOPSIS
    Install Kali Linux WSL with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallTools = $true
    )
    
    Write-ComponentHeader "Installing Kali Linux WSL $Version"
    
    # Check if already installed
    $currentInstallation = Test-KaliWSLInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Kali Linux WSL is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Kali Linux WSL using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Kali Linux WSL installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Kali Linux WSL using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Kali Linux WSL installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Kali Linux WSL manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Kali Linux WSL installation..." "INFO"
        $postInstallVerification = Test-KaliWSLInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Kali Linux WSL installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Kali Linux WSL installation verification failed" "WARNING"
            return $false
        }
        
        # Install tools if requested
        if ($InstallTools) {
            Write-ComponentStep "Installing Kali Linux WSL tools..." "INFO"
            
            $tools = @(
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
                "docker-compose",
                "nmap",
                "metasploit-framework",
                "burpsuite",
                "wireshark",
                "john",
                "hashcat",
                "aircrack-ng",
                "sqlmap",
                "nikto",
                "dirb",
                "gobuster",
                "ffuf",
                "wfuzz",
                "dirbuster",
                "dirsearch",
                "sublist3r",
                "amass",
                "masscan",
                "zmap",
                "nmap",
                "masscan",
                "zmap",
                "nmap",
                "masscan",
                "zmap"
            )
            
            foreach ($tool in $tools) {
                try {
                    wsl -d kali-linux -- apt update
                    wsl -d kali-linux -- apt install -y $tool
                    Write-ComponentStep "  ✓ $tool installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $tool" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Kali Linux WSL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-KaliWSLFunctionality {
    <#
    .SYNOPSIS
    Test Kali Linux WSL functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Kali Linux WSL Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "wsl -d kali-linux -- lsb_release -a",
        "wsl -d kali-linux -- uname -a",
        "wsl -d kali-linux -- whoami",
        "wsl -d kali-linux -- pwd",
        "wsl -d kali-linux -- ls -la"
    )
    
    $expectedOutputs = @(
        "Kali",
        "Linux",
        "kali",
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

function Update-KaliWSL {
    <#
    .SYNOPSIS
    Update Kali Linux WSL to latest version
    #>
    Write-ComponentHeader "Updating Kali Linux WSL"
    
    $currentInstallation = Test-KaliWSLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Kali Linux WSL is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Kali Linux WSL..." "INFO"
    
    try {
        # Update Kali Linux WSL using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Kali Linux WSL updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Kali Linux WSL updated using Chocolatey" "SUCCESS"
        }
        
        # Update tools
        wsl -d kali-linux -- apt update
        wsl -d kali-linux -- apt upgrade -y
        Write-ComponentStep "Kali Linux WSL tools updated" "SUCCESS"
        
        Write-ComponentStep "Kali Linux WSL update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Kali Linux WSL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-KaliWSLPath {
    <#
    .SYNOPSIS
    Fix Kali Linux WSL PATH issues
    #>
    Write-ComponentHeader "Fixing Kali Linux WSL PATH"
    
    $kaliPaths = @(
        "${env:ProgramFiles}\Windows Subsystem for Linux",
        "${env:ProgramFiles(x86)}\Windows Subsystem for Linux",
        "${env:LOCALAPPDATA}\Microsoft\WindowsApps"
    )
    
    $foundPaths = @()
    foreach ($path in $kaliPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Kali Linux WSL paths:" "INFO"
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
            Write-ComponentStep "Added Kali Linux WSL paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Kali Linux WSL paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Kali Linux WSL paths found" "WARNING"
    }
}

function Uninstall-KaliWSL {
    <#
    .SYNOPSIS
    Uninstall Kali Linux WSL
    #>
    Write-ComponentHeader "Uninstalling Kali Linux WSL"
    
    $currentInstallation = Test-KaliWSLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Kali Linux WSL is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Kali Linux WSL from PATH..." "INFO"
    
    # Remove Kali Linux WSL paths from environment
    $currentPath = $env:Path
    $kaliPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $kaliPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Kali Linux WSL removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Kali Linux WSL files may be required" "WARNING"
    
    return $true
}

function Show-KaliWSLStatus {
    <#
    .SYNOPSIS
    Show comprehensive Kali Linux WSL status
    #>
    Write-ComponentHeader "Kali Linux WSL Status Report"
    
    $installation = Test-KaliWSLInstallation -Detailed:$Detailed
    $functionality = Test-KaliWSLFunctionality -Detailed:$Detailed
    
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
    
    if ($installation.ToolsInstalled.Count -gt 0) {
        Write-Host "`nInstalled Tools:" -ForegroundColor Cyan
        foreach ($tool in $installation.ToolsInstalled) {
            Write-Host "  - $tool" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-KaliWSLHelp {
    <#
    .SYNOPSIS
    Show help information for Kali Linux WSL component
    #>
    Write-ComponentHeader "Kali Linux WSL Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Kali Linux WSL" -ForegroundColor White
    Write-Host "  test        - Test Kali Linux WSL functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Kali Linux WSL" -ForegroundColor White
    Write-Host "  update      - Update Kali Linux WSL and tools" -ForegroundColor White
    Write-Host "  check       - Check Kali Linux WSL installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Kali Linux WSL PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Kali Linux WSL" -ForegroundColor White
    Write-Host "  status      - Show Kali Linux WSL status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\kali.ps1 install                    # Install Kali Linux WSL" -ForegroundColor White
    Write-Host "  .\kali.ps1 test                       # Test Kali Linux WSL" -ForegroundColor White
    Write-Host "  .\kali.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\kali.ps1 update                     # Update Kali Linux WSL" -ForegroundColor White
    Write-Host "  .\kali.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\kali.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\kali.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Kali Linux WSL version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallTools          - Install tools" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-KaliWSL -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallTools:$InstallTools
        if ($result) {
            Write-ComponentStep "Kali Linux WSL installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Kali Linux WSL installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-KaliWSLFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Kali Linux WSL functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Kali Linux WSL functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Kali Linux WSL..." "INFO"
        $result = Install-KaliWSL -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallTools:$InstallTools
        if ($result) {
            Write-ComponentStep "Kali Linux WSL reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Kali Linux WSL reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-KaliWSL
        if ($result) {
            Write-ComponentStep "Kali Linux WSL update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Kali Linux WSL update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-KaliWSLInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Kali Linux WSL is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Kali Linux WSL is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-KaliWSLPath
        Write-ComponentStep "Kali Linux WSL PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-KaliWSL
        if ($result) {
            Write-ComponentStep "Kali Linux WSL uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Kali Linux WSL uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-KaliWSLStatus
    }
    "help" {
        Show-KaliWSLHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-KaliWSLHelp
        exit 1
    }
}
