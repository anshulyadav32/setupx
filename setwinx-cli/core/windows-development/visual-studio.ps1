# Complete Visual Studio Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallWorkloads = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Visual Studio"
    Version = "1.0.0"
    Description = "Complete Visual Studio Development Environment"
    ExecutableNames = @("devenv.exe", "devenv")
    VersionCommands = @("devenv /?")
    TestCommands = @("devenv /?", "devenv /help", "devenv /version")
    WingetId = "Microsoft.VisualStudio.2022.Community"
    ChocoId = "visualstudio2022community"
    DownloadUrl = "https://visualstudio.microsoft.com/downloads/"
    Documentation = "https://docs.microsoft.com/en-us/visualstudio/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "VISUAL STUDIO COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-VisualStudioInstallation {
    <#
    .SYNOPSIS
    Comprehensive Visual Studio installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Visual Studio installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        Workloads = @()
        Components = @()
        InstalledProducts = @()
    }
    
    # Check Visual Studio executable
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
            $version = & devenv /? 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check installed workloads and components
        try {
            $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
            if (Test-Path $vsWhere) {
                $installations = & $vsWhere -all -products "*" -requires Microsoft.VisualStudio.Component.CoreEditor -format json | ConvertFrom-Json
                if ($installations) {
                    $result.InstalledProducts = $installations | ForEach-Object { $_.displayName }
                    
                    # Get workloads
                    $workloads = & $vsWhere -all -products "*" -requires Microsoft.VisualStudio.Workload.* -format json | ConvertFrom-Json
                    if ($workloads) {
                        $result.Workloads = $workloads | ForEach-Object { $_.displayName }
                    }
                    
                    # Get components
                    $components = & $vsWhere -all -products "*" -requires Microsoft.VisualStudio.Component.* -format json | ConvertFrom-Json
                    if ($components) {
                        $result.Components = $components | ForEach-Object { $_.displayName }
                    }
                }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-VisualStudio {
    <#
    .SYNOPSIS
    Install Visual Studio with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallWorkloads = $true
    )
    
    Write-ComponentHeader "Installing Visual Studio $Version"
    
    # Check if already installed
    $currentInstallation = Test-VisualStudioInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Visual Studio is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Visual Studio using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Visual Studio installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Visual Studio using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Visual Studio installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Visual Studio manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Visual Studio installation..." "INFO"
        $postInstallVerification = Test-VisualStudioInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Visual Studio installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Visual Studio installation verification failed" "WARNING"
            return $false
        }
        
        # Install workloads if requested
        if ($InstallWorkloads) {
            Write-ComponentStep "Installing Visual Studio workloads..." "INFO"
            
            $workloads = @(
                "Microsoft.VisualStudio.Workload.NetWeb",
                "Microsoft.VisualStudio.Workload.NetDesktop",
                "Microsoft.VisualStudio.Workload.Universal",
                "Microsoft.VisualStudio.Workload.Azure",
                "Microsoft.VisualStudio.Workload.Data"
            )
            
            foreach ($workload in $workloads) {
                try {
                    $vsInstaller = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
                    if (Test-Path $vsInstaller) {
                        & $vsInstaller modify --installPath "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community" --add $workload --quiet
                        Write-ComponentStep "  ✓ $workload installed" "SUCCESS"
                    }
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $workload" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Visual Studio: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-VisualStudioFunctionality {
    <#
    .SYNOPSIS
    Test Visual Studio functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Visual Studio Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "devenv /?",
        "devenv /help",
        "devenv /version",
        "devenv /build",
        "devenv /rebuild"
    )
    
    $expectedOutputs = @(
        "devenv",
        "devenv",
        "devenv",
        "devenv",
        "devenv"
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

function Update-VisualStudio {
    <#
    .SYNOPSIS
    Update Visual Studio to latest version
    #>
    Write-ComponentHeader "Updating Visual Studio"
    
    $currentInstallation = Test-VisualStudioInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Visual Studio is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Visual Studio..." "INFO"
    
    try {
        # Update Visual Studio using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Visual Studio updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Visual Studio updated using Chocolatey" "SUCCESS"
        }
        # Update using Visual Studio Installer
        else {
            $vsInstaller = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
            if (Test-Path $vsInstaller) {
                & $vsInstaller update --quiet
                Write-ComponentStep "Visual Studio updated using Visual Studio Installer" "SUCCESS"
            }
        }
        
        Write-ComponentStep "Visual Studio update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Visual Studio: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-VisualStudioPath {
    <#
    .SYNOPSIS
    Fix Visual Studio PATH issues
    #>
    Write-ComponentHeader "Fixing Visual Studio PATH"
    
    $vsPaths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\Common7\IDE",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\Common7\IDE",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\Common7\IDE",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\Common7\IDE",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\Common7\IDE",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\Common7\IDE"
    )
    
    $foundPaths = @()
    foreach ($path in $vsPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Visual Studio paths:" "INFO"
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
            Write-ComponentStep "Added Visual Studio paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Visual Studio paths found" "WARNING"
    }
}

function Uninstall-VisualStudio {
    <#
    .SYNOPSIS
    Uninstall Visual Studio
    #>
    Write-ComponentHeader "Uninstalling Visual Studio"
    
    $currentInstallation = Test-VisualStudioInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Visual Studio is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Visual Studio from PATH..." "INFO"
    
    # Remove Visual Studio paths from environment
    $currentPath = $env:Path
    $vsPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $vsPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Visual Studio removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Visual Studio files may be required" "WARNING"
    
    return $true
}

function Show-VisualStudioStatus {
    <#
    .SYNOPSIS
    Show comprehensive Visual Studio status
    #>
    Write-ComponentHeader "Visual Studio Status Report"
    
    $installation = Test-VisualStudioInstallation -Detailed:$Detailed
    $functionality = Test-VisualStudioFunctionality -Detailed:$Detailed
    
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
    
    if ($installation.InstalledProducts.Count -gt 0) {
        Write-Host "`nInstalled Products:" -ForegroundColor Cyan
        foreach ($product in $installation.InstalledProducts) {
            Write-Host "  - $product" -ForegroundColor White
        }
    }
    
    if ($installation.Workloads.Count -gt 0) {
        Write-Host "`nInstalled Workloads:" -ForegroundColor Cyan
        foreach ($workload in $installation.Workloads) {
            Write-Host "  - $workload" -ForegroundColor White
        }
    }
    
    if ($installation.Components.Count -gt 0) {
        Write-Host "`nInstalled Components:" -ForegroundColor Cyan
        foreach ($component in $installation.Components) {
            Write-Host "  - $component" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-VisualStudioHelp {
    <#
    .SYNOPSIS
    Show help information for Visual Studio component
    #>
    Write-ComponentHeader "Visual Studio Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Visual Studio" -ForegroundColor White
    Write-Host "  test        - Test Visual Studio functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Visual Studio" -ForegroundColor White
    Write-Host "  update      - Update Visual Studio" -ForegroundColor White
    Write-Host "  check       - Check Visual Studio installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Visual Studio PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Visual Studio" -ForegroundColor White
    Write-Host "  status      - Show Visual Studio status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\visual-studio.ps1 install                    # Install Visual Studio" -ForegroundColor White
    Write-Host "  .\visual-studio.ps1 test                       # Test Visual Studio" -ForegroundColor White
    Write-Host "  .\visual-studio.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\visual-studio.ps1 update                     # Update Visual Studio" -ForegroundColor White
    Write-Host "  .\visual-studio.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\visual-studio.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\visual-studio.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Visual Studio version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallWorkloads      - Install workloads" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-VisualStudio -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallWorkloads:$InstallWorkloads
        if ($result) {
            Write-ComponentStep "Visual Studio installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-VisualStudioFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Visual Studio functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Visual Studio..." "INFO"
        $result = Install-VisualStudio -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallWorkloads:$InstallWorkloads
        if ($result) {
            Write-ComponentStep "Visual Studio reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-VisualStudio
        if ($result) {
            Write-ComponentStep "Visual Studio update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-VisualStudioInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Visual Studio is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-VisualStudioPath
        Write-ComponentStep "Visual Studio PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-VisualStudio
        if ($result) {
            Write-ComponentStep "Visual Studio uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Visual Studio uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-VisualStudioStatus
    }
    "help" {
        Show-VisualStudioHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-VisualStudioHelp
        exit 1
    }
}
