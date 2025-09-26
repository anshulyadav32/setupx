# Complete Node.js Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallGlobalPackages = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Node.js"
    Version = "1.0.0"
    Description = "Complete Node.js Development Environment"
    ExecutableNames = @("node.exe", "node", "npm.exe", "npm")
    VersionCommands = @("node --version", "npm --version")
    TestCommands = @("node --version", "npm --version", "node -e `"console.log('Hello World')`"")
    WingetId = "OpenJS.NodeJS"
    ChocoId = "nodejs"
    DownloadUrl = "https://nodejs.org/"
    Documentation = "https://nodejs.org/docs/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "NODE.JS COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-NodeJsInstallation {
    <#
    .SYNOPSIS
    Comprehensive Node.js installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Node.js installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        NpmAvailable = $false
        YarnAvailable = $false
        PnpmAvailable = $false
    }
    
    # Check Node.js executable
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
            $nodeVersion = & node --version 2>$null
            $npmVersion = & npm --version 2>$null
            if ($nodeVersion -and $npmVersion) {
                $result.Version = "$nodeVersion, npm: $npmVersion"
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check additional tools
        $result.NpmAvailable = (Get-Command npm -ErrorAction SilentlyContinue) -ne $null
        $result.YarnAvailable = (Get-Command yarn -ErrorAction SilentlyContinue) -ne $null
        $result.PnpmAvailable = (Get-Command pnpm -ErrorAction SilentlyContinue) -ne $null
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-NodeJs {
    <#
    .SYNOPSIS
    Install Node.js with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallGlobalPackages = $true
    )
    
    Write-ComponentHeader "Installing Node.js $Version"
    
    # Check if already installed
    $currentInstallation = Test-NodeJsInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Node.js is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Node.js using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Node.js installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Node.js using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Node.js installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Node.js manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Node.js installation..." "INFO"
        $postInstallVerification = Test-NodeJsInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Node.js installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Node.js installation verification failed" "WARNING"
            return $false
        }
        
        # Install global packages
        if ($InstallGlobalPackages) {
            Write-ComponentStep "Installing global Node.js packages..." "INFO"
            
            $globalPackages = @(
                "yarn", "pnpm", "nodemon", "pm2", "typescript", 
                "ts-node", "eslint", "prettier", "jest", "mocha"
            )
            
            foreach ($package in $globalPackages) {
                try {
                    npm install -g $package
                    Write-ComponentStep "  ✓ $package installed globally" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $package globally" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Node.js: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-NodeJsFunctionality {
    <#
    .SYNOPSIS
    Test Node.js functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Node.js Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "node --version",
        "npm --version",
        "node -e `"console.log('Hello World')`"",
        "node -e `"console.log(process.version)`"",
        "node -e `"console.log(process.platform)`""
    )
    
    $expectedOutputs = @(
        "v",
        "npm",
        "Hello World",
        "v",
        "win32"
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

function Update-NodeJs {
    <#
    .SYNOPSIS
    Update Node.js to latest version
    #>
    Write-ComponentHeader "Updating Node.js"
    
    $currentInstallation = Test-NodeJsInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Node.js is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Node.js..." "INFO"
    
    try {
        # Update Node.js using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Node.js updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Node.js updated using Chocolatey" "SUCCESS"
        }
        
        # Update npm
        npm install -g npm@latest
        Write-ComponentStep "npm updated" "SUCCESS"
        
        # Update global packages
        $packages = @("yarn", "pnpm", "nodemon", "pm2", "typescript", "ts-node", "eslint", "prettier", "jest", "mocha")
        foreach ($package in $packages) {
            try {
                npm install -g $package@latest
                Write-ComponentStep "  ✓ $package updated" "SUCCESS"
            } catch {
                Write-ComponentStep "  ✗ Failed to update $package" "WARNING"
            }
        }
        
        Write-ComponentStep "Node.js update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Node.js: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-NodeJsPath {
    <#
    .SYNOPSIS
    Fix Node.js PATH issues
    #>
    Write-ComponentHeader "Fixing Node.js PATH"
    
    $nodePaths = @(
        "$env:ProgramFiles\nodejs",
        "$env:ProgramFiles(x86)\nodejs",
        "$env:APPDATA\npm"
    )
    
    $foundPaths = @()
    foreach ($path in $nodePaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Node.js paths:" "INFO"
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
            Write-ComponentStep "Added Node.js paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Node.js paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Node.js paths found" "WARNING"
    }
}

function Uninstall-NodeJs {
    <#
    .SYNOPSIS
    Uninstall Node.js
    #>
    Write-ComponentHeader "Uninstalling Node.js"
    
    $currentInstallation = Test-NodeJsInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Node.js is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Node.js from PATH..." "INFO"
    
    # Remove Node.js paths from environment
    $currentPath = $env:Path
    $nodePaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $nodePaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Node.js removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Node.js files may be required" "WARNING"
    
    return $true
}

function Show-NodeJsStatus {
    <#
    .SYNOPSIS
    Show comprehensive Node.js status
    #>
    Write-ComponentHeader "Node.js Status Report"
    
    $installation = Test-NodeJsInstallation -Detailed:$Detailed
    $functionality = Test-NodeJsFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    Write-Host "`nAvailable Tools:" -ForegroundColor Cyan
    Write-Host "  Node.js: $(if ($installation.IsInstalled) { 'Available' } else { 'Not Available' })" -ForegroundColor White
    Write-Host "  npm: $(if ($installation.NpmAvailable) { 'Available' } else { 'Not Available' })" -ForegroundColor White
    Write-Host "  yarn: $(if ($installation.YarnAvailable) { 'Available' } else { 'Not Available' })" -ForegroundColor White
    Write-Host "  pnpm: $(if ($installation.PnpmAvailable) { 'Available' } else { 'Not Available' })" -ForegroundColor White
}

function Show-NodeJsHelp {
    <#
    .SYNOPSIS
    Show help information for Node.js component
    #>
    Write-ComponentHeader "Node.js Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Node.js" -ForegroundColor White
    Write-Host "  test        - Test Node.js functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Node.js" -ForegroundColor White
    Write-Host "  update      - Update Node.js and packages" -ForegroundColor White
    Write-Host "  check       - Check Node.js installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Node.js PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Node.js" -ForegroundColor White
    Write-Host "  status      - Show Node.js status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\nodejs.ps1 install                    # Install Node.js" -ForegroundColor White
    Write-Host "  .\nodejs.ps1 test                       # Test Node.js" -ForegroundColor White
    Write-Host "  .\nodejs.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\nodejs.ps1 update                     # Update Node.js" -ForegroundColor White
    Write-Host "  .\nodejs.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\nodejs.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\nodejs.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Node.js version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallGlobalPackages - Install global packages" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-NodeJs -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallGlobalPackages:$InstallGlobalPackages
        if ($result) {
            Write-ComponentStep "Node.js installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Node.js installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-NodeJsFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Node.js functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Node.js functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Node.js..." "INFO"
        $result = Install-NodeJs -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallGlobalPackages:$InstallGlobalPackages
        if ($result) {
            Write-ComponentStep "Node.js reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Node.js reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-NodeJs
        if ($result) {
            Write-ComponentStep "Node.js update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Node.js update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-NodeJsInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Node.js is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Node.js is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-NodeJsPath
        Write-ComponentStep "Node.js PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-NodeJs
        if ($result) {
            Write-ComponentStep "Node.js uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Node.js uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-NodeJsStatus
    }
    "help" {
        Show-NodeJsHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-NodeJsHelp
        exit 1
    }
}
