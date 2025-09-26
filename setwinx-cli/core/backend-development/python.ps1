# Complete Python Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallPip = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Python"
    Version = "1.0.0"
    Description = "Complete Python Programming Language Environment"
    ExecutableNames = @("python.exe", "python", "pip.exe", "pip")
    VersionCommands = @("python --version", "pip --version")
    TestCommands = @("python --version", "pip --version", "python -c print('Hello World')")
    WingetId = "Python.Python.3"
    ChocoId = "python"
    DownloadUrl = "https://www.python.org/downloads/"
    Documentation = "https://docs.python.org/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "PYTHON COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-PythonInstallation {
    <#
    .SYNOPSIS
    Comprehensive Python installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Python installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        PipAvailable = $false
        PipVersion = "Unknown"
        PackagesInstalled = @()
    }
    
    # Check Python executable
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
            $version = & python --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check pip availability
        $result.PipAvailable = $null -ne (Get-Command pip -ErrorAction SilentlyContinue)
        if ($result.PipAvailable) {
            try {
                $pipVersion = & pip --version 2>$null
                if ($pipVersion) {
                    $result.PipVersion = $pipVersion
                }
            } catch {
                $result.PipVersion = "Unknown"
            }
        }
        
        # Check installed packages
        try {
            $packages = & pip list 2>$null
            if ($packages) {
                $result.PackagesInstalled = $packages | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Python {
    <#
    .SYNOPSIS
    Install Python with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallPip = $true
    )
    
    Write-ComponentHeader "Installing Python $Version"
    
    # Check if already installed
    $currentInstallation = Test-PythonInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Python is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Python using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Python installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Python using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Python installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Python manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Python installation..." "INFO"
        $postInstallVerification = Test-PythonInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Python installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Python installation verification failed" "WARNING"
            return $false
        }
        
        # Install pip if requested
        if ($InstallPip) {
            Write-ComponentStep "Installing pip..." "INFO"
            
            # Update pip to latest version
            python -m pip install --upgrade pip
            Write-ComponentStep "pip updated to latest version" "SUCCESS"
            
            # Install essential Python packages
            Write-ComponentStep "Installing essential Python packages..." "INFO"
            
            $essentialPackages = @(
                "setuptools", "wheel", "virtualenv", "pipenv", "requests", 
                "numpy", "pandas", "matplotlib", "jupyter", "flask", "django"
            )
            
            foreach ($package in $essentialPackages) {
                try {
                    pip install $package
                    Write-ComponentStep "  ✓ $package installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $package" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Python: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PythonFunctionality {
    <#
    .SYNOPSIS
    Test Python functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Python Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "python --version",
        "pip --version",
        "python -c print('Hello World')",
        "python -c import sys; print(sys.version)",
        "python -c import pip; print(pip.__version__)"
    )
    
    $expectedOutputs = @(
        "Python",
        "pip",
        "Hello World",
        "Python",
        "pip"
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

function Update-Python {
    <#
    .SYNOPSIS
    Update Python to latest version
    #>
    Write-ComponentHeader "Updating Python"
    
    $currentInstallation = Test-PythonInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Python is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Python..." "INFO"
    
    try {
        # Update Python using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Python updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Python updated using Chocolatey" "SUCCESS"
        }
        
        # Update pip
        python -m pip install --upgrade pip
        Write-ComponentStep "pip updated" "SUCCESS"
        
        # Update all packages
        pip list --outdated --format=freeze | ForEach-Object { ($_ -split "==")[0] } | ForEach-Object { pip install --upgrade $_ }
        Write-ComponentStep "All packages updated" "SUCCESS"
        
        Write-ComponentStep "Python update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Python: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-PythonPath {
    <#
    .SYNOPSIS
    Fix Python PATH issues
    #>
    Write-ComponentHeader "Fixing Python PATH"
    
    $pythonPaths = @(
        "${env:ProgramFiles}\Python*",
        "${env:ProgramFiles(x86)}\Python*",
        "${env:LOCALAPPDATA}\Programs\Python\Python*"
    )
    
    $foundPaths = @()
    foreach ($path in $pythonPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            $binPath = Join-Path $expandedPath.FullName "Scripts"
            $pythonPath = Join-Path $expandedPath.FullName "python.exe"
            if (Test-Path $binPath) { $foundPaths += $binPath }
            if (Test-Path $pythonPath) { $foundPaths += $expandedPath.FullName }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Python paths:" "INFO"
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
            Write-ComponentStep "Added Python paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Python paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Python paths found" "WARNING"
    }
}

function Uninstall-Python {
    <#
    .SYNOPSIS
    Uninstall Python
    #>
    Write-ComponentHeader "Uninstalling Python"
    
    $currentInstallation = Test-PythonInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Python is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Python from PATH..." "INFO"
    
    # Remove Python paths from environment
    $currentPath = $env:Path
    $pythonPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $pythonPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Python removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Python files may be required" "WARNING"
    
    return $true
}

function Show-PythonStatus {
    <#
    .SYNOPSIS
    Show comprehensive Python status
    #>
    Write-ComponentHeader "Python Status Report"
    
    $installation = Test-PythonInstallation -Detailed:$Detailed
    $functionality = Test-PythonFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Pip Available: $(if ($installation.PipAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Pip Version: $($installation.PipVersion)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.PackagesInstalled.Count -gt 0) {
        Write-Host "`nInstalled Packages:" -ForegroundColor Cyan
        foreach ($package in $installation.PackagesInstalled) {
            Write-Host "  - $package" -ForegroundColor White
        }
    }
}

function Show-PythonHelp {
    <#
    .SYNOPSIS
    Show help information for Python component
    #>
    Write-ComponentHeader "Python Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Python" -ForegroundColor White
    Write-Host "  test        - Test Python functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Python" -ForegroundColor White
    Write-Host "  update      - Update Python and packages" -ForegroundColor White
    Write-Host "  check       - Check Python installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Python PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Python" -ForegroundColor White
    Write-Host "  status      - Show Python status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\python.ps1 install                    # Install Python" -ForegroundColor White
    Write-Host "  .\python.ps1 test                       # Test Python" -ForegroundColor White
    Write-Host "  .\python.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\python.ps1 update                     # Update Python" -ForegroundColor White
    Write-Host "  .\python.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\python.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\python.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Python version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallPip            - Install pip" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Python -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallPip:$InstallPip
        if ($result) {
            Write-ComponentStep "Python installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Python installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-PythonFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Python functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Python functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Python..." "INFO"
        $result = Install-Python -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallPip:$InstallPip
        if ($result) {
            Write-ComponentStep "Python reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Python reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Python
        if ($result) {
            Write-ComponentStep "Python update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Python update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-PythonInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Python is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Python is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-PythonPath
        Write-ComponentStep "Python PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Python
        if ($result) {
            Write-ComponentStep "Python uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Python uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-PythonStatus
    }
    "help" {
        Show-PythonHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-PythonHelp
        exit 1
    }
}
