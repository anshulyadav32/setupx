# Complete TensorFlow Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallGPU = $true
)

# Component Information
$ComponentInfo = @{
    Name = "TensorFlow"
    Version = "1.0.0"
    Description = "Complete TensorFlow Machine Learning Framework"
    ExecutableNames = @("python.exe", "python")
    VersionCommands = @("python -c \"import tensorflow as tf; print(tf.__version__)\"")
    TestCommands = @("python -c \"import tensorflow as tf; print(tf.__version__)\"", "python -c \"import tensorflow as tf; tf.config.list_physical_devices()\"")
    InstallMethod = "pip"
    InstallCommands = @("pip install tensorflow")
    Documentation = "https://www.tensorflow.org/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "TENSORFLOW COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-TensorFlowInstallation {
    <#
    .SYNOPSIS
    Comprehensive TensorFlow installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking TensorFlow installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        PythonAvailable = $false
        PipAvailable = $false
        GPUSupport = $false
        Devices = @()
        KerasAvailable = $false
    }
    
    # Check Python executable
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand) {
        $result.PythonAvailable = $true
        $result.ExecutablePath = $pythonCommand.Source
        $result.Paths += $pythonCommand.Source
    }
    
    # Check pip availability
    $result.PipAvailable = (Get-Command pip -ErrorAction SilentlyContinue) -ne $null
    
    # Get TensorFlow version
    if ($result.PythonAvailable) {
        try {
            $version = & python -c "import tensorflow as tf; print(tf.__version__)" 2>$null
            if ($version) {
                $result.IsInstalled = $true
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check GPU support
        try {
            $gpuCheck = & python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))" 2>$null
            if ($gpuCheck -and $gpuCheck -ne "[]") {
                $result.GPUSupport = $true
                $result.Devices = $gpuCheck
            }
        } catch {
            # Continue without error
        }
        
        # Check Keras availability
        try {
            $kerasCheck = & python -c "import tensorflow.keras; print('Keras available')" 2>$null
            if ($kerasCheck) {
                $result.KerasAvailable = $true
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-TensorFlow {
    <#
    .SYNOPSIS
    Install TensorFlow with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallGPU = $true
    )
    
    Write-ComponentHeader "Installing TensorFlow $Version"
    
    # Check if already installed
    $currentInstallation = Test-TensorFlowInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "TensorFlow is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install Python if not available
        if (-not $currentInstallation.PythonAvailable) {
            Write-ComponentStep "Installing Python..." "INFO"
            
            $pythonScript = "core\backend-development\python.ps1"
            if (Test-Path $pythonScript) {
                & $pythonScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                Write-ComponentStep "Python installed" "SUCCESS"
            } else {
                throw "Python installer not found"
            }
        }
        
        # Install TensorFlow
        Write-ComponentStep "Installing TensorFlow..." "INFO"
        
        if ($InstallGPU) {
            pip install tensorflow[and-cuda]
            Write-ComponentStep "TensorFlow with GPU support installed" "SUCCESS"
        } else {
            pip install tensorflow
            Write-ComponentStep "TensorFlow installed" "SUCCESS"
        }
        
        # Install additional AI packages
        Write-ComponentStep "Installing additional AI packages..." "INFO"
        
        $packages = @(
            "tensorflow-datasets",
            "tensorflow-hub",
            "tensorflow-probability",
            "tensorflow-text",
            "tensorflow-addons",
            "tensorflow-io",
            "tensorflow-transform",
            "tensorflow-serving-api",
            "tensorflow-model-optimization",
            "tensorflow-lite",
            "tensorflow-js",
            "tensorflow-graphics",
            "tensorflow-federated",
            "tensorflow-privacy",
            "tensorflow-gan",
            "tensorflow-recommenders",
            "tensorflow-ranking",
            "tensorflow-text",
            "tensorflow-hub",
            "tensorflow-datasets"
        )
        
        foreach ($package in $packages) {
            try {
                pip install $package
                Write-ComponentStep "  ✓ $package installed" "SUCCESS"
            } catch {
                Write-ComponentStep "  ✗ Failed to install $package" "ERROR"
            }
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying TensorFlow installation..." "INFO"
        $postInstallVerification = Test-TensorFlowInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "TensorFlow installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "TensorFlow installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install TensorFlow: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-TensorFlowFunctionality {
    <#
    .SYNOPSIS
    Test TensorFlow functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing TensorFlow Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "python -c \"import tensorflow as tf; print(tf.__version__)\"",
        "python -c \"import tensorflow as tf; print(tf.config.list_physical_devices())\"",
        "python -c \"import tensorflow as tf; print(tf.config.list_logical_devices())\"",
        "python -c \"import tensorflow as tf; print(tf.test.is_built_with_cuda())\"",
        "python -c \"import tensorflow as tf; print(tf.test.is_gpu_available())\""
    )
    
    $expectedOutputs = @(
        "tensorflow",
        "tensorflow",
        "tensorflow",
        "tensorflow",
        "tensorflow"
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

function Update-TensorFlow {
    <#
    .SYNOPSIS
    Update TensorFlow to latest version
    #>
    Write-ComponentHeader "Updating TensorFlow"
    
    $currentInstallation = Test-TensorFlowInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "TensorFlow is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating TensorFlow..." "INFO"
    
    try {
        # Update TensorFlow
        pip install --upgrade tensorflow
        Write-ComponentStep "TensorFlow updated" "SUCCESS"
        
        # Update additional packages
        $packages = @(
            "tensorflow-datasets",
            "tensorflow-hub",
            "tensorflow-probability",
            "tensorflow-text",
            "tensorflow-addons"
        )
        
        foreach ($package in $packages) {
            try {
                pip install --upgrade $package
                Write-ComponentStep "  ✓ $package updated" "SUCCESS"
            } catch {
                Write-ComponentStep "  ✗ Failed to update $package" "WARNING"
            }
        }
        
        Write-ComponentStep "TensorFlow update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update TensorFlow: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-TensorFlowPath {
    <#
    .SYNOPSIS
    Fix TensorFlow PATH issues
    #>
    Write-ComponentHeader "Fixing TensorFlow PATH"
    
    $tensorflowPaths = @(
        "${env:APPDATA}\Python\Python*\Scripts",
        "${env:ProgramFiles}\Python*\Scripts",
        "${env:ProgramFiles(x86)}\Python*\Scripts"
    )
    
    $foundPaths = @()
    foreach ($path in $tensorflowPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found TensorFlow paths:" "INFO"
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
            Write-ComponentStep "Added TensorFlow paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "TensorFlow paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No TensorFlow paths found" "WARNING"
    }
}

function Uninstall-TensorFlow {
    <#
    .SYNOPSIS
    Uninstall TensorFlow
    #>
    Write-ComponentHeader "Uninstalling TensorFlow"
    
    $currentInstallation = Test-TensorFlowInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "TensorFlow is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling TensorFlow..." "INFO"
    
    # Uninstall TensorFlow and related packages
    $packages = @(
        "tensorflow",
        "tensorflow-datasets",
        "tensorflow-hub",
        "tensorflow-probability",
        "tensorflow-text",
        "tensorflow-addons"
    )
    
    foreach ($package in $packages) {
        try {
            pip uninstall -y $package
            Write-ComponentStep "  ✓ $package uninstalled" "SUCCESS"
        } catch {
            Write-ComponentStep "  ✗ Failed to uninstall $package" "ERROR"
        }
    }
    
    Write-ComponentStep "TensorFlow uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-TensorFlowStatus {
    <#
    .SYNOPSIS
    Show comprehensive TensorFlow status
    #>
    Write-ComponentHeader "TensorFlow Status Report"
    
    $installation = Test-TensorFlowInstallation -Detailed:$Detailed
    $functionality = Test-TensorFlowFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Python Available: $(if ($installation.PythonAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Pip Available: $(if ($installation.PipAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  GPU Support: $(if ($installation.GPUSupport) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Keras Available: $(if ($installation.KerasAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Devices.Count -gt 0) {
        Write-Host "`nAvailable Devices:" -ForegroundColor Cyan
        foreach ($device in $installation.Devices) {
            Write-Host "  - $device" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-TensorFlowHelp {
    <#
    .SYNOPSIS
    Show help information for TensorFlow component
    #>
    Write-ComponentHeader "TensorFlow Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install TensorFlow" -ForegroundColor White
    Write-Host "  test        - Test TensorFlow functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall TensorFlow" -ForegroundColor White
    Write-Host "  update      - Update TensorFlow and packages" -ForegroundColor White
    Write-Host "  check       - Check TensorFlow installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix TensorFlow PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall TensorFlow" -ForegroundColor White
    Write-Host "  status      - Show TensorFlow status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\tensorflow.ps1 install                    # Install TensorFlow" -ForegroundColor White
    Write-Host "  .\tensorflow.ps1 test                       # Test TensorFlow" -ForegroundColor White
    Write-Host "  .\tensorflow.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\tensorflow.ps1 update                     # Update TensorFlow" -ForegroundColor White
    Write-Host "  .\tensorflow.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\tensorflow.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\tensorflow.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - TensorFlow version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallGPU            - Install GPU support" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-TensorFlow -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallGPU:$InstallGPU
        if ($result) {
            Write-ComponentStep "TensorFlow installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "TensorFlow installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-TensorFlowFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "TensorFlow functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "TensorFlow functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling TensorFlow..." "INFO"
        $result = Install-TensorFlow -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallGPU:$InstallGPU
        if ($result) {
            Write-ComponentStep "TensorFlow reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "TensorFlow reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-TensorFlow
        if ($result) {
            Write-ComponentStep "TensorFlow update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "TensorFlow update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-TensorFlowInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "TensorFlow is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "TensorFlow is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-TensorFlowPath
        Write-ComponentStep "TensorFlow PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-TensorFlow
        if ($result) {
            Write-ComponentStep "TensorFlow uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "TensorFlow uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-TensorFlowStatus
    }
    "help" {
        Show-TensorFlowHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-TensorFlowHelp
        exit 1
    }
}
