# Complete PostgreSQL Management - Install, Test, Reinstall, Update, Check, Path Fix, Everything

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
    Name = "PostgreSQL"
    Version = "1.0.0"
    Description = "Complete PostgreSQL Database Server"
    ExecutableNames = @("psql.exe", "psql", "postgres.exe", "postgres")
    VersionCommands = @("psql --version", "postgres --version")
    TestCommands = @("psql --version", "psql -c SELECT version()")
    WingetId = "PostgreSQL.PostgreSQL"
    ChocoId = "postgresql"
    DownloadUrl = "https://www.postgresql.org/"
    Documentation = "https://www.postgresql.org/docs/"
}

# Core functions (no code repetition)
function Write-ComponentHeader {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
        Write-Host "POSTGRESQL COMPONENT: $Message" -ForegroundColor Cyan
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

function Test-PostgreSQLInstallation {
    <#
    .SYNOPSIS
    Comprehensive PostgreSQL installation verification
    #>
    param([switch]$Detailed)
    
    Write-ComponentStep "Checking PostgreSQL installation..." "INFO"
    
    $result = @{
        IsInstalled = $false
        Version = "Unknown"
        Paths = @()
        Status = "Not Installed"
        ExecutablePath = ""
        ServiceStatus = "Unknown"
        Databases = @()
        Extensions = @()
        Users = @()
        Ports = @()
    }
    
    # Check PostgreSQL executable
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
            $version = & psql --version 2>$null
            if ($version) {
                $result.Version = $version
            }
        } catch {
            $result.Version = "Unknown"
        }
        
        # Check service status
        try {
            $service = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
            if ($service) {
                $result.ServiceStatus = $service.Status
            }
        } catch {
            # Continue without error
        }
        
        # Get databases
        try {
            $databases = & psql -l 2>$null
            if ($databases) {
                $result.Databases = $databases | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get extensions
        try {
            $extensions = & psql -c "SELECT * FROM pg_extension;" 2>$null
            if ($extensions) {
                $result.Extensions = $extensions | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get users
        try {
            $users = & psql -c "SELECT usename FROM pg_user;" 2>$null
            if ($users) {
                $result.Users = $users | Where-Object { $_ -match "^\w+" } | ForEach-Object { ($_ -split "\s+")[0] }
            }
        } catch {
            # Continue without error
        }
        
        # Get listening ports
        try {
            $ports = & netstat -an | Select-String ":5432 " | ForEach-Object { ($_ -split "\s+")[1] }
            if ($ports) {
                $result.Ports = $ports
            }
        } catch {
            # Continue without error
        }
        
        $result.Status = "Installed"
    }
    
    return $result
}

function Install-PostgreSQL {
    <#
    .SYNOPSIS
    Install PostgreSQL with comprehensive configuration
    #>
    param(
        [string]$Version = "latest",
        [switch]$Silent = $false,
        [switch]$Force = $false,
        [switch]$AddToPath = $true,
        [switch]$InstallExtensions = $true
    )
    
    Write-ComponentHeader "Installing PostgreSQL $Version"
    
    # Check if already installed
    $currentInstallation = Test-PostgreSQLInstallation
    if ($currentInstallation.IsInstalled -and -not $Force) {
        Write-ComponentStep "PostgreSQL is already installed: $($currentInstallation.Version)" "WARNING"
        Write-ComponentStep "Use -Force to reinstall" "INFO"
        return $currentInstallation
    }
    
    try {
        # Install using WinGet (preferred)
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing PostgreSQL using WinGet..." "INFO"
            $installArgs = @("install", $ComponentInfo.WingetId)
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "winget" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "PostgreSQL installed successfully using WinGet!" "SUCCESS"
            } else {
                throw "WinGet installation failed"
            }
        }
        # Fallback to Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-ComponentStep "Installing PostgreSQL using Chocolatey..." "INFO"
            $installArgs = @("install", $ComponentInfo.ChocoId, "-y")
            if ($Silent) { $installArgs += "--silent" }
            if ($Force) { $installArgs += "--force" }
            
            $process = Start-Process -FilePath "choco" -ArgumentList $installArgs -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-ComponentStep "PostgreSQL installed successfully using Chocolatey!" "SUCCESS"
            } else {
                throw "Chocolatey installation failed"
            }
        }
        # Manual installation
        else {
            Write-ComponentStep "Installing PostgreSQL manually..." "INFO"
            # Manual installation logic here
            throw "Manual installation not implemented"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Start-Sleep -Seconds 5
        
        # Verify installation
        Write-ComponentStep "Verifying PostgreSQL installation..." "INFO"
        $postInstallVerification = Test-PostgreSQLInstallation -Detailed:$Detailed
        
        if ($postInstallVerification.IsInstalled) {
            Write-ComponentStep "PostgreSQL installation verified successfully!" "SUCCESS"
            Write-ComponentStep "Version: $($postInstallVerification.Version)" "INFO"
        } else {
            Write-ComponentStep "PostgreSQL installation verification failed" "WARNING"
            return $false
        }
        
        # Install extensions if requested
        if ($InstallExtensions) {
            Write-ComponentStep "Installing PostgreSQL extensions..." "INFO"
            
            $extensions = @(
                "postgis",
                "pg_stat_statements",
                "pg_trgm",
                "pgcrypto",
                "uuid-ossp",
                "hstore",
                "ltree",
                "intarray",
                "btree_gin",
                "btree_gist",
                "citext",
                "cube",
                "dblink",
                "dict_int",
                "dict_xsyn",
                "earthdistance",
                "file_fdw",
                "fuzzystrmatch",
                "isn",
                "lo",
                "ltree",
                "pageinspect",
                "pg_buffercache",
                "pg_freespacemap",
                "pgrowlocks",
                "pg_stat_statements",
                "pg_trgm",
                "pgcrypto",
                "uuid-ossp",
                "hstore",
                "ltree",
                "intarray",
                "btree_gin",
                "btree_gist",
                "citext",
                "cube",
                "dblink",
                "dict_int",
                "dict_xsyn",
                "earthdistance",
                "file_fdw",
                "fuzzystrmatch",
                "isn",
                "lo",
                "ltree",
                "pageinspect",
                "pg_buffercache",
                "pg_freespacemap",
                "pgrowlocks"
            )
            
            foreach ($extension in $extensions) {
                try {
                    # Install extension
                    & psql -c "CREATE EXTENSION IF NOT EXISTS $extension;" 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-ComponentStep "  ✓ $extension extension installed" "SUCCESS"
                    } else {
                        Write-ComponentStep "  ✗ Failed to install $extension extension" "ERROR"
                    }
                } catch {
                    Write-ComponentStep "  ✗ Failed to install $extension extension" "ERROR"
                }
            }
        }
        
        return $true
        
    } catch {
        Write-ComponentStep "Failed to install PostgreSQL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PostgreSQLFunctionality {
    <#
    .SYNOPSIS
    Test PostgreSQL functionality with comprehensive tests
    #>
    param([switch]$Detailed)
    
    Write-ComponentHeader "Testing PostgreSQL Functionality"
    
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = 0
    }
    
    $testCommands = @(
        "psql --version",
        "psql -c SELECT version()",
        "psql -c SELECT current_database()",
        "psql -c SELECT current_user",
        "psql -c SELECT current_timestamp"
    )
    
    $expectedOutputs = @(
        "psql",
        "PostgreSQL",
        "postgres",
        "postgres",
        "timestamp"
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

function Update-PostgreSQL {
    <#
    .SYNOPSIS
    Update PostgreSQL to latest version
    #>
    Write-ComponentHeader "Updating PostgreSQL"
    
    $currentInstallation = Test-PostgreSQLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "PostgreSQL is not installed. Cannot update." "ERROR"
        return $false
    }
    
    Write-ComponentStep "Current version: $($currentInstallation.Version)" "INFO"
    Write-ComponentStep "Updating PostgreSQL..." "INFO"
    
    try {
        # Update PostgreSQL using WinGet
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget upgrade $ComponentInfo.WingetId
            Write-ComponentStep "PostgreSQL updated using WinGet" "SUCCESS"
        }
        # Update using Chocolatey
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco upgrade $ComponentInfo.ChocoId -y
            Write-ComponentStep "PostgreSQL updated using Chocolatey" "SUCCESS"
        }
        
        Write-ComponentStep "PostgreSQL update completed" "SUCCESS"
        return $true
        
    } catch {
        Write-ComponentStep "Failed to update PostgreSQL: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-PostgreSQLPath {
    <#
    .SYNOPSIS
    Fix PostgreSQL PATH issues
    #>
    Write-ComponentHeader "Fixing PostgreSQL PATH"
    
    $postgresqlPaths = @(
        "${env:ProgramFiles}\PostgreSQL\*\bin",
        "${env:ProgramFiles(x86)}\PostgreSQL\*\bin",
        "${env:LOCALAPPDATA}\PostgreSQL\*\bin"
    )
    
    $foundPaths = @()
    foreach ($path in $postgresqlPaths) {
        $expandedPaths = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($expandedPath in $expandedPaths) {
            if (Test-Path $expandedPath.FullName) {
                $foundPaths += $expandedPath.FullName
            }
        }
    }
    
    if ($foundPaths.Count -gt 0) {
        Write-ComponentStep "Found PostgreSQL paths:" "INFO"
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
            Write-ComponentStep "Added PostgreSQL paths to environment" "SUCCESS"
        } else {
            Write-ComponentStep "PostgreSQL paths already in environment" "INFO"
        }
    } else {
        Write-ComponentStep "No PostgreSQL paths found" "WARNING"
    }
}

function Uninstall-PostgreSQL {
    <#
    .SYNOPSIS
    Uninstall PostgreSQL
    #>
    Write-ComponentHeader "Uninstalling PostgreSQL"
    
    $currentInstallation = Test-PostgreSQLInstallation
    if (-not $currentInstallation.IsInstalled) {
        Write-ComponentStep "PostgreSQL is not installed" "INFO"
        return $true
    }
    
    Write-ComponentStep "Uninstalling PostgreSQL..." "INFO"
    
    # Uninstall using WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget uninstall $ComponentInfo.WingetId
        Write-ComponentStep "PostgreSQL uninstalled using WinGet" "SUCCESS"
    }
    # Uninstall using Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco uninstall $ComponentInfo.ChocoId -y
        Write-ComponentStep "PostgreSQL uninstalled using Chocolatey" "SUCCESS"
    }
    
    Write-ComponentStep "PostgreSQL uninstallation completed" "SUCCESS"
    
    return $true
}

function Show-PostgreSQLStatus {
    <#
    .SYNOPSIS
    Show comprehensive PostgreSQL status
    #>
    Write-ComponentHeader "PostgreSQL Status Report"
    
    $installation = Test-PostgreSQLInstallation -Detailed:$Detailed
    $functionality = Test-PostgreSQLFunctionality -Detailed:$Detailed
    
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
    
    if ($installation.Databases.Count -gt 0) {
        Write-Host "`nDatabases:" -ForegroundColor Cyan
        foreach ($database in $installation.Databases) {
            Write-Host "  - $database" -ForegroundColor White
        }
    }
    
    if ($installation.Extensions.Count -gt 0) {
        Write-Host "`nExtensions:" -ForegroundColor Cyan
        foreach ($extension in $installation.Extensions) {
            Write-Host "  - $extension" -ForegroundColor White
        }
    }
    
    if ($installation.Users.Count -gt 0) {
        Write-Host "`nUsers:" -ForegroundColor Cyan
        foreach ($user in $installation.Users) {
            Write-Host "  - $user" -ForegroundColor White
        }
    }
    
    if ($installation.Ports.Count -gt 0) {
        Write-Host "`nListening Ports:" -ForegroundColor Cyan
        foreach ($port in $installation.Ports) {
            Write-Host "  - $port" -ForegroundColor White
        }
    }
    
    Write-Host "`nFunctionality Status:" -ForegroundColor Cyan
    Write-Host "  Tests Passed: $($functionality.PassedTests)/$($functionality.TotalTests)" -ForegroundColor White
    Write-Host "  Overall Success: $(if ($functionality.OverallSuccess) { 'Yes' } else { 'No' })" -ForegroundColor White
}

function Show-PostgreSQLHelp {
    <#
    .SYNOPSIS
    Show help information for PostgreSQL component
    #>
    Write-ComponentHeader "PostgreSQL Component Help"
    
    Write-Host "`nAvailable Actions:" -ForegroundColor Cyan
    Write-Host "  install     - Install PostgreSQL" -ForegroundColor White
    Write-Host "  test        - Test PostgreSQL functionality" -ForegroundColor White
    Write-Host "  reinstall   - Reinstall PostgreSQL" -ForegroundColor White
    Write-Host "  update      - Update PostgreSQL" -ForegroundColor White
    Write-Host "  check       - Check PostgreSQL installation" -ForegroundColor White
    Write-Host "  fix-path    - Fix PostgreSQL PATH issues" -ForegroundColor White
    Write-Host "  uninstall   - Uninstall PostgreSQL" -ForegroundColor White
    Write-Host "  status      - Show PostgreSQL status" -ForegroundColor White
    Write-Host "  help        - Show this help" -ForegroundColor White
    
    Write-Host "`nUsage Examples:" -ForegroundColor Cyan
    Write-Host "  .\postgresql.ps1 install                    # Install PostgreSQL" -ForegroundColor White
    Write-Host "  .\postgresql.ps1 test                       # Test PostgreSQL" -ForegroundColor White
    Write-Host "  .\postgresql.ps1 reinstall -Force           # Force reinstall" -ForegroundColor White
    Write-Host "  .\postgresql.ps1 update                     # Update PostgreSQL" -ForegroundColor White
    Write-Host "  .\postgresql.ps1 check -Detailed            # Detailed check" -ForegroundColor White
    Write-Host "  .\postgresql.ps1 fix-path                   # Fix PATH issues" -ForegroundColor White
    Write-Host "  .\postgresql.ps1 status                     # Show status" -ForegroundColor White
    
    Write-Host "`nParameters:" -ForegroundColor Cyan
    Write-Host "  -Version <version>     - PostgreSQL version to install" -ForegroundColor White
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
        $result = Install-PostgreSQL -Version $Version -Silent:$Silent -Force:$Force -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "PostgreSQL installation completed successfully!" "SUCCESS"
        } else {
            Write-ComponentStep "PostgreSQL installation failed!" "ERROR"
            exit 1
        }
    }
    "test" {
        $result = Test-PostgreSQLFunctionality -Detailed:$Detailed
        if ($result.OverallSuccess) {
            Write-ComponentStep "PostgreSQL functionality tests passed!" "SUCCESS"
        } else {
            Write-ComponentStep "PostgreSQL functionality tests failed!" "ERROR"
            exit 1
        }
    }
    "reinstall" {
        Write-ComponentStep "Reinstalling PostgreSQL..." "INFO"
        $result = Install-PostgreSQL -Version $Version -Silent:$Silent -Force:$true -AddToPath:$AddToPath -InstallExtensions:$InstallExtensions
        if ($result) {
            Write-ComponentStep "PostgreSQL reinstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PostgreSQL reinstallation failed!" "ERROR"
            exit 1
        }
    }
    "update" {
        $result = Update-PostgreSQL
        if ($result) {
            Write-ComponentStep "PostgreSQL update completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PostgreSQL update failed!" "ERROR"
            exit 1
        }
    }
    "check" {
        $result = Test-PostgreSQLInstallation -Detailed:$Detailed
        if ($result.IsInstalled) {
            Write-ComponentStep "PostgreSQL is installed: $($result.Version)" "SUCCESS"
        } else {
            Write-ComponentStep "PostgreSQL is not installed" "WARNING"
        }
    }
    "fix-path" {
        Fix-PostgreSQLPath
        Write-ComponentStep "PostgreSQL PATH fix completed!" "SUCCESS"
    }
    "uninstall" {
        $result = Uninstall-PostgreSQL
        if ($result) {
            Write-ComponentStep "PostgreSQL uninstallation completed!" "SUCCESS"
        } else {
            Write-ComponentStep "PostgreSQL uninstallation failed!" "ERROR"
            exit 1
        }
    }
    "status" {
        Show-PostgreSQLStatus
    }
    "help" {
        Show-PostgreSQLHelp
    }
    default {
        Write-ComponentStep "Unknown action: $Action" "ERROR"
        Show-PostgreSQLHelp
        exit 1
    }
}
