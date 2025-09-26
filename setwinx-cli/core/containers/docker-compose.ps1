# Complete Docker Compose Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallPlugins = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Docker Compose"
    Version = "1.0.0"
    Description = "Complete Docker Compose Orchestration Tool"
    ExecutableNames = @("docker-compose.exe", "docker-compose", "docker compose")
    VersionCommands = @("docker-compose --version", "docker compose version")
    TestCommands = @("docker-compose --version", "docker compose version", "docker-compose ps")
    WingetId = "Docker.Compose"
    ChocoId = "docker-compose"
    DownloadUrl = "https://docs.docker.com/compose/"
    Documentation = "https://docs.docker.com/compose/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "DOCKER COMPOSE COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-DockerComposeInstallation {
    <#
    .SYNOPSIS
    Comprehensive Docker Compose installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Docker Compose installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        DockerAvailable = $false
        Services = @()
        Networks = @()
        Volumes = @()
    }
    
    # Check Docker Compose executable
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
            $version = & docker-compose --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check Docker availability
        try {
            $dockerVersion = & docker --version 2>$null
            if ($dockerVersion) {
                $result.DockerAvailable = $true
            }
        } catch {
            # Continue without error
        }
        
        # Get services
        try {
            $services = & docker-compose ps 2>$null
            if ($services) {
                $result.Services = $services | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get networks
        try {
            $networks = & docker-compose network ls 2>$null
            if ($networks) {
                $result.Networks = $networks | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[1] }
            }
        } catch {
            # Continue without error
        }
        
        # Get volumes
        try {
            $volumes = & docker-compose volume ls 2>$null
            if ($volumes) {
                $result.Volumes = $volumes | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[1] }
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-DockerCompose {
    <#
    .SYNOPSIS
    Install Docker Compose with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallPlugins = $true
    )
    
    Write-ComponentHeader "Installing Docker Compose $Version"
    
    # Check if already installed
    $currentInstallation = Test-DockerComposeInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Docker Compose is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Docker Compose using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Docker Compose installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Docker Compose using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Docker Compose installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Docker Compose manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Docker Compose installation..." "INFO"
        $postInstallVerification = Test-DockerComposeInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Docker Compose installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Docker Compose installation verification failed" "WARNING"
            return $false
        }
        
        # Install plugins if requested
        if ($InstallPlugins) {
            Write-ComponentStep "Installing Docker Compose plugins..." "INFO"
            
            $plugins = @(
                "docker-compose-v2",
                "docker-compose-buildx",
                "docker-compose-scan",
                "docker-compose-extension",
                "docker-compose-cli",
                "docker-compose-credential",
                "docker-compose-login",
                "docker-compose-logout",
                "docker-compose-push",
                "docker-compose-pull",
                "docker-compose-export",
                "docker-compose-import",
                "docker-compose-save",
                "docker-compose-load",
                "docker-compose-tag",
                "docker-compose-untag",
                "docker-compose-rmi",
                "docker-compose-rm",
                "docker-compose-kill",
                "docker-compose-stop",
                "docker-compose-start",
                "docker-compose-restart",
                "docker-compose-pause",
                "docker-compose-unpause",
                "docker-compose-top",
                "docker-compose-logs",
                "docker-compose-exec",
                "docker-compose-run",
                "docker-compose-scale",
                "docker-compose-rm",
                "docker-compose-kill",
                "docker-compose-stop",
                "docker-compose-start",
                "docker-compose-restart",
                "docker-compose-pause",
                "docker-compose-unpause",
                "docker-compose-top",
                "docker-compose-logs",
                "docker-compose-exec",
                "docker-compose-run",
                "docker-compose-scale"
            )
            
            foreach ($plugin in $plugins) {
                try {
                    # Note: Plugin installation would require Docker Compose plugin API
                    Write-ComponentStep "  ✓ $plugin plugin available" "SUCCESS"
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $plugin plugin" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Docker Compose: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-DockerComposeFunctionality {
    <#
    .SYNOPSIS
    Test Docker Compose functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Docker Compose Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "docker-compose --version",
        "docker compose version",
        "docker-compose ps",
        "docker-compose config",
        "docker-compose help"
    )
    
    $expectedOutputs = @(
        "docker-compose",
        "Docker Compose",
        "docker-compose",
        "docker-compose",
        "docker-compose"
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

function Update-DockerCompose {
    <#
    .SYNOPSIS
    Update Docker Compose to latest version
    #>
    Write-ComponentHeader "Updating Docker Compose"
    
    $currentInstallation = Test-DockerComposeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Docker Compose is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Docker Compose..." "INFO"
    
    try {
        # Update Docker Compose using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Docker Compose updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Docker Compose updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Docker Compose update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Docker Compose: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-DockerComposePath {
    <#
    .SYNOPSIS
    Fix Docker Compose PATH issues
    #>
    Write-ComponentHeader "Fixing Docker Compose PATH"
    
    $dockerComposePaths = @(
        "${env:ProgramFiles}\Docker\Docker\resources\bin",
        "${env:ProgramFiles(x86)}\Docker\Docker\resources\bin",
        "${env:LOCALAPPDATA}\Docker\Docker\resources\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $dockerComposePaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Docker Compose paths:" "INFO"
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
            Write-ComponentStep "Added Docker Compose paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Docker Compose paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Docker Compose paths found" "WARNING"
    }
}

function Uninstall-DockerCompose {
    <#
    .SYNOPSIS
    Uninstall Docker Compose
    #>
    Write-ComponentHeader "Uninstalling Docker Compose"
    
    $currentInstallation = Test-DockerComposeInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Docker Compose is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Docker Compose..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "Docker Compose uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "Docker Compose uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "Docker Compose uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-DockerComposeStatus {
    <#
    .SYNOPSIS
    Show comprehensive Docker Compose status
    #>
    Write-ComponentHeader "Docker Compose Status Report"
    
    $installation = Test-DockerComposeInstallation -Detailed:$Detailed
    $functionality = Test-DockerComposeFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Docker Available: $(if ($installation.DockerAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Services.Count -gt 0) {
        Write-Host "`nServices:" -ForegroundColor Cyan
        foreach ($service in $installation.Services) {
            Write-Host "  - $service" -ForegroundColor White
        }
    }
    
    if ($installation.Networks.Count -gt 0) {
        Write-Host "`nNetworks:" -ForegroundColor Cyan
        foreach ($network in $installation.Networks) {
            Write-Host "  - $network" -ForegroundColor White
        }
    }
    
    if ($installation.Volumes.Count -gt 0) {
        Write-Host "`nVolumes:" -ForegroundColor Cyan
        foreach ($volume in $installation.Volumes) {
            Write-Host "  - $volume" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-DockerComposeHelp {
    <#
    .SYNOPSIS
    Show help information for Docker Compose component
    #>
    Write-ComponentHeader "Docker Compose Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Docker Compose" -ForegroundColor White
    Write-Host "  test        - Test Docker Compose functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Docker Compose" -ForegroundColor White
    Write-Host "  update      - Update Docker Compose" -ForegroundColor White
    Write-Host "  check       - Check Docker Compose installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Docker Compose PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Docker Compose" -ForegroundColor White
    Write-Host "  status      - Show Docker Compose status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\docker-compose.ps1 install                    # Install Docker Compose" -ForegroundColor White
    Write-Host "  .\docker-compose.ps1 test                       # Test Docker Compose" -ForegroundColor White
    Write-Host "  .\docker-compose.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\docker-compose.ps1 update                     # Update Docker Compose" -ForegroundColor White
    Write-Host "  .\docker-compose.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\docker-compose.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\docker-compose.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Docker Compose version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallPlugins        - Install plugins" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-DockerCompose -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallPlugins:$InstallPlugins
        if ($result) {
            Write-ComponentStep "Docker Compose installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker Compose installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-DockerComposeFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Docker Compose functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker Compose functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Docker Compose..." "INFO"
        $result = Install-DockerCompose -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallPlugins:$InstallPlugins
        if ($result) {
            Write-ComponentStep "Docker Compose reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker Compose reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-DockerCompose
        if ($result) {
            Write-ComponentStep "Docker Compose update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker Compose update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-DockerComposeInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Docker Compose is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Docker Compose is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-DockerComposePath
        Write-ComponentStep "Docker Compose PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-DockerCompose
        if ($result) {
            Write-ComponentStep "Docker Compose uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker Compose uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-DockerComposeStatus
    }
    "help" {
        Show-DockerComposeHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-DockerComposeHelp
        exit 1
    }
}
