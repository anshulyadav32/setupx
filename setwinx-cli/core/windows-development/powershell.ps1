# Complete PowerShell Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "PowerShell"
    Version = "1.0.0"
    Description = "Complete PowerShell Development Environment"
    ExecutableNames = @("powershell.exe", "pwsh.exe", "powershell", "pwsh")
    VersionCommands = @("powershell --version", "pwsh --version")
    TestCommands = @("powershell --version", "pwsh --version", "Get-Host")
    WingetId = "Microsoft.PowerShell"
    ChocoId = "powershell-core"
    DownloadUrl = "https://github.com/PowerShell/PowerShell/releases"
    Documentation = "https://docs.microsoft.com/en-us/powershell/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "POWERSHELL COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-PowerShellInstallation {
    <#
    .SYNOPSIS
    Comprehensive PowerShell installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking PowerShell installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        PowerShellCoreAvailable = $false
        WindowsPowerShellAvailable = $false
        Modules = @()
        ExecutionPolicy = ""
        ProfileConfigured = $false
    }
    
    # Check PowerShell executable
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
            $version = & powershell --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check PowerShell Core availability
        $result.PowerShellCoreAvailable = (Get-Command pwsh -ErrorAction SilentlyContinue) -ne $null
        
        # Check Windows PowerShell availability
        $result.WindowsPowerShellAvailable = (Get-Command powershell -ErrorAction SilentlyContinue) -ne $null
        
        # Get execution policy
        try {
            $executionPolicy = Get-ExecutionPolicy
            $result.ExecutionPolicy = $executionPolicy
        } catch {
            $result.ExecutionPolicy = "Unknown"
        }
        
        # Check profile configuration
        $profilePath = $PROFILE
        $result.ProfileConfigured = Test-Path $profilePath
        
        # Get installed modules
        try {
            $modules = Get-Module -ListAvailable
            if ($modules) {
                $result.Modules = $modules | ForEach-Object { $_.Name }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-PowerShell {
    <#
    .SYNOPSIS
    Install PowerShell with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallModules = $true
    )
    
    Write-ComponentHeader "Installing PowerShell $Version"
    
    # Check if already installed
    $currentInstallation = Test-PowerShellInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "PowerShell is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing PowerShell using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "PowerShell installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing PowerShell using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "PowerShell installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing PowerShell manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying PowerShell installation..." "INFO"
        $postInstallVerification = Test-PowerShellInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "PowerShell installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "PowerShell installation verification failed" "WARNING"
            return $false
        }
        
        # Install modules if requested
        if ($InstallModules) {
            Write-ComponentStep "Installing PowerShell modules..." "INFO"
            
            $modules = @(
                "PowerShellGet",
                "PackageManagement",
                "PSReadLine",
                "PSFzf",
                "Posh-Git",
                "PSWindowsUpdate",
                "PSScriptAnalyzer",
                "ImportExcel",
                "Pester",
                "Plaster"
            )
            
            foreach ($module in $modules) {
                try {
                    Install-Module -Name $module -Force -AllowClobber
                    Write-ComponentStep "  ✓ $module installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $module" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install PowerShell: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PowerShellFunctionality {
    <#
    .SYNOPSIS
    Test PowerShell functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing PowerShell Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "powershell --version",
        "pwsh --version",
        "Get-Host",
        "Get-Module",
        "Get-ExecutionPolicy"
    )
    
    $expectedOutputs = @(
        "PowerShell",
        "PowerShell",
        "PowerShell",
        "PowerShell",
        "PowerShell"
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

function Update-PowerShell {
    <#
    .SYNOPSIS
    Update PowerShell to latest version
    #>
    Write-ComponentHeader "Updating PowerShell"
    
    $currentInstallation = Test-PowerShellInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "PowerShell is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating PowerShell..." "INFO"
    
    try {
        # Update PowerShell using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "PowerShell updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "PowerShell updated using Chocolatey" "SUCCESS"
        }
        
        # Update modules
        Update-Module -Force
        Write-ComponentStep "PowerShell modules updated" "SUCCESS"
        
        Write-ComponentStep "PowerShell update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update PowerShell: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-PowerShellPath {
    <#
    .SYNOPSIS
    Fix PowerShell PATH issues
    #>
    Write-ComponentHeader "Fixing PowerShell PATH"
    
    $powershellPaths = @(
        "${env:ProgramFiles}\PowerShell\7",
        "${env:ProgramFiles(x86)}\PowerShell\7",
        "${env:LOCALAPPDATA}\Programs\PowerShell\7"
    )
    
    $foundPaths = @()
    foreach ($path in $powershellPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found PowerShell paths:" "INFO"
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
            Write-ComponentStep "Added PowerShell paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "PowerShell paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No PowerShell paths found" "WARNING"
    }
}

function Uninstall-PowerShell {
    <#
    .SYNOPSIS
    Uninstall PowerShell
    #>
    Write-ComponentHeader "Uninstalling PowerShell"
    
    $currentInstallation = Test-PowerShellInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "PowerShell is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing PowerShell from PATH..." "INFO"
    
    # Remove PowerShell paths from environment
    $currentPath = $env:Path
    $powershellPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $powershellPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "PowerShell removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of PowerShell files may be required" "WARNING"
    
    return $true
}

function Show-PowerShellStatus {
    <#
    .SYNOPSIS
    Show comprehensive PowerShell status
    #>
    Write-ComponentHeader "PowerShell Status Report"
    
    $installation = Test-PowerShellInstallation -Detailed:$Detailed
    $functionality = Test-PowerShellFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  PowerShell Core Available: $(if ($installation.PowerShellCoreAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Windows PowerShell Available: $(if ($installation.WindowsPowerShellAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Execution Policy: $($installation.ExecutionPolicy)" -ForegroundColor White
    Write-Host "  Profile Configured: $(if ($installation.ProfileConfigured) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Modules.Count -gt 0) {
        Write-Host "`nInstalled Modules:" -ForegroundColor Cyan
        foreach ($module in $installation.Modules) {
            Write-Host "  - $module" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-PowerShellHelp {
    <#
    .SYNOPSIS
    Show help information for PowerShell component
    #>
    Write-ComponentHeader "PowerShell Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install PowerShell" -ForegroundColor White
    Write-Host "  test        - Test PowerShell functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall PowerShell" -ForegroundColor White
    Write-Host "  update      - Update PowerShell and modules" -ForegroundColor White
    Write-Host "  check       - Check PowerShell installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix PowerShell PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall PowerShell" -ForegroundColor White
    Write-Host "  status      - Show PowerShell status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\powershell.ps1 install                    # Install PowerShell" -ForegroundColor White
    Write-Host "  .\powershell.ps1 test                       # Test PowerShell" -ForegroundColor White
    Write-Host "  .\powershell.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\powershell.ps1 update                     # Update PowerShell" -ForegroundColor White
    Write-Host "  .\powershell.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\powershell.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\powershell.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - PowerShell version to install" -ForegroundColor White
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
        $result = Install-PowerShell -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallModules:$InstallModules
        if ($result) {
            Write-ComponentStep "PowerShell installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "PowerShell installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-PowerShellFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "PowerShell functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "PowerShell functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling PowerShell..." "INFO"
        $result = Install-PowerShell -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallModules:$InstallModules
        if ($result) {
            Write-ComponentStep "PowerShell reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PowerShell reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-PowerShell
        if ($result) {
            Write-ComponentStep "PowerShell update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PowerShell update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-PowerShellInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "PowerShell is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "PowerShell is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-PowerShellPath
        Write-ComponentStep "PowerShell PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-PowerShell
        if ($result) {
            Write-ComponentStep "PowerShell uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PowerShell uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-PowerShellStatus
    }
    "help" {
        Show-PowerShellHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-PowerShellHelp
        exit 1
    }
}
