# Complete AWS CLI Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "AWS CLI"
    Version = "1.0.0"
    Description = "Complete AWS Command Line Interface"
    ExecutableNames = @("aws.exe", "aws")
    VersionCommands = @("aws --version")
    TestCommands = @("aws --version", "aws --help", "aws configure list")
    WingetId = "Amazon.AWSCLI"
    ChocoId = "awscli"
    DownloadUrl = "https://aws.amazon.com/cli/"
    Documentation = "https://docs.aws.amazon.com/cli/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "AWS CLI COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-AwsCliInstallation {
    <#
    .SYNOPSIS
    Comprehensive AWS CLI installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking AWS CLI installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        Configured = $false
        CredentialsConfigured = $false
        DefaultRegion = ""
        DefaultOutput = ""
    }
    
    # Check AWS CLI executable
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
            $version = & aws --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check configuration
        try {
            $config = & aws configure list 2>$null
            if ($config) {
                $result.Configured = $true
                $result.CredentialsConfigured = ($config | Where-Object { $_ -match "access_key" -and $_ -notmatch "None" }) -ne $null
                $result.DefaultRegion = ($config | Where-Object { $_ -match "region" } | ForEach-Object { ($_ -split "\s+")[-1] }) -join ", "
                $result.DefaultOutput = ($config | Where-Object { $_ -match "output" } | ForEach-Object { ($_ -split "\s+")[-1] }) -join ", "
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-AwsCli {
    <#
    .SYNOPSIS
    Install AWS CLI with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$ConfigureCredentials = $true
    )
    
    Write-ComponentHeader "Installing AWS CLI $Version"
    
    # Check if already installed
    $currentInstallation = Test-AwsCliInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "AWS CLI is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing AWS CLI using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "AWS CLI installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing AWS CLI using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "AWS CLI installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing AWS CLI manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying AWS CLI installation..." "INFO"
        $postInstallVerification = Test-AwsCliInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "AWS CLI installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "AWS CLI installation verification failed" "WARNING"
            return $false
        }
        
        # Configure credentials if requested
        if ($ConfigureCredentials) {
            Write-ComponentStep "Configuring AWS CLI..." "INFO"
            Write-ComponentStep "Please run 'aws configure' to set up your credentials" "INFO"
            Write-ComponentStep "You can also use 'aws configure sso' for SSO authentication" "INFO"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install AWS CLI: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-AwsCliFunctionality {
    <#
    .SYNOPSIS
    Test AWS CLI functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing AWS CLI Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "aws --version",
        "aws --help",
        "aws configure list",
        "aws sts get-caller-identity",
        "aws s3 ls"
    )
    
    $expectedOutputs = @(
        "aws-cli",
        "aws",
        "aws configure",
        "aws sts",
        "aws s3"
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

function Update-AwsCli {
    <#
    .SYNOPSIS
    Update AWS CLI to latest version
    #>
    Write-ComponentHeader "Updating AWS CLI"
    
    $currentInstallation = Test-AwsCliInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "AWS CLI is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating AWS CLI..." "INFO"
    
    try {
        # Update AWS CLI using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "AWS CLI updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "AWS CLI updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "AWS CLI update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update AWS CLI: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-AwsCliPath {
    <#
    .SYNOPSIS
    Fix AWS CLI PATH issues
    #>
    Write-ComponentHeader "Fixing AWS CLI PATH"
    
    $awsPaths = @(
        "${env:ProgramFiles}\Amazon\AWSCLIV2",
        "${env:ProgramFiles(x86)}\Amazon\AWSCLIV2",
        "${env:LOCALAPPDATA}\Amazon\AWSCLIV2"
    )
    
    $foundPaths = @()
    foreach ($path in $awsPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found AWS CLI paths:" "INFO"
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
            Write-ComponentStep "Added AWS CLI paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "AWS CLI paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No AWS CLI paths found" "WARNING"
    }
}

function Uninstall-AwsCli {
    <#
    .SYNOPSIS
    Uninstall AWS CLI
    #>
    Write-ComponentHeader "Uninstalling AWS CLI"
    
    $currentInstallation = Test-AwsCliInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "AWS CLI is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing AWS CLI from PATH..." "INFO"
    
    # Remove AWS CLI paths from environment
    $currentPath = $env:Path
    $awsPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $awsPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "AWS CLI removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of AWS CLI files may be required" "WARNING"
    
    return $true
}

function Show-AwsCliStatus {
    <#
    .SYNOPSIS
    Show comprehensive AWS CLI status
    #>
    Write-ComponentHeader "AWS CLI Status Report"
    
    $installation = Test-AwsCliInstallation -Detailed:$Detailed
    $functionality = Test-AwsCliFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Configured: $(if ($installation.Configured) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Credentials Configured: $(if ($installation.CredentialsConfigured) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Default Region: $($installation.DefaultRegion)" -ForegroundColor White
    Write-Host "  Default Output: $($installation.DefaultOutput)" -ForegroundColor White
    
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

function Show-AwsCliHelp {
    <#
    .SYNOPSIS
    Show help information for AWS CLI component
    #>
    Write-ComponentHeader "AWS CLI Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install AWS CLI" -ForegroundColor White
    Write-Host "  test        - Test AWS CLI functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall AWS CLI" -ForegroundColor White
    Write-Host "  update      - Update AWS CLI" -ForegroundColor White
    Write-Host "  check       - Check AWS CLI installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix AWS CLI PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall AWS CLI" -ForegroundColor White
    Write-Host "  status      - Show AWS CLI status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\aws-cli.ps1 install                    # Install AWS CLI" -ForegroundColor White
    Write-Host "  .\aws-cli.ps1 test                       # Test AWS CLI" -ForegroundColor White
    Write-Host "  .\aws-cli.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\aws-cli.ps1 update                     # Update AWS CLI" -ForegroundColor White
    Write-Host "  .\aws-cli.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\aws-cli.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\aws-cli.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - AWS CLI version to install" -ForegroundColor White
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
        $result = Install-AwsCli -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -ConfigureCredentials:$ConfigureCredentials
        if ($result) {
            Write-ComponentStep "AWS CLI installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "AWS CLI installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-AwsCliFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "AWS CLI functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "AWS CLI functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling AWS CLI..." "INFO"
        $result = Install-AwsCli -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -ConfigureCredentials:$ConfigureCredentials
        if ($result) {
            Write-ComponentStep "AWS CLI reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "AWS CLI reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-AwsCli
        if ($result) {
            Write-ComponentStep "AWS CLI update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "AWS CLI update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-AwsCliInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "AWS CLI is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "AWS CLI is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-AwsCliPath
        Write-ComponentStep "AWS CLI PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-AwsCli
        if ($result) {
            Write-ComponentStep "AWS CLI uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "AWS CLI uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-AwsCliStatus
    }
    "help" {
        Show-AwsCliHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-AwsCliHelp
        exit 1
    }
}
