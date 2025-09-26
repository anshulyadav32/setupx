<#
.SYNOPSIS
    Enhanced Software Verification Module
.DESCRIPTION
    Provides comprehensive software installation verification with version checking, 
    path validation, and functionality testing for the Windows Development Toolkit
#>

# Import logging module
$LoggingModule = Join-Path (Split-Path (Split-Path $PSCommandPath)) "Core\LoggingProvider.psm1"
if (Test-Path $LoggingModule) {
    Import-Module $LoggingModule -Force -DisableNameChecking
}

# Enhanced software verification result class
class SoftwareVerificationResult {
    [bool]$IsInstalled
    [string]$Version
    [string]$InstallPath
    [bool]$PathValid
    [string]$ExecutablePath
    [string]$Status
    [string]$ErrorMessage
    [hashtable]$AdditionalInfo
    [datetime]$VerificationTime
    [int]$VerificationDuration
    [object]$Logger
    
    SoftwareVerificationResult() {
        $this.IsInstalled = $false
        $this.Version = "Unknown"
        $this.InstallPath = ""
        $this.PathValid = $false
        $this.ExecutablePath = ""
        $this.Status = "Not Verified"
        $this.ErrorMessage = ""
        $this.AdditionalInfo = @{}
        $this.VerificationTime = Get-Date
        $this.VerificationDuration = 0
        $this.Logger = Initialize-ToolkitLogging -LogLevel "Info"
    }
    
    [void] SetSuccess([string]$Message) {
        $this.Status = "Verified"
        $this.Logger.Success($Message)
    }
    
    [void] SetError([string]$Message) {
        $this.Status = "Error"
        $this.ErrorMessage = $Message
        $this.Logger.Failure($Message)
    }
    
    [void] SetWarning([string]$Message) {
        $this.Status = "Warning"
        $this.Logger.Warning($Message)
    }
}

# Main verification function
function Test-SoftwareInstallation {
    <#
    .SYNOPSIS
        Tests software installation with comprehensive verification
    .PARAMETER SoftwareName
        Name of the software to verify
    .PARAMETER ExecutableNames
        Array of executable names to check
    .PARAMETER VersionCommands
        Array of version commands to execute
    .PARAMETER CommonPaths
        Array of common installation paths
    .PARAMETER RegistryKeys
        Array of registry keys to check
    .PARAMETER TestCommands
        Array of test commands to verify functionality
    .PARAMETER ExpectedOutputs
        Array of expected outputs for test commands
    .PARAMETER Detailed
        Whether to provide detailed output
    .PARAMETER Quiet
        Whether to suppress output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExecutableNames = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$VersionCommands = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$CommonPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$RegistryKeys = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$TestCommands = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExpectedOutputs = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet = $false
    )
    
    $result = [SoftwareVerificationResult]::new()
    $result.AdditionalInfo["SoftwareName"] = $SoftwareName
    $startTime = Get-Date
    
    try {
        if (-not $Quiet) {
            $result.Logger.Info("Verifying $SoftwareName installation")
        }
        
        # Step 1: Check if executable is in PATH
        $foundInPath = $false
        foreach ($exe in $ExecutableNames) {
            $command = Get-Command $exe -ErrorAction SilentlyContinue
            if ($command) {
                $result.IsInstalled = $true
                $result.ExecutablePath = $command.Source
                $result.PathValid = Test-Path $command.Source
                $foundInPath = $true
                
                if (-not $Quiet) {
                    $result.Logger.Success("$exe found in PATH: $($command.Source)")
                }
                break
            }
        }
        
        # Step 2: Try version commands to get version info
        if ($foundInPath -and $VersionCommands.Count -gt 0) {
            foreach ($versionCmd in $VersionCommands) {
                try {
                    $versionOutput = Invoke-Expression $versionCmd 2>$null
                    if ($versionOutput) {
                        $result.Version = ($versionOutput | Select-Object -First 3) -join " "
                        if (-not $Quiet) {
                            $result.Logger.Success("Version detected: $($result.Version)")
                        }
                        break
                    }
                } catch {
                    # Continue to next version command
                }
            }
        }
        
        # Step 3: Check common installation paths
        if (-not $foundInPath -and $CommonPaths.Count -gt 0) {
            foreach ($path in $CommonPaths) {
                $expandedPath = [System.Environment]::ExpandEnvironmentVariables($path)
                if (Test-Path $expandedPath) {
                    $result.IsInstalled = $true
                    $result.InstallPath = $expandedPath
                    $result.PathValid = $true
                    
                    if (-not $Quiet) {
                        $result.Logger.Success("Found installation at: $expandedPath")
                    }
                    
                    # Try to find executable in this path
                    foreach ($exe in $ExecutableNames) {
                        $exePath = Join-Path $expandedPath $exe
                        if (Test-Path $exePath) {
                            $result.ExecutablePath = $exePath
                            if (-not $Quiet) {
                                $result.Logger.Success("Executable found: $exePath")
                            }
                            break
                        }
                    }
                    break
                }
            }
        }
        
        # Step 4: Check registry keys
        if (-not $result.IsInstalled -and $RegistryKeys.Count -gt 0) {
            foreach ($regKey in $RegistryKeys) {
                try {
                    $regValue = Get-ItemProperty -Path $regKey -ErrorAction SilentlyContinue
                    if ($regValue) {
                        $result.IsInstalled = $true
                        
                        # Try to get install path from registry
                        $installPath = $regValue.InstallLocation -or $regValue.InstallPath -or $regValue.Path
                        if ($installPath -and (Test-Path $installPath)) {
                            $result.InstallPath = $installPath
                            $result.PathValid = $true
                            
                            if (-not $Quiet) {
                                $result.Logger.Success("Found in registry with valid path: $installPath")
                            }
                        } else {
                            if (-not $Quiet) {
                                $result.Logger.Warning("Installation path exists in registry but is not accessible")
                            }
                        }
                        
                        # Try to get version from registry
                        $version = $regValue.Version -or $regValue.DisplayVersion
                        if ($version) {
                            $result.Version = $version
                            if (-not $Quiet) {
                                $result.Logger.Success("Version from registry: $version")
                            }
                        }
                        break
                    }
                } catch {
                    # Continue to next registry key
                }
            }
        }
        
        # Step 5: Test functionality if installed
        if ($result.IsInstalled -and $TestCommands.Count -gt 0) {
            $functionalityResult = Test-SoftwareFunctionality -SoftwareName $SoftwareName -TestCommands $TestCommands -ExpectedOutputs $ExpectedOutputs -Quiet:$Quiet
            $result.AdditionalInfo["FunctionalityTest"] = $functionalityResult
            
            if (-not $functionalityResult.OverallSuccess) {
                $result.SetWarning("Software installed but functionality test failed")
            }
        }
        
        # Set final status
        if ($result.IsInstalled) {
            $result.SetSuccess("$SoftwareName verification completed successfully")
        } else {
            $result.SetError("$SoftwareName is not installed or not detectable")
        }
        
    } catch {
        $result.SetError("Verification failed: $($_.Exception.Message)")
    }
    
    $result.VerificationDuration = [int]((Get-Date) - $startTime).TotalSeconds
    return $result
}

function Test-SoftwareFunctionality {
    <#
    .SYNOPSIS
        Tests software functionality with comprehensive test suite
    .PARAMETER SoftwareName
        Name of the software to test
    .PARAMETER TestCommands
        Array of test commands to execute
    .PARAMETER ExpectedOutputs
        Array of expected outputs
    .PARAMETER Quiet
        Whether to suppress output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SoftwareName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$TestCommands = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExpectedOutputs = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet = $false
    )
    
    $logger = Initialize-ToolkitLogging -LogLevel "Info"
    $results = @{
        OverallSuccess = $false
        TestResults = @()
        PassedTests = 0
        TotalTests = $TestCommands.Count
        ErrorMessage = ""
        TestDuration = 0
    }
    
    $startTime = Get-Date
    
    if ($TestCommands.Count -eq 0) {
        if (-not $Quiet) {
            $logger.Warning("No test commands defined for $SoftwareName")
        }
        $results.OverallSuccess = $true
        return $results
    }
    
    if (-not $Quiet) {
        $logger.Info("Testing $SoftwareName functionality")
    }
    
    for ($i = 0; $i -lt $TestCommands.Count; $i++) {
        $testCmd = $TestCommands[$i]
        $expectedOutput = if ($i -lt $ExpectedOutputs.Count) { $ExpectedOutputs[$i] } else { $null }
        
        try {
            if (-not $Quiet) {
                $logger.Step("Testing: $testCmd")
            }
            
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
                Timestamp = Get-Date
            }
            
            if ($testPassed) {
                $results.PassedTests++
                if (-not $Quiet) {
                    $logger.Success("Test passed")
                }
            } else {
                if (-not $Quiet) {
                    $logger.Failure("Test failed (Expected: $expectedOutput, Got: $output)")
                }
            }
        } catch {
            $results.TestResults += @{
                Command = $testCmd
                Output = $null
                Expected = $expectedOutput
                Passed = $false
                Error = $_.Exception.Message
                Timestamp = Get-Date
            }
            if (-not $Quiet) {
                $logger.Failure("Test error: $($_.Exception.Message)")
            }
        }
    }
    
    $results.TestDuration = [int]((Get-Date) - $startTime).TotalSeconds
    $results.OverallSuccess = ($results.PassedTests -ge ($results.TotalTests * 0.7))  # 70% pass rate
    
    if (-not $Quiet) {
        if ($results.OverallSuccess) {
            $logger.Success("Functionality test passed ($($results.PassedTests)/$($results.TotalTests))")
        } else {
            $logger.Failure("Functionality test failed ($($results.PassedTests)/$($results.TotalTests))")
        }
    }
    
    return $results
}

function Test-MultipleSoftware {
    <#
    .SYNOPSIS
        Tests multiple software installations
    .PARAMETER SoftwareList
        Array of software names to test
    .PARAMETER SoftwareDefinitions
        Hashtable of software definitions
    .PARAMETER Detailed
        Whether to provide detailed output
    .PARAMETER Quiet
        Whether to suppress output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$SoftwareList,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SoftwareDefinitions = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$Quiet = $false
    )
    
    $logger = Initialize-ToolkitLogging -LogLevel "Info"
    $results = @{}
    
    if (-not $Quiet) {
        $logger.Info("Testing multiple software installations")
    }
    
    foreach ($software in $SoftwareList) {
        $config = $SoftwareDefinitions[$software]
        if ($config) {
            $results[$software] = Test-SoftwareInstallation @config -SoftwareName $software -Detailed:$Detailed -Quiet:$Quiet
        } else {
            # Fallback to basic detection
            $results[$software] = Test-SoftwareInstallation -SoftwareName $software -Detailed:$Detailed -Quiet:$Quiet
        }
    }
    
    if (-not $Quiet) {
        $installed = ($results.Values | Where-Object { $_.IsInstalled }).Count
        $total = $results.Count
        
        $logger.Info("Total software checked: $total")
        $logger.Info("Successfully verified: $installed")
        $notFound = $total - $installed
        $logger.Info("Not found or failed: $notFound")
        
        foreach ($software in $SoftwareList) {
            $result = $results[$software]
            if ($result.IsInstalled) {
                $status = "✓ Installed"
                if ($result.Version -ne "Unknown") {
                    $status += " (v$($result.Version))"
                }
                $logger.Success("$software : $status")
            } else {
                $logger.Failure("$software : ✗ Not Found")
            }
        }
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function @(
    'Test-SoftwareInstallation',
    'Test-SoftwareFunctionality',
    'Test-MultipleSoftware'
)
