#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Development Toolkit - Main Module
.DESCRIPTION
    Provides a comprehensive, modular framework for setting up Windows development environments.
    Supports installation, configuration, testing, and management of development tools.
    
.NOTES
    Version: 2.0.0
    Author: Windows Development Toolkit Team
    Last Updated: 2024
#>

# Import required modules
$ModuleRoot = Split-Path -Parent $PSCommandPath
$CoreModules = @(
    'ConfigurationManager',
    'LoggingProvider',
    'SystemValidator'
)

foreach ($Module in $CoreModules) {
    $ModulePath = Join-Path $ModuleRoot "$Module.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force -DisableNameChecking
    }
}

# Import installer modules
$InstallerModules = @(
    'PackageManagerInstaller',
    'DevelopmentToolsInstaller', 
    'CloudToolsInstaller',
    'ApplicationInstaller',
    'AIToolsInstaller'
)

foreach ($Module in $InstallerModules) {
    $ModulePath = Join-Path (Split-Path $ModuleRoot) "Installers\$Module.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force -DisableNameChecking
    }
}

# Import verification modules
$VerificationModules = @(
    'SoftwareVerification',
    'TestFramework',
    'ValidationEngine'
)

foreach ($Module in $VerificationModules) {
    $ModulePath = Join-Path (Split-Path $ModuleRoot) "Verification\$Module.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force -DisableNameChecking
    }
}

# Import configuration modules
$ConfigModules = @(
    'TerminalConfigurator',
    'PowerShellConfigurator',
    'ToolConfigurator',
    'AIConfigurator'
)

foreach ($Module in $ConfigModules) {
    $ModulePath = Join-Path (Split-Path $ModuleRoot) "Configuration\$Module.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force -DisableNameChecking
    }
}

# Toolkit Configuration Class
class WindowsDevToolkit {
    [string]$Version = "2.0.0"
    [string]$ConfigPath
    [hashtable]$Configuration
    [object]$Logger
    [object]$SystemValidator
    [bool]$IsInitialized = $false
    [hashtable]$InstallResults = @{}
    [hashtable]$TestResults = @{}
    [hashtable]$ConfigResults = @{}
    
    WindowsDevToolkit() {
        $this.Initialize()
    }
    
    [void] Initialize() {
        try {
            # Initialize logging
            $this.Logger = Initialize-ToolkitLogging -LogLevel "Info"
            $this.Logger.Info("Initializing Windows Development Toolkit v$($this.Version)")
            
            # Initialize system validator
            $this.SystemValidator = Initialize-SystemValidator
            
            # Load configuration
            $this.ConfigPath = Get-ToolkitConfigPath
            $this.Configuration = Get-ToolkitConfiguration -ConfigPath $this.ConfigPath
            
            # Validate system requirements
            $validationResult = $this.SystemValidator.ValidateSystemRequirements()
            if (-not $validationResult.IsValid) {
                throw "System validation failed: $($validationResult.ErrorMessage)"
            }
            
            $this.IsInitialized = $true
            $this.Logger.Success("Toolkit initialized successfully")
        }
        catch {
            throw "Failed to initialize toolkit: $($_.Exception.Message)"
        }
    }
    
    [hashtable] InstallCategory([string]$Category, [hashtable]$Options = @{}) {
        if (-not $this.IsInitialized) { throw "Toolkit not initialized" }
        
        $this.Logger.Info("Installing category: $Category")
        
        $result = switch ($Category.ToLower()) {
            "package-managers" { 
                $this.InstallResults["package-managers"] = Install-PackageManagers @Options
                $this.InstallResults["package-managers"]
            }
            "development-tools" { 
                $this.InstallResults["development-tools"] = Install-DevelopmentTools @Options
                $this.InstallResults["development-tools"]
            }
            "cloud-tools" { 
                $this.InstallResults["cloud-tools"] = Install-CloudTools @Options
                $this.InstallResults["cloud-tools"]
            }
            "applications" { 
                $this.InstallResults["applications"] = Install-Applications @Options
                $this.InstallResults["applications"]
            }
            "ai-tools" { 
                $this.InstallResults["ai-tools"] = Install-AITools @Options
                $this.InstallResults["ai-tools"]
            }
            default { throw "Unknown category: $Category" }
        }
        
        return $result
    }
    
    [hashtable] TestCategory([string]$Category, [hashtable]$Options = @{}) {
        if (-not $this.IsInitialized) { throw "Toolkit not initialized" }
        
        $this.Logger.Info("Testing category: $Category")
        
        $result = switch ($Category.ToLower()) {
            "package-managers" { 
                $this.TestResults["package-managers"] = Test-PackageManagers @Options
                $this.TestResults["package-managers"]
            }
            "development-tools" { 
                $this.TestResults["development-tools"] = Test-DevelopmentTools @Options
                $this.TestResults["development-tools"]
            }
            "cloud-tools" { 
                $this.TestResults["cloud-tools"] = Test-CloudTools @Options
                $this.TestResults["cloud-tools"]
            }
            "applications" { 
                $this.TestResults["applications"] = Test-Applications @Options
                $this.TestResults["applications"]
            }
            "ai-tools" { 
                $this.TestResults["ai-tools"] = Test-AITools @Options
                $this.TestResults["ai-tools"]
            }
            "all" { 
                $this.TestResults["all"] = Test-AllCategories @Options
                $this.TestResults["all"]
            }
            default { throw "Unknown category: $Category" }
        }
        
        return $result
    }
    
    [hashtable] ConfigureCategory([string]$Category, [hashtable]$Options = @{}) {
        if (-not $this.IsInitialized) { throw "Toolkit not initialized" }
        
        $this.Logger.Info("Configuring category: $Category")
        
        $result = switch ($Category.ToLower()) {
            "terminal" { 
                $this.ConfigResults["terminal"] = Set-TerminalConfiguration @Options
                $this.ConfigResults["terminal"]
            }
            "powershell" { 
                $this.ConfigResults["powershell"] = Set-PowerShellConfiguration @Options
                $this.ConfigResults["powershell"]
            }
            "tools" { 
                $this.ConfigResults["tools"] = Set-ToolConfiguration @Options
                $this.ConfigResults["tools"]
            }
            "ai-tools" { 
                $this.ConfigResults["ai-tools"] = Set-AIConfiguration @Options
                $this.ConfigResults["ai-tools"]
            }
            default { throw "Unknown configuration category: $Category" }
        }
        
        return $result
    }
    
    [hashtable] GetStatus() {
        return @{
            IsInitialized = $this.IsInitialized
            Version = $this.Version
            InstallResults = $this.InstallResults
            TestResults = $this.TestResults
            ConfigResults = $this.ConfigResults
            Configuration = $this.Configuration
        }
    }
    
    [void] Reset() {
        $this.InstallResults = @{}
        $this.TestResults = @{}
        $this.ConfigResults = @{}
        $this.Logger.Info("Toolkit state reset")
    }
}

# Main toolkit functions
function Initialize-WindowsDevToolkit {
    <#
    .SYNOPSIS
        Initializes the Windows Development Toolkit
    .DESCRIPTION
        Creates and returns a new WindowsDevToolkit instance with full functionality
    #>
    [CmdletBinding()]
    param()
    
    try {
        return [WindowsDevToolkit]::new()
    }
    catch {
        Write-Error "Failed to initialize Windows Development Toolkit: $($_.Exception.Message)"
        throw
    }
}

function Install-ToolkitCategory {
    <#
    .SYNOPSIS
        Installs tools from a specific category
    .PARAMETER Category
        The category to install (package-managers, development-tools, cloud-tools, applications, ai-tools)
    .PARAMETER Options
        Installation options
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("package-managers", "development-tools", "cloud-tools", "applications", "ai-tools")]
        [string]$Category,
        
        [hashtable]$Options = @{}
    )
    
    $toolkit = Initialize-WindowsDevToolkit
    return $toolkit.InstallCategory($Category, $Options)
}

function Test-ToolkitCategory {
    <#
    .SYNOPSIS
        Tests tools from a specific category
    .PARAMETER Category
        The category to test
    .PARAMETER Options
        Testing options
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("package-managers", "development-tools", "cloud-tools", "applications", "ai-tools", "all")]
        [string]$Category,
        
        [hashtable]$Options = @{}
    )
    
    $toolkit = Initialize-WindowsDevToolkit
    return $toolkit.TestCategory($Category, $Options)
}

function Set-ToolkitConfiguration {
    <#
    .SYNOPSIS
        Configures tools from a specific category
    .PARAMETER Category
        The configuration category
    .PARAMETER Options
        Configuration options
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("terminal", "powershell", "tools", "ai-tools")]
        [string]$Category,
        
        [hashtable]$Options = @{}
    )
    
    $toolkit = Initialize-WindowsDevToolkit
    return $toolkit.ConfigureCategory($Category, $Options)
}

function Get-ToolkitStatus {
    <#
    .SYNOPSIS
        Gets the current toolkit status
    #>
    [CmdletBinding()]
    param()
    
    $toolkit = Initialize-WindowsDevToolkit
    return $toolkit.GetStatus()
}

# Export public functions
Export-ModuleMember -Function @(
    'Initialize-WindowsDevToolkit',
    'Install-ToolkitCategory',
    'Test-ToolkitCategory',
    'Set-ToolkitConfiguration',
    'Get-ToolkitStatus'
)
