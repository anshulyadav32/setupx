# Complete Go Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallTools = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Go"
    Version = "1.0.0"
    Description = "Complete Go Programming Language Environment"
    ExecutableNames = @("go.exe", "go")
    VersionCommands = @("go version")
    TestCommands = @("go version", "go env", "go help")
    WingetId = "GoLang.Go"
    ChocoId = "golang"
    DownloadUrl = "https://golang.org/dl/"
    Documentation = "https://golang.org/doc/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "GO COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-GoInstallation {
    <#
    .SYNOPSIS
    Comprehensive Go installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Go installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        GoRoot = ""
        GoPath = ""
        GoModules = $false
        GoVersion = "Unknown"
    }
    
    # Check Go executable
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
            $version = & go version 2>$null
            if ($version) {
                $result.Version = $version
                $result.GoVersion = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Get Go environment
        try {
            $env = & go env 2>$null
            if ($env) {
                $result.GoRoot = ($env | Where-Object { $_ -match "GOROOT" } | ForEach-Object { ($_ -split "=")[1] }) -join ", "
                $result.GoPath = ($env | Where-Object { $_ -match "GOPATH" } | ForEach-Object { ($_ -split "=")[1] }) -join ", "
                $result.GoModules = ($env | Where-Object { $_ -match "GO111MODULE" } | ForEach-Object { ($_ -split "=")[1] }) -eq "on"
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Go {
    <#
    .SYNOPSIS
    Install Go with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallTools = $true
    )
    
    Write-ComponentHeader "Installing Go $Version"
    
    # Check if already installed
    $currentInstallation = Test-GoInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Go is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Go using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Go installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Go using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Go installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Go manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Set Go environment variables
        $goPaths = @(
            "${env:ProgramFiles}\Go",
            "${env:ProgramFiles(x86)}\Go",
            "${env:LOCALAPPDATA}\Go"
        )
        
        $goRoot = ""
        foreach ($path in $goPaths) {
            if (Test-Path $path) {
                $goRoot = $path
                break
            }
        }
        
        if ($goRoot) {
            [Environment]::SetEnvironmentVariable("GOROOT", $goRoot, "User")
            Write-ComponentStep "Set GOROOT to: $goRoot" "SUCCESS"
        }
        
        # Set GOPATH
        $goPath = "${env:USERPROFILE}\go"
        [Environment]::SetEnvironmentVariable("GOPATH", $goPath, "User")
        Write-ComponentStep "Set GOPATH to: $goPath" "SUCCESS"
        
        # Enable Go modules
        [Environment]::SetEnvironmentVariable("GO111MODULE", "on", "User")
        Write-ComponentStep "Enabled Go modules" "SUCCESS"
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $env:GOROOT = [Environment]::GetEnvironmentVariable("GOROOT", "User")
        $env:GOPATH = [Environment]::GetEnvironmentVariable("GOPATH", "User")
        $env:GO111MODULE = [Environment]::GetEnvironmentVariable("GO111MODULE", "User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Go installation..." "INFO"
        $postInstallVerification = Test-GoInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Go installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Go installation verification failed" "WARNING"
            return $false
        }
        
        # Install Go tools if requested
        if ($InstallTools) {
            Write-ComponentStep "Installing Go development tools..." "INFO"
            
            $tools = @(
                "golang.org/x/tools/gopls",
                "golang.org/x/tools/cmd/goimports",
                "golang.org/x/tools/cmd/godoc",
                "golang.org/x/tools/cmd/guru",
                "golang.org/x/tools/cmd/gorename",
                "golang.org/x/tools/cmd/gotype",
                "golang.org/x/tools/cmd/godex",
                "golang.org/x/tools/cmd/godoc",
                "golang.org/x/tools/cmd/gofmt",
                "golang.org/x/tools/cmd/golint"
            )
            
            foreach ($tool in $tools) {
                try {
                    go install $tool@latest
                    Write-ComponentStep "  ✓ $tool installed" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $tool" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Go: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-GoFunctionality {
    <#
    .SYNOPSIS
    Test Go functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Go Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "go version",
        "go env",
        "go help",
        "go mod help",
        "go build --help"
    )
    
    $expectedOutputs = @(
        "go version",
        "go env",
        "go help",
        "go mod",
        "go build"
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

function Update-Go {
    <#
    .SYNOPSIS
    Update Go to latest version
    #>
    Write-ComponentHeader "Updating Go"
    
    $currentInstallation = Test-GoInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Go is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Go..." "INFO"
    
    try {
        # Update Go using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Go updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Go updated using Chocolatey" "SUCCESS"
        }
        
        # Update Go tools
        go install golang.org/x/tools/gopls@latest
        Write-ComponentStep "Go tools updated" "SUCCESS"
        
        Write-ComponentStep "Go update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Go: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-GoPath {
    <#
    .SYNOPSIS
    Fix Go PATH issues
    #>
    Write-ComponentHeader "Fixing Go PATH"
    
    $goPaths = @(
        "${env:ProgramFiles}\Go\bin",
        "${env:ProgramFiles(x86)}\Go\bin",
        "${env:LOCALAPPDATA}\Go\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $goPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Go paths:" "INFO"
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
            Write-ComponentStep "Added Go paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Go paths already in environment" "INFO"
        }
        
        # Set environment variables
        $goRoot = $foundPaths[0].Replace("\bin", "")
        $goPath = "${env:USERPROFILE}\go"
        
        [Environment]::SetEnvironmentVariable("GOROOT", $goRoot, "User")
        [Environment]::SetEnvironmentVariable("GOPATH", $goPath, "User")
        [Environment]::SetEnvironmentVariable("GO111MODULE", "on", "User")
        
        $env:GOROOT = $goRoot
        $env:GOPATH = $goPath
        $env:GO111MODULE = "on"
        
        Write-ComponentStep "Set Go environment variables" "SUCCESS"
    } else {
        Write-ComponentStep "No Go paths found" "WARNING"
    }
}

function Uninstall-Go {
    <#
    .SYNOPSIS
    Uninstall Go
    #>
    Write-ComponentHeader "Uninstalling Go"
    
    $currentInstallation = Test-GoInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Go is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Go from PATH..." "INFO"
    
    # Remove Go paths from environment
    $currentPath = $env:Path
    $goPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $goPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Remove Go environment variables
    [Environment]::SetEnvironmentVariable("GOROOT", $null, "User")
    [Environment]::SetEnvironmentVariable("GOPATH", $null, "User")
    [Environment]::SetEnvironmentVariable("GO111MODULE", $null, "User")
    
    $env:GOROOT = $null
    $env:GOPATH = $null
    $env:GO111MODULE = $null
    
    Write-ComponentStep "Go removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Go files may be required" "WARNING"
    
    return $true
}

function Show-GoStatus {
    <#
    .SYNOPSIS
    Show comprehensive Go status
    #>
    Write-ComponentHeader "Go Status Report"
    
    $installation = Test-GoInstallation -Detailed:$Detailed
    $functionality = Test-GoFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Go Root: $($installation.GoRoot)" -ForegroundColor White
    Write-Host "  Go Path: $($installation.GoPath)" -ForegroundColor White
    Write-Host "  Go Modules: $(if ($installation.GoModules) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
    
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

function Show-GoHelp {
    <#
    .SYNOPSIS
    Show help information for Go component
    #>
    Write-ComponentHeader "Go Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Go" -ForegroundColor White
    Write-Host "  test        - Test Go functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Go" -ForegroundColor White
    Write-Host "  update      - Update Go and tools" -ForegroundColor White
    Write-Host "  check       - Check Go installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Go PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Go" -ForegroundColor White
    Write-Host "  status      - Show Go status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\go.ps1 install                    # Install Go" -ForegroundColor White
    Write-Host "  .\go.ps1 test                       # Test Go" -ForegroundColor White
    Write-Host "  .\go.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\go.ps1 update                     # Update Go" -ForegroundColor White
    Write-Host "  .\go.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\go.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\go.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Go version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallTools          - Install Go tools" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Go -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallTools:$InstallTools
        if ($result) {
            Write-ComponentStep "Go installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Go installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-GoFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Go functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Go functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Go..." "INFO"
        $result = Install-Go -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallTools:$InstallTools
        if ($result) {
            Write-ComponentStep "Go reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Go reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Go
        if ($result) {
            Write-ComponentStep "Go update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Go update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-GoInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Go is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Go is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-GoPath
        Write-ComponentStep "Go PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Go
        if ($result) {
            Write-ComponentStep "Go uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Go uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-GoStatus
    }
    "help" {
        Show-GoHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-GoHelp
        exit 1
    }
}
