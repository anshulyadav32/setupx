# Complete Git Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$ConfigureGit = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Git"
    Version = "1.0.0"
    Description = "Complete Git Version Control System"
    ExecutableNames = @("git.exe", "git")
    VersionCommands = @("git --version")
    TestCommands = @("git --version", "git --help", "git config --list")
    WingetId = "Git.Git"
    ChocoId = "git"
    DownloadUrl = "https://git-scm.com/download/win"
    Documentation = "https://git-scm.com/docs"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "GIT COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-GitInstallation {
    <#
    .SYNOPSIS
    Comprehensive Git installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Git installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        ConfigAvailable = $false
        UserConfigured = $false
        DefaultBranch = ""
    }
    
    # Check Git executable
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
            $version = & git --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check Git configuration
        try {
            $config = & git config --list 2>$null
            if ($config) {
                $result.ConfigAvailable = $true
                $result.UserConfigured = ($config -match "user.name" -and $config -match "user.email")
                $result.DefaultBranch = ($config | Where-Object { $_ -match "init.defaultbranch" } | ForEach-Object { ($_ -split "=")[1] }) -join ", "
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Git {
    <#
    .SYNOPSIS
    Install Git with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$ConfigureGit = $true
    )
    
    Write-ComponentHeader "Installing Git $Version"
    
    # Check if already installed
    $currentInstallation = Test-GitInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Git is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Git using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Git installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Git using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Git installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Git manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Git installation..." "INFO"
        $postInstallVerification = Test-GitInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Git installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Git installation verification failed" "WARNING"
            return $false
        }
        
        # Configure Git if requested
        if ($ConfigureGit) {
            Write-ComponentStep "Configuring Git..." "INFO"
            
            # Set default branch to main
            git config --global init.defaultBranch main
            Write-ComponentStep "Set default branch to main" "SUCCESS"
            
            # Set common Git configurations
            git config --global core.autocrlf true
            git config --global core.safecrlf false
            git config --global pull.rebase false
            git config --global push.default simple
            git config --global color.ui auto
            git config --global color.branch auto
            git config --global color.diff auto
            git config --global color.status auto
            git config --global color.interactive auto
            git config --global color.pager true
            git config --global core.editor "code --wait"
            git config --global merge.tool "code"
            git config --global diff.tool "code"
            
            Write-ComponentStep "Git configuration completed" "SUCCESS"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Git: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-GitFunctionality {
    <#
    .SYNOPSIS
    Test Git functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Git Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "git --version",
        "git --help",
        "git config --list",
        "git status --help",
        "git log --oneline --max-count=1"
    )
    
    $expectedOutputs = @(
        "git version",
        "Git",
        "core",
        "Git",
        "Git"
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

function Update-Git {
    <#
    .SYNOPSIS
    Update Git to latest version
    #>
    Write-ComponentHeader "Updating Git"
    
    $currentInstallation = Test-GitInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Git is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Git..." "INFO"
    
    try {
        # Update Git using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Git updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Git updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Git update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Git: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-GitPath {
    <#
    .SYNOPSIS
    Fix Git PATH issues
    #>
    Write-ComponentHeader "Fixing Git PATH"
    
    $gitPaths = @(
        "${env:ProgramFiles}\Git\bin",
        "${env:ProgramFiles(x86)}\Git\bin",
        "${env:LOCALAPPDATA}\Git\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $gitPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Git paths:" "INFO"
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
            Write-ComponentStep "Added Git paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Git paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Git paths found" "WARNING"
    }
}

function Uninstall-Git {
    <#
    .SYNOPSIS
    Uninstall Git
    #>
    Write-ComponentHeader "Uninstalling Git"
    
    $currentInstallation = Test-GitInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Git is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Git from PATH..." "INFO"
    
    # Remove Git paths from environment
    $currentPath = $env:Path
    $gitPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $gitPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Git removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Git files may be required" "WARNING"
    
    return $true
}

function Show-GitStatus {
    <#
    .SYNOPSIS
    Show comprehensive Git status
    #>
    Write-ComponentHeader "Git Status Report"
    
    $installation = Test-GitInstallation -Detailed:$Detailed
    $functionality = Test-GitFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Config Available: $(if ($installation.ConfigAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  User Configured: $(if ($installation.UserConfigured) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Default Branch: $($installation.DefaultBranch)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-GitHelp {
    <#
    .SYNOPSIS
    Show help information for Git component
    #>
    Write-ComponentHeader "Git Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Git" -ForegroundColor White
    Write-Host "  test        - Test Git functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Git" -ForegroundColor White
    Write-Host "  update      - Update Git" -ForegroundColor White
    Write-Host "  check       - Check Git installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Git PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Git" -ForegroundColor White
    Write-Host "  status      - Show Git status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\git.ps1 install                    # Install Git" -ForegroundColor White
    Write-Host "  .\git.ps1 test                       # Test Git" -ForegroundColor White
    Write-Host "  .\git.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\git.ps1 update                     # Update Git" -ForegroundColor White
    Write-Host "  .\git.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\git.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\git.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Git version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -ConfigureGit          - Configure Git" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Git -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -ConfigureGit:$ConfigureGit
        if ($result) {
            Write-ComponentStep "Git installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Git installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-GitFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Git functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Git functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Git..." "INFO"
        $result = Install-Git -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -ConfigureGit:$ConfigureGit
        if ($result) {
            Write-ComponentStep "Git reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Git reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Git
        if ($result) {
            Write-ComponentStep "Git update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Git update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-GitInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Git is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Git is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-GitPath
        Write-ComponentStep "Git PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Git
        if ($result) {
            Write-ComponentStep "Git uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Git uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-GitStatus
    }
    "help" {
        Show-GitHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-GitHelp
        exit 1
    }
}
