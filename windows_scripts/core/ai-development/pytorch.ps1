# Complete PyTorch Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "PyTorch"
    Version = "1.0.0"
    Description = "Complete PyTorch Machine Learning Framework"
    ExecutableNames = @("python.exe", "python")
    VersionCommands = @("python -c \"import torch; print(torch.__version__)\"")
    TestCommands = @("python -c \"import torch; print(torch.__version__)\"", "python -c \"import torch; print(torch.cuda.is_available())\"")
    InstallMethod = "pip"
    InstallCommands = @("pip install torch")
    Documentation = "https://pytorch.org/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "PYTORCH COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-PyTorchInstallation {
    <#
    .SYNOPSIS
    Comprehensive PyTorch installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking PyTorch installation..." "INFO"
    
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
        TorchVisionAvailable = $false
        TorchAudioAvailable = $false
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
    
    # Get PyTorch version
    if ($result.PythonAvailable) {
        try {
            $version = & python -c "import torch; print(torch.__version__)" 2>$null
            if ($version) {
                $result.IsInstalled = $true
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check GPU support
        try {
            $gpuCheck = & python -c "import torch; print(torch.cuda.is_available())" 2>$null
            if ($gpuCheck -eq "True") {
                $result.GPUSupport = $true
            }
        } catch {
            # Continue without error
        }
        
        # Check TorchVision availability
        try {
            $torchVisionCheck = & python -c "import torchvision; print('TorchVision available')" 2>$null
            if ($torchVisionCheck) {
                $result.TorchVisionAvailable = $true
            }
        } catch {
            # Continue without error
        }
        
        # Check TorchAudio availability
        try {
            $torchAudioCheck = & python -c "import torchaudio; print('TorchAudio available')" 2>$null
            if ($torchAudioCheck) {
                $result.TorchAudioAvailable = $true
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-PyTorch {
    <#
    .SYNOPSIS
    Install PyTorch with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallGPU = $true
    )
    
    Write-ComponentHeader "Installing PyTorch $Version"
    
    # Check if already installed
    $currentInstallation = Test-PyTorchInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "PyTorch is already installed: $($currentInstallation.Version)" "WARNING"
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
        
        # Install PyTorch
        Write-ComponentStep "Installing PyTorch..." "INFO"
        
        if ($InstallGPU) {
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
            Write-ComponentStep "PyTorch with GPU support installed" "SUCCESS"
        } else {
            pip install torch torchvision torchaudio
            Write-ComponentStep "PyTorch installed" "SUCCESS"
        }
        
        # Install additional AI packages
        Write-ComponentStep "Installing additional AI packages..." "INFO"
        
        $packages = @(
            "torchtext",
            "torchdata",
            "torchrec",
            "torchx",
            "torchserve",
            "torch-audio",
            "torch-vision",
            "torch-geometric",
            "torch-scatter",
            "torch-sparse",
            "torch-cluster",
            "torch-spline-conv",
            "torch-scatter",
            "torch-sparse",
            "torch-cluster",
            "torch-spline-conv",
            "torch-scatter",
            "torch-sparse",
            "torch-cluster",
            "torch-spline-conv"
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
        Write-ComponentStep "Verifying PyTorch installation..." "INFO"
        $postInstallVerification = Test-PyTorchInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "PyTorch installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "PyTorch installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install PyTorch: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PyTorchFunctionality {
    <#
    .SYNOPSIS
    Test PyTorch functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing PyTorch Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "python -c \"import torch; print(torch.__version__)\"",
        "python -c \"import torch; print(torch.cuda.is_available())\"",
        "python -c \"import torch; print(torch.cuda.device_count())\"",
        "python -c \"import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'No GPU')\"",
        "python -c \"import torch; print(torch.cuda.memory_allocated(0) if torch.cuda.is_available() else 'No GPU')\""
    )
    
    $expectedOutputs = @(
        "torch",
        "torch",
        "torch",
        "torch",
        "torch"
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

function Update-PyTorch {
    <#
    .SYNOPSIS
    Update PyTorch to latest version
    #>
    Write-ComponentHeader "Updating PyTorch"
    
    $currentInstallation = Test-PyTorchInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "PyTorch is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating PyTorch..." "INFO"
    
    try {
        # Update PyTorch
        pip install --upgrade torch torchvision torchaudio
        Write-ComponentStep "PyTorch updated" "SUCCESS"
        
        # Update additional packages
        $packages = @(
            "torchtext",
            "torchdata",
            "torchrec",
            "torchx",
            "torchserve"
        )
        
        foreach ($package in $packages) {
            try {
                pip install --upgrade $package
                Write-ComponentStep "  ✓ $package updated" "SUCCESS"
            } catch {
                Write-ComponentStep "  ✗ Failed to update $package" "WARNING"
            }
        }
        
        Write-ComponentStep "PyTorch update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update PyTorch: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-PyTorchPath {
    <#
    .SYNOPSIS
    Fix PyTorch PATH issues
    #>
    Write-ComponentHeader "Fixing PyTorch PATH"
    
    $pytorchPaths = @(
        "${env:APPDATA}\Python\Python*\Scripts",
        "${env:ProgramFiles}\Python*\Scripts",
        "${env:ProgramFiles(x86)}\Python*\Scripts"
    )
    
    $foundPaths = @()
    foreach ($path in $pytorchPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found PyTorch paths:" "INFO"
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
            Write-ComponentStep "Added PyTorch paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "PyTorch paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No PyTorch paths found" "WARNING"
    }
}

function Uninstall-PyTorch {
    <#
    .SYNOPSIS
    Uninstall PyTorch
    #>
    Write-ComponentHeader "Uninstalling PyTorch"
    
    $currentInstallation = Test-PyTorchInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "PyTorch is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling PyTorch..." "INFO"
    
    # Uninstall PyTorch and related packages
    $packages = @(
        "torch",
        "torchvision",
        "torchaudio",
        "torchtext",
        "torchdata",
        "torchrec",
        "torchx",
        "torchserve"
    )
    
    foreach ($package in $packages) {
        try {
            pip uninstall -y $package
            Write-ComponentStep "  ✓ $package uninstalled" "SUCCESS"
        } catch {
            Write-ComponentStep "  ✗ Failed to uninstall $package" "ERROR"
        }
    }
    
    Write-ComponentStep "PyTorch uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-PyTorchStatus {
    <#
    .SYNOPSIS
    Show comprehensive PyTorch status
    #>
    Write-ComponentHeader "PyTorch Status Report"
    
    $installation = Test-PyTorchInstallation -Detailed:$Detailed
    $functionality = Test-PyTorchFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Python Available: $(if ($installation.PythonAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Pip Available: $(if ($installation.PipAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  GPU Support: $(if ($installation.GPUSupport) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  TorchVision Available: $(if ($installation.TorchVisionAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  TorchAudio Available: $(if ($installation.TorchAudioAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
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

function Show-PyTorchHelp {
    <#
    .SYNOPSIS
    Show help information for PyTorch component
    #>
    Write-ComponentHeader "PyTorch Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install PyTorch" -ForegroundColor White
    Write-Host "  test        - Test PyTorch functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall PyTorch" -ForegroundColor White
    Write-Host "  update      - Update PyTorch and packages" -ForegroundColor White
    Write-Host "  check       - Check PyTorch installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix PyTorch PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall PyTorch" -ForegroundColor White
    Write-Host "  status      - Show PyTorch status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\pytorch.ps1 install                    # Install PyTorch" -ForegroundColor White
    Write-Host "  .\pytorch.ps1 test                       # Test PyTorch" -ForegroundColor White
    Write-Host "  .\pytorch.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\pytorch.ps1 update                     # Update PyTorch" -ForegroundColor White
    Write-Host "  .\pytorch.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\pytorch.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\pytorch.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - PyTorch version to install" -ForegroundColor White
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
        $result = Install-PyTorch -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallGPU:$InstallGPU
        if ($result) {
            Write-ComponentStep "PyTorch installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "PyTorch installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-PyTorchFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "PyTorch functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "PyTorch functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling PyTorch..." "INFO"
        $result = Install-PyTorch -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallGPU:$InstallGPU
        if ($result) {
            Write-ComponentStep "PyTorch reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PyTorch reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-PyTorch
        if ($result) {
            Write-ComponentStep "PyTorch update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PyTorch update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-PyTorchInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "PyTorch is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "PyTorch is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-PyTorchPath
        Write-ComponentStep "PyTorch PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-PyTorch
        if ($result) {
            Write-ComponentStep "PyTorch uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PyTorch uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-PyTorchStatus
    }
    "help" {
        Show-PyTorchHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-PyTorchHelp
        exit 1
    }
}
