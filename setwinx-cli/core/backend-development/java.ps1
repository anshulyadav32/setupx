# Complete Java Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    [switch]$InstallJdk = $true
)

# Component Information
$ComponentInfo = @{
    Name = "Java"
    Version = "1.0.0"
    Description = "Complete Java Development Kit Environment"
    ExecutableNames = @("java.exe", "java", "javac.exe", "javac")
    VersionCommands = @("java --version", "javac --version")
    TestCommands = @("java --version", "javac --version", "java -version")
    WingetId = "Oracle.JDK"
    ChocoId = "openjdk"
    DownloadUrl = "https://www.oracle.com/java/technologies/downloads/"
    Documentation = "https://docs.oracle.com/en/java/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "JAVA COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-JavaInstallation {
    <#
    .SYNOPSIS
    Comprehensive Java installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking Java installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        JavaHome = ""
        JavacAvailable = $false
        JavacVersion = "Unknown"
        JavaVersion = "Unknown"
    }
    
    # Check Java executable
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
            $version = & java --version 2>$null
            if ($version) {
                $result.Version = $version
                $result.JavaVersion = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check javac availability
        $result.JavacAvailable = (Get-Command javac -ErrorAction SilentlyContinue) -ne $null
        if ($result.JavacAvailable) {
            try {
                $javacVersion = & javac --version 2>$null
                if ($javacVersion) {
                    $result.JavacVersion = $javacVersion
                }
            } catch {
                $result.JavacVersion = "Unknown"
            }
        }
        
        # Check JAVA_HOME
        $result.JavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
        if (-not $result.JavaHome) {
            $result.JavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-Java {
    <#
    .SYNOPSIS
    Install Java with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallJdk = $true
    )
    
    Write-ComponentHeader "Installing Java $Version"
    
    # Check if already installed
    $currentInstallation = Test-JavaInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "Java is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Java using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Java installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing Java using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "Java installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing Java manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Set JAVA_HOME environment variable
        $javaPaths = @(
            "${env:ProgramFiles}\Java\jdk*",
            "${env:ProgramFiles(x86)}\Java\jdk*",
            "${env:LOCALAPPDATA}\Programs\Java\jdk*"
        )
        
        $javaHome = ""
        foreach ($path in $javaPaths) {
            $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
            foreach ($expandedPath in $expandedPaths) {
                if (Test-Path (Join-Path $expandedPath.FullName "bin\java.exe")) {
                    $javaHome = $expandedPath.FullName
                    break
                }
            }
            if ($javaHome) { break }
        }
        
        if ($javaHome) {
            [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "User")
            Write-ComponentStep "Set JAVA_HOME to: $javaHome" "SUCCESS"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $env:JAVA_HOME = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying Java installation..." "INFO"
        $postInstallVerification = Test-JavaInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "Java installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "Java installation verification failed" "WARNING"
            return $false
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install Java: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-JavaFunctionality {
    <#
    .SYNOPSIS
    Test Java functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing Java Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "java --version",
        "javac --version",
        "java -version",
        "java -cp . -version",
        "javac -version"
    )
    
    $expectedOutputs = @(
        "java",
        "javac",
        "java",
        "java",
        "javac"
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

function Update-Java {
    <#
    .SYNOPSIS
    Update Java to latest version
    #>
    Write-ComponentHeader "Updating Java"
    
    $currentInstallation = Test-JavaInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Java is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating Java..." "INFO"
    
    try {
        # Update Java using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "Java updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "Java updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "Java update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update Java: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-JavaPath {
    <#
    .SYNOPSIS
    Fix Java PATH issues
    #>
    Write-ComponentHeader "Fixing Java PATH"
    
    $javaPaths = @(
        "${env:ProgramFiles}\Java\jdk*\bin",
        "${env:ProgramFiles(x86)}\Java\jdk*\bin",
        "${env:LOCALAPPDATA}\Programs\Java\jdk*\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $javaPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found Java paths:" "INFO"
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
            Write-ComponentStep "Added Java paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "Java paths already in environment" "INFO"
        }
        
        # Set JAVA_HOME
        $javaHome = $foundPaths[0].Replace("\bin", "")
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "User")
        $env:JAVA_HOME = $javaHome
        Write-ComponentStep "Set JAVA_HOME to: $javaHome" "SUCCESS"
    } else {
        Write-ComponentStep "No Java paths found" "WARNING"
    }
}

function Uninstall-Java {
    <#
    .SYNOPSIS
    Uninstall Java
    #>
    Write-ComponentHeader "Uninstalling Java"
    
    $currentInstallation = Test-JavaInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "Java is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Removing Java from PATH..." "INFO"
    
    # Remove Java paths from environment
    $currentPath = $env:Path
    $javaPaths = $currentInstallation.Paths
    $newPath = $currentPath
    
    foreach ($path in $javaPaths) {
        $newPath = $newPath -replace [regex]::Escape($path), ""
        $newPath = $newPath -replace ";;", ";"
    }
    
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    
    # Remove JAVA_HOME
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $null, "User")
    $env:JAVA_HOME = $null
    
    Write-ComponentStep "Java removed from PATH" "SUCCESS"
    Write-ComponentStep "Manual removal of Java files may be required" "WARNING"
    
    return $true
}

function Show-JavaStatus {
    <#
    .SYNOPSIS
    Show comprehensive Java status
    #>
    Write-ComponentHeader "Java Status Report"
    
    $installation = Test-JavaInstallation -Detailed:$Detailed
    $functionality = Test-JavaFunctionality -Detailed:$Detailed
    
    Write-Host "`nInstallation Status:" -ForegroundColor Cyan
    Write-Host "  Installed: $(if ($installation.IsInstalled) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Version: $($installation.Version)" -ForegroundColor White
    Write-Host "  Executable: $($installation.ExecutablePath)" -ForegroundColor White
    Write-Host "  Javac Available: $(if ($installation.JavacAvailable) { 'Yes' } else { 'No' })" -ForegroundColor White
    Write-Host "  Javac Version: $($installation.JavacVersion)" -ForegroundColor White
    Write-Host "  Java Version: $($installation.JavaVersion)" -ForegroundColor White
    Write-Host "  JAVA_HOME: $($installation.JavaHome)" -ForegroundColor White
    
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

function Show-JavaHelp {
    <#
    .SYNOPSIS
    Show help information for Java component
    #>
    Write-ComponentHeader "Java Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install Java" -ForegroundColor White
    Write-Host "  test        - Test Java functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall Java" -ForegroundColor White
    Write-Host "  update      - Update Java" -ForegroundColor White
    Write-Host "  check       - Check Java installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix Java PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall Java" -ForegroundColor White
    Write-Host "  status      - Show Java status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\java.ps1 install                    # Install Java" -ForegroundColor White
    Write-Host "  .\java.ps1 test                       # Test Java" -ForegroundColor White
    Write-Host "  .\java.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\java.ps1 update                     # Update Java" -ForegroundColor White
    Write-Host "  .\java.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\java.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\java.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - Java version to install" -ForegroundColor White
    Write-Host "  -Silent                - Silent installation" -ForegroundColor White
    Write-Host "  -Force                 - Force installation" -ForegroundColor White
    Write-Host "  -Detailed              - Detailed output" -ForegroundColor White
    Write-Host "  -Quiet                 - Quiet mode" -ForegroundColor White
    Write-Host "  -AddToPath             - Add to PATH" -ForegroundColor White
    Write-Host "  -InstallJdk            - Install JDK" -ForegroundColor White
}

# Main execution logic
switch ($Action.ToLower()) {
    "install" {
        $result = Install-Java -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallJdk:$InstallJdk
        if ($result) {
            Write-ComponentStep "Java installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "Java installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-JavaFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "Java functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "Java functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling Java..." "INFO"
        $result = Install-Java -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallJdk:$InstallJdk
        if ($result) {
            Write-ComponentStep "Java reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Java reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-Java
        if ($result) {
            Write-ComponentStep "Java update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Java update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-JavaInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "Java is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "Java is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-JavaPath
        Write-ComponentStep "Java PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-Java
        if ($result) {
            Write-ComponentStep "Java uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "Java uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-JavaStatus
    }
    "help" {
        Show-JavaHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-JavaHelp
        exit 1
    }
}
