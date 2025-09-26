# SetWinX CLI - Windows Development Environment Setup
param(
    [string]$Target = "help", 
    [string]$Component = "help",
    [string]$Module = "",
    [switch]$List,
    [switch]$ShowVersion,
    [switch]$All,
    [switch]$PackageManagers,
    [switch]$DevTools,
    [switch]$Install,
    [switch]$Setup,
    [switch]$Status,
    [switch]$Force,
    [switch]$Verbose,
    [switch]$ShowCommands,
    [Alias("lm")][switch]$ListModules
)

$SETWINX_VERSION = "1.0.0"
$SCRIPT_DIR = Split-Path $MyInvocation.MyCommand.Path -Parent

# Component lists (defined early for function access)
$packageManagerList = @("scoop", "winget", "choco")
$devToolsList = @("git", "gh", "vscode", "docker", "node", "python", "terminal")
$allComponentsList = $packageManagerList + $devToolsList

# Function to display modules in a concise format
function Show-ModuleList {
    Write-Host "SetWinX v$SETWINX_VERSION - Available Modules" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Package Managers:" -ForegroundColor Green
    foreach ($module in $packageManagerList) {
        Write-Host "  $module" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Development Tools:" -ForegroundColor Green
    foreach ($module in $devToolsList) {
        Write-Host "  $module" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Module Groups:" -ForegroundColor Green
    Write-Host "  all               - All components" -ForegroundColor White
    Write-Host "  package-managers  - All package managers" -ForegroundColor White
    Write-Host "  dev-tools         - All development tools" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  setwinx --status --module git           # Check git status" -ForegroundColor White
    Write-Host "  setwinx --status --module dev-tools     # Check all dev tools" -ForegroundColor White
    
    exit 0
}

# Component definitions with detailed information
$COMPONENT_INFO = @{
    "scoop" = @{
        "category" = "Package Manager"
        "description" = "Scoop - Command-line installer for Windows that installs programs from the command line with minimal friction"
        "features" = @("Package management", "Bucket system", "Easy uninstalls", "No admin rights required")
        "install_cmd" = "setwinx scoop auto"
        "test_cmd" = "setwinx scoop test"
        "script_path" = "core\package-managers\scoop.ps1"
    }
    "winget" = @{
        "category" = "Package Manager"
        "description" = "Windows Package Manager - Official Microsoft package manager for Windows 10 and Windows 11"
        "features" = @("Official Microsoft tool", "Integrates with Microsoft Store", "System-wide installations")
        "install_cmd" = "setwinx winget auto"
        "test_cmd" = "setwinx winget test"
        "script_path" = "core\package-managers\winget.ps1"
    }
    "choco" = @{
        "category" = "Package Manager"
        "description" = "Chocolatey - Community-driven package manager for Windows with extensive software repository"
        "features" = @("Largest Windows package repository", "Community packages", "System-wide installations", "Advanced package management")
        "install_cmd" = "setwinx choco auto"
        "test_cmd" = "setwinx choco test"
        "script_path" = "core\package-managers\choco.ps1"
    }
    "git" = @{
        "category" = "Development Tool"
        "description" = "Git - Distributed version control system for tracking changes in source code during software development"
        "features" = @("Version control", "Branch management", "SSH key setup", "Global configuration")
        "install_cmd" = "setwinx git auto"
        "test_cmd" = "setwinx git test"
        "script_path" = "core\development-tools\git.ps1"
    }
    "gh" = @{
        "category" = "Development Tool"
        "description" = "GitHub CLI - Official command-line interface for GitHub with authentication and repository management"
        "features" = @("GitHub authentication", "Repository management", "Issue tracking", "Extension support")
        "install_cmd" = "setwinx gh auto"
        "test_cmd" = "setwinx gh test"
        "script_path" = "core\development-tools\gh.ps1"
    }
    "vscode" = @{
        "category" = "Development Tool"
        "description" = "Visual Studio Code - Lightweight but powerful source code editor with extensive extension ecosystem"
        "features" = @("IntelliSense", "Extension marketplace", "Integrated terminal", "Git integration")
        "install_cmd" = "setwinx vscode auto"
        "test_cmd" = "setwinx vscode test"
        "script_path" = "core\development-tools\vscode.ps1"
    }
    "docker" = @{
        "category" = "Development Tool"
        "description" = "Docker Desktop - Containerization platform for developing, shipping, and running applications"
        "features" = @("Container management", "Docker Compose", "Kubernetes support", "GUI interface")
        "install_cmd" = "setwinx docker auto"
        "test_cmd" = "setwinx docker test"
        "script_path" = "core\development-tools\docker.ps1"
    }
    "node" = @{
        "category" = "Development Tool"
        "description" = "Node.js LTS - JavaScript runtime built on Chrome's V8 engine with npm package manager"
        "features" = @("LTS version management", "npm package manager", "Global package support", "Runtime environment")
        "install_cmd" = "setwinx node auto"
        "test_cmd" = "setwinx node test"
        "script_path" = "core\development-tools\node-lts.ps1"
    }
    "python" = @{
        "category" = "Development Tool"
        "description" = "Python - High-level programming language with pip package manager and virtual environment support"
        "features" = @("Latest stable version", "pip package manager", "Virtual environments", "Essential packages")
        "install_cmd" = "setwinx python auto"
        "test_cmd" = "setwinx python test"
        "script_path" = "core\development-tools\python.ps1"
    }
    "terminal" = @{
        "category" = "Development Tool"
        "description" = "Windows Terminal - Modern terminal application with tabs, profiles, and customization options"
        "features" = @("Multiple tabs", "Custom profiles", "GPU acceleration", "Unicode support")
        "install_cmd" = "setwinx terminal auto"
        "test_cmd" = "setwinx terminal test"
        "script_path" = "core\development-tools\windows-terminal.ps1"
    }
}

# Function to display all available commands and their descriptions
function Show-CommandList {
    Write-Host "SetWinX v$SETWINX_VERSION - Available Commands and Components" -ForegroundColor Cyan
    Write-Host "===========================================================`n" -ForegroundColor Cyan
    
    $categories = @{}
    foreach ($name in $COMPONENT_INFO.Keys) {
        $info = $COMPONENT_INFO[$name]
        $category = $info.category
        if (-not $categories.ContainsKey($category)) {
            $categories[$category] = @()
        }
        $categories[$category] += @{name = $name; info = $info}
    }
    
    foreach ($category in $categories.Keys | Sort-Object) {
        Write-Host "$category Components:" -ForegroundColor Green
        Write-Host ("-" * 40)
        
        foreach ($component in $categories[$category] | Sort-Object name) {
            $name = $component.name
            $info = $component.info
            Write-Host "  $name" -ForegroundColor Yellow
            Write-Host "    Description: $($info.description)" -ForegroundColor White
            Write-Host "    Install: $($info.install_cmd)" -ForegroundColor Cyan
            Write-Host "    Test: $($info.test_cmd)" -ForegroundColor Gray
            Write-Host "    Features: $($info.features -join ', ')" -ForegroundColor DarkGreen
            Write-Host ""
        }
    }
    
    Write-Host "Bulk Operations:" -ForegroundColor Green
    Write-Host ("-" * 40)
    Write-Host "  setwinx --status [--module <name>]  - Show installation status of components" -ForegroundColor Cyan
    Write-Host "  setwinx --all [action]          - Apply action to all components" -ForegroundColor Cyan
    Write-Host "  setwinx --package-managers [action] - Apply action to package managers only" -ForegroundColor Cyan
    Write-Host "  setwinx --dev-tools [action]    - Apply action to development tools only" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Actions:" -ForegroundColor Green
    Write-Host ("-" * 40)
    Write-Host "  test, version, status, path, install, update, reinstall, auto" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Flags:" -ForegroundColor Green
    Write-Host ("-" * 40)
    Write-Host "  --force, -f                     - Force operations without prompts" -ForegroundColor Cyan
    Write-Host "  --verbose, -v                   - Show detailed output" -ForegroundColor Cyan
}

# Function to display installation options with detailed instructions
function Show-InstallOptions {
    Write-Host "SetWinX v$SETWINX_VERSION - Installation Options" -ForegroundColor Cyan
    Write-Host "==========================================`n" -ForegroundColor Cyan
    
    Write-Host "Quick Start (Recommended):" -ForegroundColor Green
    Write-Host ("-" * 40)
    Write-Host "  setwinx --setup                 - Interactive setup wizard" -ForegroundColor Yellow
    Write-Host "  setwinx --all auto              - Auto-install everything" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Package Managers First:" -ForegroundColor Green
    Write-Host ("-" * 40)
    Write-Host "  setwinx --package-managers auto - Install Scoop, WinGet & Chocolatey" -ForegroundColor Cyan
    Write-Host "  setwinx scoop auto              - Install Scoop only" -ForegroundColor Gray
    Write-Host "  setwinx winget auto             - Install WinGet only" -ForegroundColor Gray
    Write-Host "  setwinx choco auto              - Install Chocolatey only" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Development Tools:" -ForegroundColor Green
    Write-Host ("-" * 40)
    Write-Host "  setwinx --dev-tools auto        - Install all dev tools" -ForegroundColor Cyan
    foreach ($name in ($COMPONENT_INFO.Keys | Where-Object { $COMPONENT_INFO[$_].category -eq "Development Tool" } | Sort-Object)) {
        $info = $COMPONENT_INFO[$name]
        Write-Host "  $($info.install_cmd.PadRight(30)) - $($info.description.Split('-')[0].Trim())" -ForegroundColor Gray
    }
    Write-Host ""
    
    Write-Host "Installation Methods (Priority Order):" -ForegroundColor Green
    Write-Host ("-" * 40)
    Write-Host "  1. WinGet (Microsoft Store integration)" -ForegroundColor White
    Write-Host "  2. Chocolatey (Community packages)" -ForegroundColor White  
    Write-Host "  3. Scoop (Portable installations)" -ForegroundColor White
    Write-Host "  4. Direct Download (Official sources)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Prerequisites:" -ForegroundColor Yellow
    Write-Host ("-" * 40)
    Write-Host "  - Windows 10/11" -ForegroundColor White
    Write-Host "  - PowerShell 5.1 or later" -ForegroundColor White
    Write-Host "  - Internet connection" -ForegroundColor White
    Write-Host "  - Administrator rights (for some installations)" -ForegroundColor White
}

# Function to start interactive setup wizard
function Start-InteractiveSetup {
    Write-Host "SetWinX v$SETWINX_VERSION - Interactive Setup Wizard" -ForegroundColor Cyan
    Write-Host "===============================================`n" -ForegroundColor Cyan
    
    Write-Host "Welcome to SetWinX! This wizard will help you set up your development environment.`n" -ForegroundColor White
    
    # Step 1: Package Managers
    Write-Host "Step 1: Package Managers" -ForegroundColor Green
    Write-Host ("-" * 25)
    $installPackageManagers = Read-Host "Install package managers (Scoop & WinGet)? [Y/n]"
    if ($installPackageManagers -ne 'n' -and $installPackageManagers -ne 'N') {
        Write-Host "Installing package managers..." -ForegroundColor Yellow
        & $MyInvocation.MyCommand.Path -PackageManagers -Component auto -Verbose
    }
    
    Write-Host ""
    
    # Step 2: Development Tools Selection
    Write-Host "Step 2: Development Tools" -ForegroundColor Green
    Write-Host ("-" * 25)
    Write-Host "Available development tools:"
    
    $devTools = $COMPONENT_INFO.Keys | Where-Object { $COMPONENT_INFO[$_].category -eq "Development Tool" } | Sort-Object
    $selectedTools = @()
    
    foreach ($tool in $devTools) {
        $info = $COMPONENT_INFO[$tool]
        $install = Read-Host "Install $tool ($($info.description.Split('-')[0].Trim()))? [Y/n]"
        if ($install -ne 'n' -and $install -ne 'N') {
            $selectedTools += $tool
        }
    }
    
    # Step 3: Installation
    if ($selectedTools.Count -gt 0) {
        Write-Host "`nStep 3: Installation" -ForegroundColor Green
        Write-Host ("-" * 20)
        Write-Host "Installing selected tools: $($selectedTools -join ', ')" -ForegroundColor Yellow
        
        foreach ($tool in $selectedTools) {
            Write-Host "`nInstalling $tool..." -ForegroundColor Cyan
            & $MyInvocation.MyCommand.Path -Target $tool -Component auto -Verbose
        }
        
        Write-Host "`nSetup completed! Run 'setwinx --list' to verify installations." -ForegroundColor Green
    } else {
        Write-Host "`nNo tools selected. Setup cancelled." -ForegroundColor Yellow
    }
}

# Function to display comprehensive status report of all or specific components
function Show-StatusReport {
    param(
        [string]$SpecificModule = ""
    )
    
    Write-Host "SetWinX v$SETWINX_VERSION - Component Status Report" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ""
    
    # Determine which components to check
    $componentsToCheck = @()
    if ($SpecificModule -ne "") {
        if ($SpecificModule -in $allComponentsList) {
            $componentsToCheck = @($SpecificModule)
        } elseif ($SpecificModule.ToLower() -eq "all") {
            $componentsToCheck = $allComponentsList
        } elseif ($SpecificModule.ToLower() -eq "package-managers" -or $SpecificModule.ToLower() -eq "packagemanagers") {
            $componentsToCheck = $packageManagerList
        } elseif ($SpecificModule.ToLower() -eq "dev-tools" -or $SpecificModule.ToLower() -eq "devtools") {
            $componentsToCheck = $devToolsList
        } else {
            Write-Host "❌ Unknown module '$SpecificModule'" -ForegroundColor Red
            Write-Host "Available modules: $($allComponentsList -join ', ')" -ForegroundColor Yellow
            Write-Host "Or use: all, package-managers, dev-tools" -ForegroundColor Yellow
            return
        }
    } else {
        $componentsToCheck = $allComponentsList
    }
    
    # Status counters
    $installed = 0
    $notInstalled = 0
    $errors = 0
    
    # Check each component
    foreach ($comp in $componentsToCheck) {
        $info = $COMPONENT_INFO[$comp]
        $category = $info.category
        $description = $info.description.Split('-')[0].Trim()
        
        Write-Host "$comp".PadRight(12) -NoNewline -ForegroundColor White
        Write-Host " | " -NoNewline -ForegroundColor Gray
        Write-Host "$category".PadRight(18) -NoNewline -ForegroundColor Cyan
        Write-Host " | " -NoNewline -ForegroundColor Gray
        
        # Test component status
        try {
            $scriptPath = if ($comp -in $packageManagerList) {
                "$SCRIPT_DIR\core\package-managers\$comp.ps1"
            } else {
                if ($comp -eq "node") {
                    "$SCRIPT_DIR\core\development-tools\node-lts.ps1"
                } elseif ($comp -eq "terminal") {
                    "$SCRIPT_DIR\core\development-tools\windows-terminal.ps1"
                } else {
                    "$SCRIPT_DIR\core\development-tools\$comp.ps1"
                }
            }
            
            if (-not (Test-Path $scriptPath)) {
                Write-Host "SCRIPT MISSING" -ForegroundColor Red
                $errors++
                continue
            }
            
            # Run test silently and capture result
            $null = & $scriptPath -Action test *>&1
            $isInstalled = $LASTEXITCODE -eq 0
            
            if ($isInstalled) {
                Write-Host "✅ INSTALLED   " -NoNewline -ForegroundColor Green
                $installed++
                
                # Get version info if available
                $versionOutput = & $scriptPath -Action version *>&1 2>$null
                if ($versionOutput -and $versionOutput -ne "" -and $LASTEXITCODE -eq 0) {
                    $version = ($versionOutput | Where-Object { $_ -match "version:" -or $_ -match "v\d" } | Select-Object -First 1)
                    if ($version) {
                        $cleanVersion = $version -replace ".*version:?\s*", "" -replace "^.*?(\d+\.\d+.*)", '$1'
                        Write-Host "| $cleanVersion" -ForegroundColor DarkGreen
                    } else {
                        Write-Host "| $description" -ForegroundColor DarkGreen
                    }
                } else {
                    Write-Host "| $description" -ForegroundColor DarkGreen
                }
            } else {
                Write-Host "❌ NOT INSTALLED" -NoNewline -ForegroundColor Red
                Write-Host " | $description" -ForegroundColor Gray
                $notInstalled++
            }
        }
        catch {
            Write-Host "⚠️ ERROR        " -NoNewline -ForegroundColor Yellow
            Write-Host "| Could not test component" -ForegroundColor Gray
            $errors++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host ("─" * 30) -ForegroundColor Gray
    Write-Host "✅ Installed:     $installed" -ForegroundColor Green
    Write-Host "❌ Not Installed: $notInstalled" -ForegroundColor Red
    if ($errors -gt 0) {
        Write-Host "⚠️ Errors:        $errors" -ForegroundColor Yellow
    }
    Write-Host "📦 Total Checked: $($componentsToCheck.Count)" -ForegroundColor Cyan
    
    if ($notInstalled -gt 0) {
        Write-Host ""
        Write-Host "💡 Quick Actions:" -ForegroundColor Yellow
        Write-Host "  setwinx --all auto                  # Install all missing components" -ForegroundColor White
        Write-Host "  setwinx --package-managers auto     # Install package managers first" -ForegroundColor White
        Write-Host "  setwinx <component> auto            # Install specific component" -ForegroundColor White
    }
}

# Fix for --status being treated as a positional argument
if ($Target -eq "--status") {
    if ($Component -eq "--module" -or $Component -eq "-module") {
        # Module is being passed via positional args
        Write-Host "SetWinX - Checking Component Status for module: $Module" -ForegroundColor Cyan
        Show-StatusReport -SpecificModule $Module
    } else {
        # No module specified, check all components
        Write-Host "SetWinX - Checking All Component Status" -ForegroundColor Cyan
        Show-StatusReport
    }
    exit 0
}

# Fix for --list-modules being treated as a positional argument
if ($Target -eq "--list-modules" -or $Target -eq "-lm") {
    Show-ModuleList
    exit 0
}

# Fix for --list being treated as a positional argument
if ($Target -eq "--list") {
    Write-Host "SetWinX Components:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Package Managers (3):" -ForegroundColor Green
    $pkgMgrList = @("scoop", "winget", "choco")
    foreach ($pm in $pkgMgrList) {
        $scriptPath = "$SCRIPT_DIR\core\package-managers\$pm.ps1"
        $exists = Test-Path $scriptPath
        $statusText = if ($exists) { "OK" } else { "MISSING" }
        $color = if ($exists) { "Green" } else { "Red" }
        Write-Host "  [$statusText] $pm" -ForegroundColor $color
    }
    Write-Host ""
    Write-Host "Development Tools (7):" -ForegroundColor Green
    $devToolsListLocal = @("git", "gh", "vscode", "docker", "node", "python", "terminal")
    foreach ($tool in $devToolsListLocal) {
        $scriptName = if ($tool -eq "node") { "node-lts.ps1" } elseif ($tool -eq "terminal") { "windows-terminal.ps1" } else { "$tool.ps1" }
        $scriptPath = "$SCRIPT_DIR\core\development-tools\$scriptName"
        $exists = Test-Path $scriptPath
        $statusText = if ($exists) { "OK" } else { "MISSING" }
        $color = if ($exists) { "Green" } else { "Red" }
        Write-Host "  [$statusText] $tool" -ForegroundColor $color
    }
    Write-Host ""
    Write-Host "Total: 10 components" -ForegroundColor Cyan
    exit 0
}

# Priority for switches - should work if properly invoked with named parameters
if ($Status) {
    Write-Host "SetWinX - Checking Component Status" -ForegroundColor Cyan
    Show-StatusReport -SpecificModule $Module
    exit 0
}

# Handle positional parameters correctly
if ($args.Count -ge 2) {
    $Target = $args[0]
    $Component = $args[1]  # This is actually the action
} elseif ($args.Count -eq 1) {
    $Target = $args[0]
    $Component = "help"
} elseif ($Target -ne "help") {
    # Target parameter was specified, Component is the action
}

# Process bulk operations or individual component commands
# (This is handled by other sections of the script)

if ($ShowVersion) {
    Write-Host "SetWinX v$SETWINX_VERSION" -ForegroundColor Green
    exit 0
}

if ($ShowCommands) {
    Show-CommandList
    exit 0
}

if ($Install) {
    Show-InstallOptions
    exit 0
}

if ($Setup) {
    Start-InteractiveSetup
    exit 0
}

if ($ListModules) {
    Show-ModuleList
    exit 0
}

# Status was already handled at the beginning of the script
# This code block is no longer needed

# List command handler is now processed earlier as a fix for positional parameters

if ($Target -eq "help" -and -not ($All -or $PackageManagers -or $DevTools)) {
    Write-Host "SetWinX v$SETWINX_VERSION - Windows Development Setup CLI" -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  setwinx <component> <action> [options]" -ForegroundColor White
    Write-Host "  setwinx --list                           # List all components" -ForegroundColor White
    Write-Host "  setwinx --status [--module <name>]       # Show installation status" -ForegroundColor White
    Write-Host "  setwinx --all <action>                  # Run action on all components" -ForegroundColor White
    Write-Host "  setwinx --package-managers <action>     # Run on package managers only" -ForegroundColor White
    Write-Host "  setwinx --dev-tools <action>           # Run on development tools only" -ForegroundColor White
    Write-Host ""
    Write-Host "COMPONENTS:" -ForegroundColor Yellow
    Write-Host "  Package Managers: scoop, winget" -ForegroundColor Green
    Write-Host "  Development Tools: git, gh, vscode, docker, node, python, terminal" -ForegroundColor Green
    Write-Host ""
    Write-Host "ACTIONS:" -ForegroundColor Yellow
    Write-Host "  test         - Test if component is working properly" -ForegroundColor White
    Write-Host "  version      - Get component version information" -ForegroundColor White
    Write-Host "  status       - Get detailed component status" -ForegroundColor White
    Write-Host "  path         - Get component installation paths" -ForegroundColor White
    Write-Host "  install      - Install component with intelligent fallbacks" -ForegroundColor White
    Write-Host "  update       - Update component to latest version" -ForegroundColor White
    Write-Host "  reinstall    - Completely remove and reinstall component" -ForegroundColor White
    Write-Host "  auto         - Intelligent auto-setup (test -> install -> verify)" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  --force      - Force action even if component appears working" -ForegroundColor White
    Write-Host "  --verbose    - Enable verbose output" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  setwinx git test                        # Test if Git is working" -ForegroundColor Gray
    Write-Host "  setwinx python auto                     # Auto-setup Python" -ForegroundColor Gray
    Write-Host "  setwinx vscode install --force         # Force install VS Code" -ForegroundColor Gray
    Write-Host "  setwinx --all test                     # Test all components" -ForegroundColor Gray
    Write-Host "  setwinx --package-managers auto        # Auto-setup package managers" -ForegroundColor Gray
    Write-Host "  setwinx --dev-tools status             # Get status of all dev tools" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Handle bulk operations
if ($All) {
    if ($Component -eq "help") {
        Write-Host "ERROR: --all requires an action" -ForegroundColor Red
        Write-Host "Example: setwinx --all test" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Running '$Component' on ALL components..." -ForegroundColor Cyan
    $success = 0
    $failed = 0
    foreach ($comp in $allComponentsList) {
        Write-Host "`n--- Processing: $comp ---" -ForegroundColor Yellow
        & $MyInvocation.MyCommand.Path $comp $Component
        if ($LASTEXITCODE -eq 0) { $success++ } else { $failed++ }
    }
    Write-Host "`nSummary: $success succeeded, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
    exit 0
}

if ($PackageManagers) {
    if ($Component -eq "help") {
        Write-Host "ERROR: --package-managers requires an action" -ForegroundColor Red
        Write-Host "Example: setwinx --package-managers auto" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Running '$Component' on PACKAGE MANAGERS..." -ForegroundColor Cyan
    $success = 0
    $failed = 0
    foreach ($pm in $packageManagerList) {
        Write-Host "`n--- Processing: $pm ---" -ForegroundColor Yellow
        & $MyInvocation.MyCommand.Path $pm $Component
        if ($LASTEXITCODE -eq 0) { $success++ } else { $failed++ }
    }
    Write-Host "`nSummary: $success succeeded, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
    exit 0
}

if ($DevTools) {
    if ($Component -eq "help") {
        Write-Host "ERROR: --dev-tools requires an action" -ForegroundColor Red
        Write-Host "Example: setwinx --dev-tools status" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Running '$Component' on DEVELOPMENT TOOLS..." -ForegroundColor Cyan
    foreach ($tool in $devToolsList) {
        Write-Host "`n--- Processing: $tool ---" -ForegroundColor Yellow
        & $MyInvocation.MyCommand.Path $tool $Component
    }
    exit 0
}

if ($Target -notin $allComponentsList) {
    Write-Host "ERROR: Unknown component '$Target'" -ForegroundColor Red
    Write-Host "Use 'setwinx --list' to see available components" -ForegroundColor Yellow
    exit 1
}

$scriptPath = if ($Target -in $packageManagerList) {
    "$SCRIPT_DIR\core\package-managers\$Target.ps1"
} else {
    "$SCRIPT_DIR\core\development-tools\$Target.ps1"
}

if ($Target -eq "node") {
    $scriptPath = "$SCRIPT_DIR\core\development-tools\node-lts.ps1"
} elseif ($Target -eq "terminal") {
    $scriptPath = "$SCRIPT_DIR\core\development-tools\windows-terminal.ps1"
}

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Executing: $Target -> $Component" -ForegroundColor Cyan

# Build argument list with optional flags
$arguments = @{}
$arguments['Action'] = $Component
if ($Force) { 
    $arguments['Force'] = $true
    Write-Host "Using --force flag" -ForegroundColor Yellow
}
if ($Verbose) { 
    $arguments['Verbose'] = $true
    Write-Host "Using --verbose flag" -ForegroundColor Yellow
}

& $scriptPath @arguments
