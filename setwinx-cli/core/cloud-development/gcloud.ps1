# Complete Google Cloud CLI Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$ConfigureCredentials = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Google Cloud CLI"
    Version = "1.0.0"
    Description = "Complete Google Cloud Command Line Interface"
    ExecutableNames = @("gcloud.exe", "gcloud")
    VersionCommands = @("gcloud --version")
    TestCommands = @("gcloud --version", "gcloud --help", "gcloud auth list")
    WingetId = "Google.CloudSDK"
    ChocoId = "google-cloud-sdk"
    DownloadUrl = "https://cloud.google.com/sdk/docs/install"
    Documentation = "https://cloud.google.com/sdk/docs"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "GOOGLE CLOUD CLI COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-GcloudInstallation {
    <#
    .SYNOPSIS
    Comprehensive Google Cloud CLI installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Google Cloud CLI installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        Configured = $false
        Authenticated = $false
        AccountInfo = ""
        DefaultProject = ""
    }
    
    # Check Google Cloud CLI executable
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
            $version = & gcloud --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check authentication status
        try {
            $auth = & gcloud auth list 2>$null
            if ($auth) {
                $result.Configured = $true
                $result.Authenticated = ($auth | Where-Object { $_ -match "ACTIVE" }) -ne $null
                $result.AccountInfo = $auth
            }
        } catch {
            # Continue without error
        }
        
        # Get default project
        try {
            $project = & gcloud config get-value project 2>$null
            if ($project) {
                $result.DefaultProject = $project
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Gcloud {
    <#
    .SYNOPSIS
    Install Google Cloud CLI with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$ConfigureCredentials = $true
    )
    
    Write-ComponentHeader "Installing Google Cloud CLI $Version"
    
    # Check if already installed
    $currentInstallation = Test-GcloudInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Google Cloud CLI is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Google Cloud CLI using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Google Cloud CLI installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Google Cloud CLI using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Google Cloud CLI installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Google Cloud CLI manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Google Cloud CLI installation..." "INFO"
        $postInstallVerification = Test-GcloudInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Google Cloud CLI installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Google Cloud CLI installation verification failed" "WARNING"
            return $false
        }
        
        # Configure credentials if requested
        if ($ConfigureCredentials) {
            Write-ComponentStep "Configuring Google Cloud CLI..." "INFO"
            Write-ComponentStep "Please run 'gcloud auth login' to authenticate with Google Cloud" "INFO"
            Write-ComponentStep "You can also use 'gcloud auth application-default login' for application authentication" "INFO"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Google Cloud CLI: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-GcloudFunctionality {
    <#
    .SYNOPSIS
    Test Google Cloud CLI functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Google Cloud CLI Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "gcloud --version",
        "gcloud --help",
        "gcloud auth list",
        "gcloud config list",
        "gcloud projects list"
    )
    
    $expectedOutputs = @(
        "Google Cloud SDK",
        "gcloud",
        "gcloud auth",
        "gcloud config",
        "gcloud projects"
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

function Update-Gcloud {
    <#
    .SYNOPSIS
    Update Google Cloud CLI to latest version
    #>
    Write-ComponentHeader "Updating Google Cloud CLI"
    
    $currentInstallation = Test-GcloudInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Google Cloud CLI is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Google Cloud CLI..." "INFO"
    
    try {
        # Update Google Cloud CLI using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Google Cloud CLI updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Google Cloud CLI updated using Chocolatey" "SUCCESS"
        }
        # Update using gcloud
        elseif (Get-Command gcloud -ErrorAction SilentlyContinue) {
            gcloud components update
            Write-ComponentStep "Google Cloud CLI updated using gcloud" "SUCCESS"
        }
        
        Write-ComponentStep "Google Cloud CLI update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Google Cloud CLI: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-GcloudPath {
    <#
    .SYNOPSIS
    Fix Google Cloud CLI PATH issues
    #>
    Write-ComponentHeader "Fixing Google Cloud CLI PATH"
    
    $gcloudPaths = @(
        "${env:ProgramFiles}\Google\Cloud SDK\google-cloud-sdk\bin",
        "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin",
        "${env:LOCALAPPDATA}\Google\Cloud SDK\google-cloud-sdk\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $gcloudPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Google Cloud CLI paths:" "INFO"
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
            Write-ComponentStep "Added Google Cloud CLI paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Google Cloud CLI paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Google Cloud CLI paths found" "WARNING"
    }
}

function Uninstall-Gcloud {
    <#
    .SYNOPSIS
    Uninstall Google Cloud CLI
    #>
    Write-ComponentHeader "Uninstalling Google Cloud CLI"
    
    $currentInstallation = Test-GcloudInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Google Cloud CLI is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Google Cloud CLI from PATH..." "INFO"
    
    # Remove Google Cloud CLI paths from environment
    $currentPath = $env:Path
    $gcloudPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $gcloudPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Google Cloud CLI removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Google Cloud CLI files may be required" "WARNING"
    
    return $true
}

function Show-GcloudStatus {
    <#
    .SYNOPSIS
    Show comprehensive Google Cloud CLI status
    #>
    Write-ComponentHeader "Google Cloud CLI Status Report"
    
    $installation = Test-GcloudInstallation -Detailed:$Detailed
    $functionality = Test-GcloudFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Configured: $(if ($installation.Configured) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Authenticated: $(if ($installation.Authenticated) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Default Project: $($installation.DefaultProject)" -ForegroundColor White
    
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

function Show-GcloudHelp {
    <#
    .SYNOPSIS
    Show help information for Google Cloud CLI component
    #>
    Write-ComponentHeader "Google Cloud CLI Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Google Cloud CLI" -ForegroundColor White
    Write-Host "  test        - Test Google Cloud CLI functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Google Cloud CLI" -ForegroundColor White
    Write-Host "  update      - Update Google Cloud CLI" -ForegroundColor White
    Write-Host "  check       - Check Google Cloud CLI installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Google Cloud CLI PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Google Cloud CLI" -ForegroundColor White
    Write-Host "  status      - Show Google Cloud CLI status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\gcloud.ps1 install                    # Install Google Cloud CLI" -ForegroundColor White
    Write-Host "  .\gcloud.ps1 test                       # Test Google Cloud CLI" -ForegroundColor White
    Write-Host "  .\gcloud.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\gcloud.ps1 update                     # Update Google Cloud CLI" -ForegroundColor White
    Write-Host "  .\gcloud.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\gcloud.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\gcloud.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Google Cloud CLI version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -ConfigureCredentials   - Configure credentials" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Gcloud -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -ConfigureCredentials:$ConfigureCredentials
        if ($result) {
            Write-ComponentStep "Google Cloud CLI installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Google Cloud CLI installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-GcloudFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Google Cloud CLI functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Google Cloud CLI functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Google Cloud CLI..." "INFO"
        $result = Install-Gcloud -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -ConfigureCredentials:$ConfigureCredentials
        if ($result) {
            Write-ComponentStep "Google Cloud CLI reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Google Cloud CLI reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Gcloud
        if ($result) {
            Write-ComponentStep "Google Cloud CLI update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Google Cloud CLI update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-GcloudInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Google Cloud CLI is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Google Cloud CLI is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-GcloudPath
        Write-ComponentStep "Google Cloud CLI PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Gcloud
        if ($result) {
            Write-ComponentStep "Google Cloud CLI uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Google Cloud CLI uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-GcloudStatus
    }
    "help" {
        Show-GcloudHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-GcloudHelp
        exit 1
    }
}
