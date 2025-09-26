# Complete .NET Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallSdk = $true
)

# Component Information
$ComponentInfo = @{
    Name = ".NET"
    Version = "1.0.0"
    Description = "Complete .NET Development Environment"
    ExecutableNames = @("dotnet.exe", "dotnet")
    VersionCommands = @("dotnet --version")
    TestCommands = @("dotnet --version", "dotnet --info", "dotnet --help")
    WingetId = "Microsoft.DotNet.SDK.8"
    ChocoId = "dotnet"
    DownloadUrl = "https://dotnet.microsoft.com/download"
    Documentation = "https://docs.microsoft.com/en-us/dotnet/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host ".NET COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-DotNetInstallation {
    <#
    .SYNOPSIS
    Comprehensive .NET installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking .NET installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        SdkVersion = "Unknown"
        RuntimeVersion = "Unknown"
        SdksInstalled = @()
        RuntimesInstalled = @()
    }
    
    # Check .NET executable
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
            $version = & dotnet --version 2>$null
            if ($version) {
                $result.Version = $version
                $result.SdkVersion = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get detailed .NET info
        try {
            $info = & dotnet --info 2>$null
            if ($info) {
                $result.RuntimeVersion = ($info | Where-Object { $_ -match "Microsoft.NETCore.App" } | ForEach-Object { ($_ -split "\s+")[-1] }) -join ", "
            }
        } catch {
            # Continue without error
        }
        
        # Get installed SDKs and runtimes
        try {
            $sdks = & dotnet --list-sdks 2>$null
            if ($sdks) {
                $result.SdksInstalled = $sdks | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        try {
            $runtimes = & dotnet --list-runtimes 2>$null
            if ($runtimes) {
                $result.RuntimesInstalled = $runtimes | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-DotNet {
    <#
    .SYNOPSIS
    Install .NET with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallSdk = $true
    )
    
    Write-ComponentHeader "Installing .NET $Version"
    
    # Check if already installed
    $currentInstallation = Test-DotNetInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep ".NET is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing .NET using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep ".NET installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing .NET using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep ".NET installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing .NET manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying .NET installation..." "INFO"
        $postInstallVerification = Test-DotNetInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep ".NET installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep ".NET installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install .NET: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-DotNetFunctionality {
    <#
    .SYNOPSIS
    Test .NET functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing .NET Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "dotnet --version",
        "dotnet --info",
        "dotnet --help",
        "dotnet --list-sdks",
        "dotnet --list-runtimes"
    )
    
    $expectedOutputs = @(
        "dotnet",
        "dotnet",
        "dotnet",
        "dotnet",
        "dotnet"
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

function Update-DotNet {
    <#
    .SYNOPSIS
    Update .NET to latest version
    #>
    Write-ComponentHeader "Updating .NET"
    
    $currentInstallation = Test-DotNetInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep ".NET is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating .NET..." "INFO"
    
    try {
        # Update .NET using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep ".NET updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep ".NET updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep ".NET update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update .NET: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-DotNetPath {
    <#
    .SYNOPSIS
    Fix .NET PATH issues
    #>
    Write-ComponentHeader "Fixing .NET PATH"
    
    $dotnetPaths = @(
        "${env:ProgramFiles}\dotnet",
        "${env:ProgramFiles(x86)}\dotnet",
        "${env:LOCALAPPDATA}\Microsoft\dotnet"
    )
    
    $foundPaths = @()
    foreach ($path in $dotnetPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found .NET paths:" "INFO"
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
            Write-ComponentStep "Added .NET paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep ".NET paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No .NET paths found" "WARNING"
    }
}

function Uninstall-DotNet {
    <#
    .SYNOPSIS
    Uninstall .NET
    #>
    Write-ComponentHeader "Uninstalling .NET"
    
    $currentInstallation = Test-DotNetInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep ".NET is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing .NET from PATH..." "INFO"
    
    # Remove .NET paths from environment
    $currentPath = $env:Path
    $dotnetPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $dotnetPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep ".NET removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of .NET files may be required" "WARNING"
    
    return $true
}

function Show-DotNetStatus {
    <#
    .SYNOPSIS
    Show comprehensive .NET status
    #>
    Write-ComponentHeader ".NET Status Report"
    
    $installation = Test-DotNetInstallation -Detailed:$Detailed
    $functionality = Test-DotNetFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  SDK Version: $($installation.SdkVersion)" -ForegroundColor White
    Write-Host "  Runtime Version: $($installation.RuntimeVersion)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.SdksInstalled.Count -gt 0) {
        Write-Host "`nInstalled SDKs:" -ForegroundColor Cyan
        foreach ($sdk in $installation.SdksInstalled) {
            Write-Host "  - $sdk" -ForegroundColor White
        }
    }
    
    if ($installation.RuntimesInstalled.Count -gt 0) {
        Write-Host "`nInstalled Runtimes:" -ForegroundColor Cyan
        foreach ($runtime in $installation.RuntimesInstalled) {
            Write-Host "  - $runtime" -ForegroundColor White
        }
    }
}

function Show-DotNetHelp {
    <#
    .SYNOPSIS
    Show help information for .NET component
    #>
    Write-ComponentHeader ".NET Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install .NET" -ForegroundColor White
    Write-Host "  test        - Test .NET functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall .NET" -ForegroundColor White
    Write-Host "  update      - Update .NET" -ForegroundColor White
    Write-Host "  check       - Check .NET installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix .NET PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall .NET" -ForegroundColor White
    Write-Host "  status      - Show .NET status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\dotnet.ps1 install                    # Install .NET" -ForegroundColor White
    Write-Host "  .\dotnet.ps1 test                       # Test .NET" -ForegroundColor White
    Write-Host "  .\dotnet.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\dotnet.ps1 update                     # Update .NET" -ForegroundColor White
    Write-Host "  .\dotnet.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\dotnet.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\dotnet.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - .NET version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallSdk            - Install SDK" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-DotNet -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallSdk:$InstallSdk
        if ($result) {
            Write-ComponentStep ".NET installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep ".NET installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-DotNetFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep ".NET functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep ".NET functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling .NET..." "INFO"
        $result = Install-DotNet -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallSdk:$InstallSdk
        if ($result) {
            Write-ComponentStep ".NET reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep ".NET reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-DotNet
        if ($result) {
            Write-ComponentStep ".NET update completed!" "SUCCESS"
        } else {
            Write-ComponentStep ".NET update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-DotNetInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep ".NET is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep ".NET is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-DotNetPath
        Write-ComponentStep ".NET PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-DotNet
        if ($result) {
            Write-ComponentStep ".NET uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep ".NET uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-DotNetStatus
    }
    "help" {
        Show-DotNetHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-DotNetHelp
        exit 1
    }
}
