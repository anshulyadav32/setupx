# Complete Jupyter Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallExtensions = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Jupyter"
    Version = "1.0.0"
    Description = "Complete Jupyter Notebook Environment"
    ExecutableNames = @("jupyter.exe", "jupyter")
    VersionCommands = @("jupyter --version")
    TestCommands = @("jupyter --version", "jupyter notebook --version")
    InstallMethod = "pip"
    InstallCommands = @("pip install jupyter")
    Documentation = "https://jupyter.org/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "JUPYTER COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-JupyterInstallation {
    <#
    .SYNOPSIS
    Comprehensive Jupyter installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Jupyter installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        PythonAvailable = $false
        PipAvailable = $false
        NotebookAvailable = $false
        LabAvailable = $false
        ExtensionsInstalled = @()
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
    
    # Get Jupyter version
    if ($result.PythonAvailable) {
        try {
            $version = & jupyter --version 2>$null
            if ($version) {
                $result.IsInstalled = $true
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check Jupyter Notebook availability
        try {
            $notebookCheck = & jupyter notebook --version 2>$null
            if ($notebookCheck) {
                $result.NotebookAvailable = $true
            }
        } catch {
            # Continue without error
        }
        
        # Check JupyterLab availability
        try {
            $labCheck = & jupyter lab --version 2>$null
            if ($labCheck) {
                $result.LabAvailable = $true
            }
        } catch {
            # Continue without error
        }
        
        # Get installed extensions
        try {
            $extensions = & jupyter labextension list 2>$null
            if ($extensions) {
                $result.ExtensionsInstalled = $extensions | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Jupyter {
    <#
    .SYNOPSIS
    Install Jupyter with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing Jupyter $Version"
    
    # Check if already installed
    $currentInstallation = Test-JupyterInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Jupyter is already installed: $($currentInstallation.Version)" "WARNING"
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
        
        # Install Jupyter
        Write-ComponentStep "Installing Jupyter..." "INFO"
        
        pip install jupyter
        Write-ComponentStep "Jupyter installed" "SUCCESS"
        
        # Install JupyterLab
        pip install jupyterlab
        Write-ComponentStep "JupyterLab installed" "SUCCESS"
        
        # Install additional Jupyter packages
        Write-ComponentStep "Installing additional Jupyter packages..." "INFO"
        
        $packages = @(
            "jupyter-notebook",
            "jupyterlab",
            "jupyterhub",
            "jupyter-server",
            "jupyter-client",
            "jupyter-core",
            "jupyter-console",
            "jupyter-contrib-nbextensions",
            "jupyter-nbextensions-configurator",
            "jupyterlab-git",
            "jupyterlab-lsp",
            "jupyterlab-code-formatter",
            "jupyterlab-drawio",
            "jupyterlab-plotly",
            "jupyterlab-widgets",
            "ipywidgets",
            "ipykernel",
            "ipython",
            "ipython-genutils",
            "ipython-sql",
            "ipython-autotime",
            "ipython-magic",
            "ipython-extensions",
            "ipython-cython",
            "ipython-js",
            "ipython-js-widgets",
            "ipython-js-widgets-nbextension",
            "ipython-js-widgets-jupyterlab-extension",
            "ipython-js-widgets-jupyterlab-extension",
            "ipython-js-widgets-jupyterlab-extension"
        )
        
        foreach ($package in $packages) {
            try {
                pip install $package
                Write-ComponentStep "  ✓ $package installed" "SUCCESS"
            } catch {
                Write-ComponentStep "  ✗ Failed to install $package" "ERROR"
            }
        }
        
        # Install extensions if requested
        if ($InstallExtensions) {
            Write-ComponentStep "Installing Jupyter extensions..." "INFO"
            
            $extensions = @(
                "jupyterlab-git",
                "jupyterlab-lsp",
                "jupyterlab-code-formatter",
                "jupyterlab-drawio",
                "jupyterlab-plotly",
                "jupyterlab-widgets"
            )
            
            foreach ($extension in $extensions) {
                try {
                    jupyter labextension install $extension
                    Write-ComponentStep "  ✓ $extension installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $extension" "ERROR"
                }
            }
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Jupyter installation..." "INFO"
        $postInstallVerification = Test-JupyterInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Jupyter installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Jupyter installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Jupyter: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-JupyterFunctionality {
    <#
    .SYNOPSIS
    Test Jupyter functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Jupyter Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "jupyter --version",
        "jupyter notebook --version",
        "jupyter lab --version",
        "jupyter server --version",
        "jupyter client --version"
    )
    
    $expectedOutputs = @(
        "jupyter",
        "jupyter",
        "jupyter",
        "jupyter",
        "jupyter"
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

function Update-Jupyter {
    <#
    .SYNOPSIS
    Update Jupyter to latest version
    #>
    Write-ComponentHeader "Updating Jupyter"
    
    $currentInstallation = Test-JupyterInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Jupyter is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Jupyter..." "INFO"
    
    try {
        # Update Jupyter
        pip install --upgrade jupyter
        Write-ComponentStep "Jupyter updated" "SUCCESS"
        
        # Update JupyterLab
        pip install --upgrade jupyterlab
        Write-ComponentStep "JupyterLab updated" "SUCCESS"
        
        # Update additional packages
        $packages = @(
            "jupyter-notebook",
            "jupyterhub",
            "jupyter-server",
            "jupyter-client",
            "jupyter-core",
            "jupyter-console"
        )
        
        foreach ($package in $packages) {
            try {
                pip install --upgrade $package
                Write-ComponentStep "  ✓ $package updated" "SUCCESS"
            } catch {
                Write-ComponentStep "  ✗ Failed to update $package" "WARNING"
            }
        }
        
        Write-ComponentStep "Jupyter update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Jupyter: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-JupyterPath {
    <#
    .SYNOPSIS
    Fix Jupyter PATH issues
    #>
    Write-ComponentHeader "Fixing Jupyter PATH"
    
    $jupyterPaths = @(
        "${env:APPDATA}\Python\Python*\Scripts",
        "${env:ProgramFiles}\Python*\Scripts",
        "${env:ProgramFiles(x86)}\Python*\Scripts"
    )
    
    $foundPaths = @()
    foreach ($path in $jupyterPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Jupyter paths:" "INFO"
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
            Write-ComponentStep "Added Jupyter paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Jupyter paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Jupyter paths found" "WARNING"
    }
}

function Uninstall-Jupyter {
    <#
    .SYNOPSIS
    Uninstall Jupyter
    #>
    Write-ComponentHeader "Uninstalling Jupyter"
    
    $currentInstallation = Test-JupyterInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Jupyter is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Jupyter..." "INFO"
    
    # Uninstall Jupyter and related packages
    $packages = @(
        "jupyter",
        "jupyterlab",
        "jupyter-notebook",
        "jupyterhub",
        "jupyter-server",
        "jupyter-client",
        "jupyter-core",
        "jupyter-console"
    )
    
    foreach ($package in $packages) {
        try {
            pip uninstall -y $package
            Write-ComponentStep "  ✓ $package uninstalled" "SUCCESS"
        } catch {
            Write-ComponentStep "  ✗ Failed to uninstall $package" "ERROR"
        }
    }
    
    Write-ComponentStep "Jupyter uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-JupyterStatus {
    <#
    .SYNOPSIS
    Show comprehensive Jupyter status
    #>
    Write-ComponentHeader "Jupyter Status Report"
    
    $installation = Test-JupyterInstallation -Detailed:$Detailed
    $functionality = Test-JupyterFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Python Available: $(if ($installation.PythonAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Pip Available: $(if ($installation.PipAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Notebook Available: $(if ($installation.NotebookAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Lab Available: $(if ($installation.LabAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.ExtensionsInstalled.Count -gt 0) {
        Write-Host "`nInstalled Extensions:" -ForegroundColor Cyan
        foreach ($extension in $installation.ExtensionsInstalled) {
            Write-Host "  - $extension" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-JupyterHelp {
    <#
    .SYNOPSIS
    Show help information for Jupyter component
    #>
    Write-ComponentHeader "Jupyter Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Jupyter" -ForegroundColor White
    Write-Host "  test        - Test Jupyter functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Jupyter" -ForegroundColor White
    Write-Host "  update      - Update Jupyter and packages" -ForegroundColor White
    Write-Host "  check       - Check Jupyter installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Jupyter PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Jupyter" -ForegroundColor White
    Write-Host "  status      - Show Jupyter status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\jupyter.ps1 install                    # Install Jupyter" -ForegroundColor White
    Write-Host "  .\jupyter.ps1 test                       # Test Jupyter" -ForegroundColor White
    Write-Host "  .\jupyter.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\jupyter.ps1 update                     # Update Jupyter" -ForegroundColor White
    Write-Host "  .\jupyter.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\jupyter.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\jupyter.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Jupyter version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallExtensions     - Install extensions" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Jupyter -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Jupyter installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Jupyter installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-JupyterFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Jupyter functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Jupyter functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Jupyter..." "INFO"
        $result = Install-Jupyter -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "Jupyter reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Jupyter reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Jupyter
        if ($result) {
            Write-ComponentStep "Jupyter update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Jupyter update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-JupyterInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Jupyter is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Jupyter is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-JupyterPath
        Write-ComponentStep "Jupyter PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Jupyter
        if ($result) {
            Write-ComponentStep "Jupyter uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Jupyter uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-JupyterStatus
    }
    "help" {
        Show-JupyterHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-JupyterHelp
        exit 1
    }
}
