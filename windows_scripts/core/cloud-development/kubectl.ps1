# Complete kubectl Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$ConfigureKubeconfig = $true
)

# Component Information
$ComponentInfo = @{
    Name = "kubectl"
    Version = "1.0.0"
    Description = "Complete Kubernetes Command Line Interface"
    ExecutableNames = @("kubectl.exe", "kubectl")
    VersionCommands = @("kubectl version --client")
    TestCommands = @("kubectl version --client", "kubectl --help", "kubectl cluster-info")
    WingetId = "Kubernetes.kubectl"
    ChocoId = "kubernetes-cli"
    DownloadUrl = "https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    Documentation = "https://kubernetes.io/docs/reference/kubectl/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "KUBECTL COMPONENT: $Message" -ForegroundColor Cyan
        Write-Host "=" * 60 -ForegroundColor Cyan
    }
}

function Write-ComponentStep {
    param([string]$Message, [string]$Status = "INFO")
    if (-not $Quent) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        switch ($Status) {
            "SUCCESS" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
            "ERROR" { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
            "WARNING" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
            "INFO" { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan }
        }
    }
}

function Test-KubectlInstallation {
    <#
    .SYNOPSIS
    Comprehensive kubectl installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking kubectl installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        Configured = $false
        Connected = $false
        ClusterInfo = ""
        Context = ""
        Namespace = ""
    }
    
    # Check kubectl executable
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
            $version = & kubectl version --client 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check cluster connection
        try {
            $clusterInfo = & kubectl cluster-info 2>$null
            if ($clusterInfo) {
                $result.Configured = $true
                $result.Connected = $true
                $result.ClusterInfo = $clusterInfo
            }
        } catch {
            # Continue without error
        }
        
        # Get current context and namespace
        try {
            $context = & kubectl config current-context 2>$null
            if ($context) {
                $result.Context = $context
            }
        } catch {
            # Continue without error
        }
        
        try {
            $namespace = & kubectl config view --minify --output 'jsonpath={..namespace}' 2>$null
            if ($namespace) {
                $result.Namespace = $namespace
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Kubectl {
    <#
    .SYNOPSIS
    Install kubectl with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$ConfigureKubeconfig = $true
    )
    
    Write-ComponentHeader "Installing kubectl $Version"
    
    # Check if already installed
    $currentInstallation = Test-KubectlInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "kubectl is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing kubectl using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "kubectl installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing kubectl using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "kubectl installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing kubectl manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying kubectl installation..." "INFO"
        $postInstallVerification = Test-KubectlInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "kubectl installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "kubectl installation verification failed" "WARNING"
            return $false
        }
        
        # Configure kubeconfig if requested
        if ($ConfigureKubeconfig) {
            Write-ComponentStep "Configuring kubectl..." "INFO"
            Write-ComponentStep "Please configure your kubeconfig file to connect to a Kubernetes cluster" "INFO"
            Write-ComponentStep "You can use 'kubectl config set-context' to set up contexts" "INFO"
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install kubectl: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-KubectlFunctionality {
    <#
    .SYNOPSIS
    Test kubectl functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing kubectl Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "kubectl version --client",
        "kubectl --help",
        "kubectl cluster-info",
        "kubectl get nodes",
        "kubectl get pods"
    )
    
    $expectedOutputs = @(
        "kubectl",
        "kubectl",
        "kubectl cluster",
        "kubectl get",
        "kubectl get"
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

function Update-Kubectl {
    <#
    .SYNOPSIS
    Update kubectl to latest version
    #>
    Write-ComponentHeader "Updating kubectl"
    
    $currentInstallation = Test-KubectlInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "kubectl is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating kubectl..." "INFO"
    
    try {
        # Update kubectl using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "kubectl updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "kubectl updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "kubectl update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update kubectl: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-KubectlPath {
    <#
    .SYNOPSIS
    Fix kubectl PATH issues
    #>
    Write-ComponentHeader "Fixing kubectl PATH"
    
    $kubectlPaths = @(
        "${env:ProgramFiles}\kubectl",
        "${env:ProgramFiles(x86)}\kubectl",
        "${env:LOCALAPPDATA}\kubectl"
    )
    
    $foundPaths = @()
    foreach ($path in $kubectlPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found kubectl paths:" "INFO"
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
            Write-ComponentStep "Added kubectl paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "kubectl paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No kubectl paths found" "WARNING"
    }
}

function Uninstall-Kubectl {
    <#
    .SYNOPSIS
    Uninstall kubectl
    #>
    Write-ComponentHeader "Uninstalling kubectl"
    
    $currentInstallation = Test-KubectlInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "kubectl is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing kubectl from PATH..." "INFO"
    
    # Remove kubectl paths from environment
    $currentPath = $env:Path
    $kubectlPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $kubectlPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    Write-ComponentStep "kubectl removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of kubectl files may be required" "WARNING"
    
    return $true
}

function Show-KubectlStatus {
    <#
    .SYNOPSIS
    Show comprehensive kubectl status
    #>
    Write-ComponentHeader "kubectl Status Report"
    
    $installation = Test-KubectlInstallation -Detailed:$Detailed
    $functionality = Test-KubectlFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Configured: $(if ($installation.Configured) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Connected: $(if ($installation.Connected) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Context: $($installation.Context)" -ForegroundColor White
    Write-Host "  Namespace: $($installation.Namespace)" -ForegroundColor White
    
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

function Show-KubectlHelp {
    <#
    .SYNOPSIS
    Show help information for kubectl component
    #>
    Write-ComponentHeader "kubectl Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install kubectl" -ForegroundColor White
    Write-Host "  test        - Test kubectl functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall kubectl" -ForegroundColor White
    Write-Host "  update      - Update kubectl" -ForegroundColor White
    Write-Host "  check       - Check kubectl installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix kubectl PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall kubectl" -ForegroundColor White
    Write-Host "  status      - Show kubectl status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\kubectl.ps1 install                    # Install kubectl" -ForegroundColor White
    Write-Host "  .\kubectl.ps1 test                       # Test kubectl" -ForegroundColor White
    Write-Host "  .\kubectl.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\kubectl.ps1 update                     # Update kubectl" -ForegroundColor White
    Write-Host "  .\kubectl.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\kubectl.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\kubectl.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - kubectl version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -ConfigureKubeconfig   - Configure kubeconfig" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Kubectl -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -ConfigureKubeconfig:$ConfigureKubeconfig
        if ($result) {
            Write-ComponentStep "kubectl installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "kubectl installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-KubectlFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "kubectl functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "kubectl functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling kubectl..." "INFO"
        $result = Install-Kubectl -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -ConfigureKubeconfig:$ConfigureKubeconfig
        if ($result) {
            Write-ComponentStep "kubectl reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "kubectl reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Kubectl
        if ($result) {
            Write-ComponentStep "kubectl update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "kubectl update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-KubectlInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "kubectl is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "kubectl is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-KubectlPath
        Write-ComponentStep "kubectl PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Kubectl
        if ($result) {
            Write-ComponentStep "kubectl uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "kubectl uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-KubectlStatus
    }
    "help" {
        Show-KubectlHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-KubectlHelp
        exit 1
    }
}
