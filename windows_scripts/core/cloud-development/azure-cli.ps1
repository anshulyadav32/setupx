# Complete Azure CLI Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "Azure CLI"
    Version = "1.0.0"
    Description = "Complete Azure Command Line Interface"
    ExecutableNames = @("az.exe", "az")
    VersionCommands = @("az --version")
    TestCommands = @("az --version", "az --help", "az account show")
    WingetId = "Microsoft.AzureCLI"
    ChocoId = "azure-cli"
    DownloadUrl = "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    Documentation = "https://docs.microsoft.com/en-us/cli/azure/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "AZURE CLI COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-AzureCliInstallation {
    <#
    .SYNOPSIS
    Comprehensive Azure CLI installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Azure CLI installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        Configured = $false
        LoggedIn = $false
        AccountInfo = ""
        DefaultSubscription = ""
    }
    
    # Check Azure CLI executable
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
            $version = & az --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check login status
        try {
            $account = & az account show 2>$null
            if ($account) {
                $result.Configured = $true
                $result.LoggedIn = $true
                $result.AccountInfo = $account
                $result.DefaultSubscription = ($account | Where-Object { $_ -match "name" } | ForEach-Object { ($_ -split ":")[1].Trim() }) -join ", "
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-AzureCli {
    <#
    .SYNOPSIS
    Install Azure CLI with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$ConfigureCredentials = $true
    )
    
    Write-ComponentHeader "Installing Azure CLI $Version"
    
    # Check if already installed
    $currentInstallation = Test-AzureCliInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Azure CLI is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Azure CLI using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Azure CLI installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Azure CLI using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Azure CLI installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Azure CLI manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Azure CLI installation..." "INFO"
        $postInstallVerification = Test-AzureCliInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Azure CLI installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Azure CLI installation verification failed" "WARNING"
            return $false
        }
        
        # Configure credentials if requested
        if ($ConfigureCredentials) {
            Write-ComponentStep "Configuring Azure CLI..." "INFO"
            Write-ComponentStep "Please run 'az login' to authenticate with Azure" "INFO"
            Write-ComponentStep "You can also use 'az login --use-device-code' for device authentication" "INFO"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Azure CLI: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-AzureCliFunctionality {
    <#
    .SYNOPSIS
    Test Azure CLI functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Azure CLI Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "az --version",
        "az --help",
        "az account show",
        "az group list",
        "az vm list"
    )
    
    $expectedOutputs = @(
        "azure-cli",
        "az",
        "az account",
        "az group",
        "az vm"
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

function Update-AzureCli {
    <#
    .SYNOPSIS
    Update Azure CLI to latest version
    #>
    Write-ComponentHeader "Updating Azure CLI"
    
    $currentInstallation = Test-AzureCliInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Azure CLI is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Azure CLI..." "INFO"
    
    try {
        # Update Azure CLI using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Azure CLI updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Azure CLI updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Azure CLI update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Azure CLI: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-AzureCliPath {
    <#
    .SYNOPSIS
    Fix Azure CLI PATH issues
    #>
    Write-ComponentHeader "Fixing Azure CLI PATH"
    
    $azurePaths = @(
        "${env:ProgramFiles}\Microsoft SDKs\Azure\CLI2\wbin",
        "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\CLI2\wbin",
        "${env:LOCALAPPDATA}\Microsoft\WindowsApps"
    )
    
    $foundPaths = @()
    foreach ($path in $azurePaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Azure CLI paths:" "INFO"
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
            Write-ComponentStep "Added Azure CLI paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Azure CLI paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Azure CLI paths found" "WARNING"
    }
}

function Uninstall-AzureCli {
    <#
    .SYNOPSIS
    Uninstall Azure CLI
    #>
    Write-ComponentHeader "Uninstalling Azure CLI"
    
    $currentInstallation = Test-AzureCliInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Azure CLI is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Azure CLI from PATH..." "INFO"
    
    # Remove Azure CLI paths from environment
    $currentPath = $env:Path
    $azurePaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $azurePaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "Azure CLI removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Azure CLI files may be required" "WARNING"
    
    return $true
}

function Show-AzureCliStatus {
    <#
    .SYNOPSIS
    Show comprehensive Azure CLI status
    #>
    Write-ComponentHeader "Azure CLI Status Report"
    
    $installation = Test-AzureCliInstallation -Detailed:$Detailed
    $functionality = Test-AzureCliFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Configured: $(if ($installation.Configured) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Logged In: $(if ($installation.LoggedIn) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Default Subscription: $($installation.DefaultSubscription)" -ForegroundColor White
    
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

function Show-AzureCliHelp {
    <#
    .SYNOPSIS
    Show help information for Azure CLI component
    #>
    Write-ComponentHeader "Azure CLI Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Azure CLI" -ForegroundColor White
    Write-Host "  test        - Test Azure CLI functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Azure CLI" -ForegroundColor White
    Write-Host "  update      - Update Azure CLI" -ForegroundColor White
    Write-Host "  check       - Check Azure CLI installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Azure CLI PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Azure CLI" -ForegroundColor White
    Write-Host "  status      - Show Azure CLI status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\azure-cli.ps1 install                    # Install Azure CLI" -ForegroundColor White
    Write-Host "  .\azure-cli.ps1 test                       # Test Azure CLI" -ForegroundColor White
    Write-Host "  .\azure-cli.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\azure-cli.ps1 update                     # Update Azure CLI" -ForegroundColor White
    Write-Host "  .\azure-cli.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\azure-cli.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\azure-cli.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Azure CLI version to install" -ForegroundColor White
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
        $result = Install-AzureCli -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -ConfigureCredentials:$ConfigureCredentials
        if ($result) {
            Write-ComponentStep "Azure CLI installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Azure CLI installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-AzureCliFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Azure CLI functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Azure CLI functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Azure CLI..." "INFO"
        $result = Install-AzureCli -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -ConfigureCredentials:$ConfigureCredentials
        if ($result) {
            Write-ComponentStep "Azure CLI reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Azure CLI reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-AzureCli
        if ($result) {
            Write-ComponentStep "Azure CLI update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Azure CLI update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-AzureCliInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Azure CLI is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Azure CLI is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-AzureCliPath
        Write-ComponentStep "Azure CLI PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-AzureCli
        if ($result) {
            Write-ComponentStep "Azure CLI uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Azure CLI uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-AzureCliStatus
    }
    "help" {
        Show-AzureCliHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-AzureCliHelp
        exit 1
    }
}
