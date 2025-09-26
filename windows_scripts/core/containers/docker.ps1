# Complete Docker Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallCompose = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Docker"
    Version = "1.0.0"
    Description = "Complete Docker Container Platform"
    ExecutableNames = @("docker.exe", "docker")
    VersionCommands = @("docker --version", "docker version")
    TestCommands = @("docker --version", "docker info", "docker ps")
    WingetId = "Docker.DockerDesktop"
    ChocoId = "docker-desktop"
    DownloadUrl = "https://www.docker.com/products/docker-desktop/"
    Documentation = "https://docs.docker.com/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "DOCKER COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-DockerInstallation {
    <#
    .SYNOPSIS
    Comprehensive Docker installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Docker installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        ServiceStatus = "Unknown"
        Containers = @()
        Images = @()
        Networks = @()
        Volumes = @()
    }
    
    # Check Docker executable
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
            $version = & docker --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check service status
        try {
            $service = Get-Service -Name "Docker*" -ErrorAction SilentlyContinue
            if ($service) {
                $result.ServiceStatus = $service.Status
            }
        } catch {
            # Continue without error
        }
        
        # Get containers
        try {
            $containers = & docker ps -a 2>$null
            if ($containers) {
                $result.Containers = $containers | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get images
        try {
            $images = & docker images 2>$null
            if ($images) {
                $result.Images = $images | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get networks
        try {
            $networks = & docker network ls 2>$null
            if ($networks) {
                $result.Networks = $networks | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[1] }
            }
        } catch {
            # Continue without error
        }
        
        # Get volumes
        try {
            $volumes = & docker volume ls 2>$null
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

function Install-Docker {
    <#
    .SYNOPSIS
    Install Docker with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallCompose = $true
    )
    
    Write-ComponentHeader "Installing Docker $Version"
    
    # Check if already installed
    $currentInstallation = Test-DockerInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Docker is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Docker using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Docker installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Docker using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Docker installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Docker manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Docker installation..." "INFO"
        $postInstallVerification = Test-DockerInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Docker installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Docker installation verification failed" "WARNING"
            return $false
        }
        
        # Install Docker Compose if requested
        if ($InstallCompose) {
            Write-ComponentStep "Installing Docker Compose..." "INFO"
            
            $composeScript = "core\containers\docker-compose.ps1"
            if (Test-Path $composeScript) {
                & $composeScript install -Silent:$Silent -Force:$Force -Quiet:$Quiet
                Write-ComponentStep "Docker Compose installed" "SUCCESS"
            } else {
                Write-ComponentStep "Docker Compose installer not found" "WARNING"
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Docker: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-DockerFunctionality {
    <#
    .SYNOPSIS
    Test Docker functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Docker Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "docker --version",
        "docker info",
        "docker ps",
        "docker images",
        "docker network ls"
    )
    
    $expectedOutputs = @(
        "Docker",
        "Docker",
        "Docker",
        "Docker",
        "Docker"
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

function Update-Docker {
    <#
    .SYNOPSIS
    Update Docker to latest version
    #>
    Write-ComponentHeader "Updating Docker"
    
    $currentInstallation = Test-DockerInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Docker is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Docker..." "INFO"
    
    try {
        # Update Docker using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Docker updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Docker updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Docker update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Docker: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-DockerPath {
    <#
    .SYNOPSIS
    Fix Docker PATH issues
    #>
    Write-ComponentHeader "Fixing Docker PATH"
    
    $dockerPaths = @(
        "${env:ProgramFiles}\Docker\Docker\resources\bin",
        "${env:ProgramFiles(x86)}\Docker\Docker\resources\bin",
        "${env:LOCALAPPDATA}\Docker\Docker\resources\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $dockerPaths) {
        if (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Docker paths:" "INFO"
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
            Write-ComponentStep "Added Docker paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Docker paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No Docker paths found" "WARNING"
    }
}

function Uninstall-Docker {
    <#
    .SYNOPSIS
    Uninstall Docker
    #>
    Write-ComponentHeader "Uninstalling Docker"
    
    $currentInstallation = Test-DockerInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Docker is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling Docker..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "Docker uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "Docker uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "Docker uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-DockerStatus {
    <#
    .SYNOPSIS
    Show comprehensive Docker status
    #>
    Write-ComponentHeader "Docker Status Report"
    
    $installation = Test-DockerInstallation -Detailed:$Detailed
    $functionality = Test-DockerFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Service Status: $($installation.ServiceStatus)" -ForegroundColor White
    
    if ($installation.Paths.Count -gt 0) {
        Write-Host "  Paths:" -ForegroundColor White
        foreach ($path in $installation.Paths) {
            Write-Host "    - $path" -ForegroundColor Gray
        }
    }
    
    if ($installation.Containers.Count -gt 0) {
        Write-Host "`nContainers:" -ForegroundColor Cyan
        foreach ($container in $installation.Containers) {
            Write-Host "  - $container" -ForegroundColor White
        }
    }
    
    if ($installation.Images.Count -gt 0) {
        Write-Host "`nImages:" -ForegroundColor Cyan
        foreach ($image in $installation.Images) {
            Write-Host "  - $image" -ForegroundColor White
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

function Show-DockerHelp {
    <#
    .SYNOPSIS
    Show help information for Docker component
    #>
    Write-ComponentHeader "Docker Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Docker" -ForegroundColor White
    Write-Host "  test        - Test Docker functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Docker" -ForegroundColor White
    Write-Host "  update      - Update Docker" -ForegroundColor White
    Write-Host "  check       - Check Docker installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Docker PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Docker" -ForegroundColor White
    Write-Host "  status      - Show Docker status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\docker.ps1 install                    # Install Docker" -ForegroundColor White
    Write-Host "  .\docker.ps1 test                       # Test Docker" -ForegroundColor White
    Write-Host "  .\docker.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\docker.ps1 update                     # Update Docker" -ForegroundColor White
    Write-Host "  .\docker.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\docker.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\docker.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Docker version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallCompose        - Install Docker Compose" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Docker -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallCompose:$InstallCompose
        if ($result) {
            Write-ComponentStep "Docker installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-DockerFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Docker functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Docker..." "INFO"
        $result = Install-Docker -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallCompose:$InstallCompose
        if ($result) {
            Write-ComponentStep "Docker reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Docker
        if ($result) {
            Write-ComponentStep "Docker update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-DockerInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Docker is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Docker is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-DockerPath
        Write-ComponentStep "Docker PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Docker
        if ($result) {
            Write-ComponentStep "Docker uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Docker uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-DockerStatus
    }
    "help" {
        Show-DockerHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-DockerHelp
        exit 1
    }
}
