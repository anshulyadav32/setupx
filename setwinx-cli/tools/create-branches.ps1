#Requires -Version 5.1

<#
.SYNOPSIS
    Create All Branches for Windows Development Toolkit
.DESCRIPTION
    Creates the complete branch structure for the Windows Development Toolkit project.
    This script sets up all necessary branches for modular development.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun
)

# Import branch management module
$BranchManagementScript = Join-Path $PSScriptRoot "branch-management.ps1"
if (Test-Path $BranchManagementScript) {
    . $BranchManagementScript
} else {
    Write-Error "Branch management script not found: $BranchManagementScript"
    exit 1
}

# Branch definitions
$script:BranchDefinitions = @{
    "main" = @{
        "type" = "main"
        "description" = "Production branch"
        "protected" = $true
    }
    "develop" = @{
        "type" = "main"
        "description" = "Integration branch"
        "protected" = $true
    }
    "feature/core-modules" = @{
        "type" = "feature"
        "description" = "Core functionality development"
        "modules" = @("WindowsDevToolkit", "ConfigurationManager", "LoggingProvider", "SystemValidator")
    }
    "feature/installers" = @{
        "type" = "feature"
        "description" = "Installation modules development"
        "modules" = @("PackageManagerInstaller", "DevelopmentToolsInstaller", "CloudToolsInstaller", "ApplicationInstaller", "AIToolsInstaller")
    }
    "feature/verification" = @{
        "type" = "feature"
        "description" = "Verification and testing modules"
        "modules" = @("SoftwareVerification", "TestFramework", "ValidationEngine")
    }
    "feature/configuration" = @{
        "type" = "feature"
        "description" = "Configuration modules development"
        "modules" = @("TerminalConfigurator", "PowerShellConfigurator", "ToolConfigurator", "AIConfigurator")
    }
    "feature/documentation" = @{
        "type" = "feature"
        "description" = "Documentation and guides"
        "modules" = @("README", "API docs", "User guides", "Tutorials")
    }
    "release/v2.0.0" = @{
        "type" = "release"
        "description" = "Version 2.0.0 release preparation"
        "version" = "2.0.0"
    }
    "release/v2.1.0" = @{
        "type" = "release"
        "description" = "Version 2.1.0 release preparation"
        "version" = "2.1.0"
    }
    "hotfix/critical-fixes" = @{
        "type" = "hotfix"
        "description" = "Critical production fixes"
        "priority" = "high"
    }
    "testing/integration-tests" = @{
        "type" = "testing"
        "description" = "Integration testing"
        "testType" = "integration"
    }
    "testing/unit-tests" = @{
        "type" = "testing"
        "description" = "Unit testing"
        "testType" = "unit"
    }
}

function Write-SetupHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-SetupInfo {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-SetupSuccess {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-SetupWarning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-SetupError {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Initialize-GitRepository {
    <#
    .SYNOPSIS
        Initializes Git repository if needed
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not (Test-GitRepository)) {
            Write-SetupInfo "Initializing Git repository..."
            git init
            git add .
            git commit -m "Initial commit: Windows Development Toolkit v2.0"
            Write-SetupSuccess "Git repository initialized"
        } else {
            Write-SetupInfo "Git repository already exists"
        }
        return $true
    }
    catch {
        Write-SetupError "Failed to initialize Git repository: $($_.Exception.Message)"
        return $false
    }
}

function New-MainBranches {
    <#
    .SYNOPSIS
        Creates main branches (main, develop)
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-SetupInfo "Creating main branches..."
        
        # Create main branch
        $mainBranch = git branch --list main
        if (-not $mainBranch) {
            git checkout -b main
            Write-SetupSuccess "Created main branch"
        } else {
            Write-SetupInfo "Main branch already exists"
        }
        
        # Create develop branch
        $developBranch = git branch --list develop
        if (-not $developBranch) {
            git checkout -b develop
            Write-SetupSuccess "Created develop branch"
        } else {
            Write-SetupInfo "Develop branch already exists"
        }
        
        return $true
    }
    catch {
        Write-SetupError "Failed to create main branches: $($_.Exception.Message)"
        return $false
    }
}

function New-FeatureBranches {
    <#
    .SYNOPSIS
        Creates feature branches
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-SetupInfo "Creating feature branches..."
        
        $featureBranches = $script:BranchDefinitions.GetEnumerator() | Where-Object { $_.Value.type -eq "feature" }
        
        foreach ($branch in $featureBranches) {
            $branchName = $branch.Key
            $branchInfo = $branch.Value
            
            if ($DryRun) {
                Write-SetupInfo "Would create feature branch: $branchName"
                continue
            }
            
            $success = New-FeatureBranch -BranchName $branchName.Replace("feature/", "") -BaseBranch "develop"
            if ($success) {
                Write-SetupSuccess "Created feature branch: $branchName"
            } else {
                Write-SetupWarning "Failed to create feature branch: $branchName"
            }
        }
        
        return $true
    }
    catch {
        Write-SetupError "Failed to create feature branches: $($_.Exception.Message)"
        return $false
    }
}

function New-ReleaseBranches {
    <#
    .SYNOPSIS
        Creates release branches
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-SetupInfo "Creating release branches..."
        
        $releaseBranches = $script:BranchDefinitions.GetEnumerator() | Where-Object { $_.Value.type -eq "release" }
        
        foreach ($branch in $releaseBranches) {
            $branchName = $branch.Key
            $branchInfo = $branch.Value
            
            if ($DryRun) {
                Write-SetupInfo "Would create release branch: $branchName"
                continue
            }
            
            $version = $branchInfo.version
            $success = New-ReleaseBranch -Version $version
            if ($success) {
                Write-SetupSuccess "Created release branch: $branchName"
            } else {
                Write-SetupWarning "Failed to create release branch: $branchName"
            }
        }
        
        return $true
    }
    catch {
        Write-SetupError "Failed to create release branches: $($_.Exception.Message)"
        return $false
    }
}

function New-HotfixBranches {
    <#
    .SYNOPSIS
        Creates hotfix branches
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-SetupInfo "Creating hotfix branches..."
        
        $hotfixBranches = $script:BranchDefinitions.GetEnumerator() | Where-Object { $_.Value.type -eq "hotfix" }
        
        foreach ($branch in $hotfixBranches) {
            $branchName = $branch.Key
            $branchInfo = $branch.Value
            
            if ($DryRun) {
                Write-SetupInfo "Would create hotfix branch: $branchName"
                continue
            }
            
            $issueNumber = $branchName.Replace("hotfix/", "")
            $success = New-HotfixBranch -IssueNumber $issueNumber
            if ($success) {
                Write-SetupSuccess "Created hotfix branch: $branchName"
            } else {
                Write-SetupWarning "Failed to create hotfix branch: $branchName"
            }
        }
        
        return $true
    }
    catch {
        Write-SetupError "Failed to create hotfix branches: $($_.Exception.Message)"
        return $false
    }
}

function New-TestingBranches {
    <#
    .SYNOPSIS
        Creates testing branches
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-SetupInfo "Creating testing branches..."
        
        $testingBranches = $script:BranchDefinitions.GetEnumerator() | Where-Object { $_.Value.type -eq "testing" }
        
        foreach ($branch in $testingBranches) {
            $branchName = $branch.Key
            $branchInfo = $branch.Value
            
            if ($DryRun) {
                Write-SetupInfo "Would create testing branch: $branchName"
                continue
            }
            
            $testType = $branchInfo.testType
            $success = New-TestingBranch -TestType $testType
            if ($success) {
                Write-SetupSuccess "Created testing branch: $branchName"
            } else {
                Write-SetupWarning "Failed to create testing branch: $branchName"
            }
        }
        
        return $true
    }
    catch {
        Write-SetupError "Failed to create testing branches: $($_.Exception.Message)"
        return $false
    }
}

function Show-BranchSummary {
    <#
    .SYNOPSIS
        Shows summary of created branches
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-SetupHeader "Branch Creation Summary"
        
        $allBranches = git branch -a --format="%(refname:short)" | Where-Object { $_ -notmatch "HEAD" }
        
        $branchTypes = @("main", "feature", "release", "hotfix", "testing")
        
        foreach ($type in $branchTypes) {
            $typeBranches = $allBranches | Where-Object { $_ -like "$type/*" -or $_ -eq $type }
            if ($typeBranches) {
                Write-Host "`n$($type.ToUpper()) BRANCHES:" -ForegroundColor Yellow
                $typeBranches | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
            }
        }
        
        Write-Host "`nTotal Branches: $($allBranches.Count)" -ForegroundColor Cyan
        
        return $true
    }
    catch {
        Write-SetupError "Failed to show branch summary: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Write-SetupHeader "Windows Development Toolkit - Branch Structure Creation"

if ($DryRun) {
    Write-SetupInfo "DRY RUN MODE - No branches will be created"
}

try {
    # Initialize Git repository
    if (-not (Initialize-GitRepository)) {
        exit 1
    }
    
    # Create main branches
    if (-not (New-MainBranches)) {
        exit 1
    }
    
    # Create feature branches
    if (-not (New-FeatureBranches)) {
        exit 1
    }
    
    # Create release branches
    if (-not (New-ReleaseBranches)) {
        exit 1
    }
    
    # Create hotfix branches
    if (-not (New-HotfixBranches)) {
        exit 1
    }
    
    # Create testing branches
    if (-not (New-TestingBranches)) {
        exit 1
    }
    
    # Show summary
    if (-not $DryRun) {
        Show-BranchSummary
    }
    
    Write-SetupSuccess "Branch structure creation completed successfully"
}
catch {
    Write-SetupError "Script execution failed: $($_.Exception.Message)"
    exit 1
}
