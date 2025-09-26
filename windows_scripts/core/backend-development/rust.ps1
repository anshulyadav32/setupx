# Complete Rust Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallCargo = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Rust"
    Version = "1.0.0"
    Description = "Complete Rust Programming Language Environment"
    ExecutableNames = @("rustc.exe", "rustc", "cargo.exe", "cargo")
    VersionCommands = @("rustc --version", "cargo --version")
    TestCommands = @("rustc --version", "cargo --version", "rustc --help")
    WingetId = "Rustlang.Rust.MSVC"
    ChocoId = "rust"
    DownloadUrl = "https://rustup.rs/"
    Documentation = "https://doc.rust-lang.org/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "RUST COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-RustInstallation {
    <#
    .SYNOPSIS
    Comprehensive Rust installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Rust installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        RustcVersion = "Unknown"
        CargoVersion = "Unknown"
        CargoAvailable = $false
        RustupAvailable = $false
        RustupVersion = "Unknown"
    }
    
    # Check Rust executable
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
            $version = & rustc --version 2>$null
            if ($version) {
                $result.Version = $version
                $result.RustcVersion = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check cargo availability
        $result.CargoAvailable = (Get-Command cargo -ErrorAction SilentlyContinue) -ne $null
        if ($result.CargoAvailable) {
            try {
                $cargoVersion = & cargo --version 2>$null
                if ($cargoVersion) {
                    $result.CargoVersion = $cargoVersion
                }
            } catch {
                $result.CargoVersion = "Unknown"
            }
        }
        
        # Check rustup availability
        $result.RustupAvailable = (Get-Command rustup -ErrorAction SilentlyContinue) -ne $null
        if ($result.RustupAvailable) {
            try {
                $rustupVersion = & rustup --version 2>$null
                if ($rustupVersion) {
                    $result.RustupVersion = $rustupVersion
                }
            } catch {
                $result.RustupVersion = "Unknown"
            }
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Rust {
    <#
    .SYNOPSIS
    Install Rust with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallCargo = $true
    )
    
    Write-ComponentHeader "Installing Rust $Version"
    
    # Check if already installed
    $currentInstallation = Test-RustInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Rust is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Rust using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Rust installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Rust using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Rust installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation using rustup
        else {
            Write-ComponentStep "Installing Rust using rustup..." "INFO"
            
            # Download and run rustup installer
            $rustupUrl = "https://win.rustup.rs/x86_64"
            $rustupInstaller = "$env:TEMP\rustup-init.exe"
            
            try {
                Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupInstaller
                Write-ComponentStep "Downloaded rustup installer" "SUCCESS"
                
                # Run rustup installer
                $process = Start-Process -FilePath $rustupInstaller -ArgumentList "-y" -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    Write-ComponentStep "Rust installed successfully using rustup!" "SUCCESS"
                } else {
                    throw "Rustup installation failed"
                }
            } finally {
                if (Test-Path $rustupInstaller) {
                    Remove-Item $rustupInstaller -Force
                }
            }
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Rust installation..." "INFO"
        $postInstallVerification = Test-RustInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Rust installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Rust installation verification failed" "WARNING"
            return $false
        }
        
        # Install Rust tools if requested
        if ($InstallCargo) {
            Write-ComponentStep "Installing Rust development tools..." "INFO"
            
            $tools = @(
                "rustfmt",
                "clippy",
                "rust-analyzer",
                "cargo-edit",
                "cargo-watch",
                "cargo-expand",
                "cargo-audit",
                "cargo-outdated",
                "cargo-tree",
                "cargo-udeps"
            )
            
            foreach ($tool in $tools) {
                try {
                    cargo install $tool
                    Write-ComponentStep "  ✓ $tool installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $tool" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Rust: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-RustFunctionality {
    <#
    .SYNOPSIS
    Test Rust functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Rust Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "rustc --version",
        "cargo --version",
        "rustc --help",
        "cargo --help",
        "rustup --version"
    )
    
    $expectedOutputs = @(
        "rustc",
        "cargo",
        "rustc",
        "cargo",
        "rustup"
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

function Update-Rust {
    <#
    .SYNOPSIS
    Update Rust to latest version
    #>
    Write-ComponentHeader "Updating Rust"
    
    $currentInstallation = Test-RustInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Rust is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Rust..." "INFO"
    
    try {
        # Update Rust using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Rust updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Rust updated using Chocolatey" "SUCCESS"
        }
        # Update using rustup
        elseif (Get-Command rustup -ErrorAction SilentlyContinue) {
            rustup update
            Write-ComponentStep "Rust updated using rustup" "SUCCESS"
        }
        
        # Update Rust tools
        cargo install --list | ForEach-Object { if ($_ -match "^\w+") { cargo install $_.Split()[0] } }
        Write-ComponentStep "Rust tools updated" "SUCCESS"
        
        Write-ComponentStep "Rust update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Rust: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-RustPath {
    <#
    .SYNOPSIS
    Fix Rust PATH issues
    #>
    Write-ComponentHeader "Fixing Rust PATH"
    
    $rustPaths = @(
        "${env:USERPROFILE}\.cargo\bin",
        "${env:ProgramFiles}\Rust\bin",
        "${env:ProgramFiles(x86)}\Rust\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $rustPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Rust paths:" "INFO"
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
            Write-ComponentStep "Added Rust paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Rust paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Rust paths found" "WARNING"
    }
}

function Uninstall-Rust {
    <#
    .SYNOPSIS
    Uninstall Rust
    #>
    Write-ComponentHeader "Uninstalling Rust"
    
    $currentInstallation = Test-RustInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Rust is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Rust from PATH..." "INFO"
    
    # Remove Rust paths from environment
    $currentPath = $env:Path
    $rustPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $rustPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Rust removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Rust files may be required" "WARNING"
    
    return $true
}

function Show-RustStatus {
    <#
    .SYNOPSIS
    Show comprehensive Rust status
    #>
    Write-ComponentHeader "Rust Status Report"
    
    $installation = Test-RustInstallation -Detailed:$Detailed
    $functionality = Test-RustFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Rustc Version: $($installation.RustcVersion)" -ForegroundColor White
    Write-Host "  Cargo Version: $($installation.CargoVersion)" -ForegroundColor White
    Write-Host "  Cargo Available: $(if ($installation.CargoAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Rustup Available: $(if ($installation.RustupAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Rustup Version: $($installation.RustupVersion)" -ForegroundColor White
    
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

function Show-RustHelp {
    <#
    .SYNOPSIS
    Show help information for Rust component
    #>
    Write-ComponentHeader "Rust Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Rust" -ForegroundColor White
    Write-Host "  test        - Test Rust functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Rust" -ForegroundColor White
    Write-Host "  update      - Update Rust and tools" -ForegroundColor White
    Write-Host "  check       - Check Rust installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Rust PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Rust" -ForegroundColor White
    Write-Host "  status      - Show Rust status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\rust.ps1 install                    # Install Rust" -ForegroundColor White
    Write-Host "  .\rust.ps1 test                       # Test Rust" -ForegroundColor White
    Write-Host "  .\rust.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\rust.ps1 update                     # Update Rust" -ForegroundColor White
    Write-Host "  .\rust.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\rust.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\rust.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Rust version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallCargo          - Install Cargo" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Rust -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallCargo:$InstallCargo
        if ($result) {
            Write-ComponentStep "Rust installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Rust installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-RustFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Rust functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Rust functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Rust..." "INFO"
        $result = Install-Rust -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallCargo:$InstallCargo
        if ($result) {
            Write-ComponentStep "Rust reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Rust reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Rust
        if ($result) {
            Write-ComponentStep "Rust update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Rust update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-RustInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Rust is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Rust is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-RustPath
        Write-ComponentStep "Rust PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Rust
        if ($result) {
            Write-ComponentStep "Rust uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Rust uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-RustStatus
    }
    "help" {
        Show-RustHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-RustHelp
        exit 1
    }
}
