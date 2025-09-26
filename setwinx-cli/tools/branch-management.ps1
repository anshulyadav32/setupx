#Requires -Version 5.1

<#
.SYNOPSIS
    Branch Management Script for Windows Development Toolkit
.DESCRIPTION
    Provides comprehensive branch management functionality for the Windows Development Toolkit project.
    Supports creating, managing, and monitoring Git branches with proper workflow enforcement.
    
.PARAMETER Action
    The action to perform (create, list, delete, merge, status)
    
.PARAMETER BranchType
    The type of branch to create (feature, release, hotfix, testing)
    
.PARAMETER BranchName
    The name of the branch
    
.PARAMETER BaseBranch
    The base branch to create from
    
.PARAMETER Force
    Force the operation
    
.EXAMPLE
    .\branch-management.ps1 -Action create -BranchType feature -BranchName core-modules
    
.EXAMPLE
    .\branch-management.ps1 -Action list -BranchType feature
    
.EXAMPLE
    .\branch-management.ps1 -Action delete -BranchName feature/old-feature -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("create", "list", "delete", "merge", "status", "sync", "cleanup")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("feature", "release", "hotfix", "testing")]
    [string]$BranchType,
    
    [Parameter(Mandatory = $false)]
    [string]$BranchName,
    
    [Parameter(Mandatory = $false)]
    [string]$BaseBranch = "develop",
    
    [switch]$Force,
    
    [switch]$Verbose
)

# Branch configuration
$script:BranchConfig = @{
    "feature" = @{
        "base" = "develop"
        "prefix" = "feature"
        "description" = "Feature development branches"
    }
    "release" = @{
        "base" = "develop"
        "prefix" = "release"
        "description" = "Release preparation branches"
    }
    "hotfix" = @{
        "base" = "main"
        "prefix" = "hotfix"
        "description" = "Critical production fixes"
    }
    "testing" = @{
        "base" = "develop"
        "prefix" = "testing"
        "description" = "Testing and validation branches"
    }
}

# Module definitions
$script:Modules = @{
    "core" = @("WindowsDevToolkit", "ConfigurationManager", "LoggingProvider", "SystemValidator")
    "installers" = @("PackageManagerInstaller", "DevelopmentToolsInstaller", "CloudToolsInstaller", "ApplicationInstaller", "AIToolsInstaller")
    "verification" = @("SoftwareVerification", "TestFramework", "ValidationEngine")
    "configuration" = @("TerminalConfigurator", "PowerShellConfigurator", "ToolConfigurator", "AIConfigurator")
    "utilities" = @("SystemUtilities", "NetworkUtilities", "FileSystemUtilities", "ProcessUtilities")
}

function Write-BranchHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-BranchInfo {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-BranchSuccess {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-BranchWarning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-BranchError {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Test-GitRepository {
    <#
    .SYNOPSIS
        Tests if the current directory is a Git repository
    #>
    try {
        $gitStatus = git status 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Get-BranchStatus {
    <#
    .SYNOPSIS
        Gets the current branch status
    #>
    try {
        $currentBranch = git branch --show-current
        $status = git status --porcelain
        $ahead = git rev-list --count @{u}..HEAD 2>$null
        $behind = git rev-list --count HEAD..@{u} 2>$null
        
        return @{
            CurrentBranch = $currentBranch
            HasChanges = $status.Count -gt 0
            Ahead = if ($ahead) { [int]$ahead } else { 0 }
            Behind = if ($behind) { [int]$behind } else { 0 }
            Status = $status
        }
    }
    catch {
        return @{
            CurrentBranch = "unknown"
            HasChanges = $false
            Ahead = 0
            Behind = 0
            Status = @()
        }
    }
}

function New-FeatureBranch {
    <#
    .SYNOPSIS
        Creates a new feature branch
    .PARAMETER BranchName
        Name of the feature branch
    .PARAMETER BaseBranch
        Base branch to create from
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName,
        
        [string]$BaseBranch = "develop"
    )
    
    $fullBranchName = "feature/$BranchName"
    
    try {
        # Check if branch already exists
        $existingBranch = git branch --list $fullBranchName
        if ($existingBranch) {
            Write-BranchWarning "Branch $fullBranchName already exists"
            return $false
        }
        
        # Ensure base branch is up to date
        Write-BranchInfo "Updating base branch: $BaseBranch"
        git checkout $BaseBranch
        git pull origin $BaseBranch
        
        # Create feature branch
        Write-BranchInfo "Creating feature branch: $fullBranchName"
        git checkout -b $fullBranchName
        
        # Push to remote
        git push -u origin $fullBranchName
        
        Write-BranchSuccess "Feature branch '$fullBranchName' created successfully"
        return $true
    }
    catch {
        Write-BranchError "Failed to create feature branch: $($_.Exception.Message)"
        return $false
    }
}

function New-ReleaseBranch {
    <#
    .SYNOPSIS
        Creates a new release branch
    .PARAMETER Version
        Version number for the release
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )
    
    $fullBranchName = "release/v$Version"
    
    try {
        # Check if branch already exists
        $existingBranch = git branch --list $fullBranchName
        if ($existingBranch) {
            Write-BranchWarning "Branch $fullBranchName already exists"
            return $false
        }
        
        # Ensure develop is up to date
        Write-BranchInfo "Updating develop branch"
        git checkout develop
        git pull origin develop
        
        # Create release branch
        Write-BranchInfo "Creating release branch: $fullBranchName"
        git checkout -b $fullBranchName
        
        # Push to remote
        git push -u origin $fullBranchName
        
        Write-BranchSuccess "Release branch '$fullBranchName' created successfully"
        return $true
    }
    catch {
        Write-BranchError "Failed to create release branch: $($_.Exception.Message)"
        return $false
    }
}

function New-HotfixBranch {
    <#
    .SYNOPSIS
        Creates a new hotfix branch
    .PARAMETER IssueNumber
        Issue number or description
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IssueNumber
    )
    
    $fullBranchName = "hotfix/$IssueNumber"
    
    try {
        # Check if branch already exists
        $existingBranch = git branch --list $fullBranchName
        if ($existingBranch) {
            Write-BranchWarning "Branch $fullBranchName already exists"
            return $false
        }
        
        # Ensure main is up to date
        Write-BranchInfo "Updating main branch"
        git checkout main
        git pull origin main
        
        # Create hotfix branch
        Write-BranchInfo "Creating hotfix branch: $fullBranchName"
        git checkout -b $fullBranchName
        
        # Push to remote
        git push -u origin $fullBranchName
        
        Write-BranchSuccess "Hotfix branch '$fullBranchName' created successfully"
        return $true
    }
    catch {
        Write-BranchError "Failed to create hotfix branch: $($_.Exception.Message)"
        return $false
    }
}

function New-TestingBranch {
    <#
    .SYNOPSIS
        Creates a new testing branch
    .PARAMETER TestType
        Type of testing (integration, unit, e2e)
    .PARAMETER Module
        Specific module to test
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestType,
        
        [string]$Module = ""
    )
    
    $branchName = if ($Module) { "testing/$TestType-$Module" } else { "testing/$TestType" }
    
    try {
        # Check if branch already exists
        $existingBranch = git branch --list $branchName
        if ($existingBranch) {
            Write-BranchWarning "Branch $branchName already exists"
            return $false
        }
        
        # Ensure develop is up to date
        Write-BranchInfo "Updating develop branch"
        git checkout develop
        git pull origin develop
        
        # Create testing branch
        Write-BranchInfo "Creating testing branch: $branchName"
        git checkout -b $branchName
        
        # Push to remote
        git push -u origin $branchName
        
        Write-BranchSuccess "Testing branch '$branchName' created successfully"
        return $true
    }
    catch {
        Write-BranchError "Failed to create testing branch: $($_.Exception.Message)"
        return $false
    }
}

function Get-BranchList {
    <#
    .SYNOPSIS
        Lists branches by type
    .PARAMETER BranchType
        Type of branches to list
    #>
    [CmdletBinding()]
    param(
        [string]$BranchType = ""
    )
    
    try {
        $branches = git branch -a --format="%(refname:short)" | Where-Object { $_ -notmatch "HEAD" }
        
        if ($BranchType) {
            $prefix = $script:BranchConfig[$BranchType].prefix
            $branches = $branches | Where-Object { $_ -like "$prefix/*" }
        }
        
        return $branches
    }
    catch {
        Write-BranchError "Failed to list branches: $($_.Exception.Message)"
        return @()
    }
}

function Remove-Branch {
    <#
    .SYNOPSIS
        Deletes a branch
    .PARAMETER BranchName
        Name of the branch to delete
    .PARAMETER Force
        Force deletion
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName,
        
        [switch]$Force
    )
    
    try {
        # Check if branch exists
        $existingBranch = git branch --list $BranchName
        if (-not $existingBranch) {
            Write-BranchWarning "Branch $BranchName does not exist"
            return $false
        }
        
        # Check if branch is merged
        $mergedBranches = git branch --merged
        $isMerged = $mergedBranches -contains $BranchName
        
        if (-not $isMerged -and -not $Force) {
            Write-BranchWarning "Branch $BranchName is not merged. Use -Force to delete anyway."
            return $false
        }
        
        # Delete local branch
        git branch -d $BranchName
        if ($LASTEXITCODE -ne 0 -and $Force) {
            git branch -D $BranchName
        }
        
        # Delete remote branch if it exists
        $remoteBranch = git branch -r --list "origin/$BranchName"
        if ($remoteBranch) {
            git push origin --delete $BranchName
        }
        
        Write-BranchSuccess "Branch '$BranchName' deleted successfully"
        return $true
    }
    catch {
        Write-BranchError "Failed to delete branch: $($_.Exception.Message)"
        return $false
    }
}

function Sync-Branch {
    <#
    .SYNOPSIS
        Syncs a branch with its base branch
    .PARAMETER BranchName
        Name of the branch to sync
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName
    )
    
    try {
        # Get current branch
        $currentBranch = git branch --show-current
        
        # Switch to target branch
        git checkout $BranchName
        
        # Determine base branch
        $baseBranch = if ($BranchName -like "feature/*") { "develop" } 
                     elseif ($BranchName -like "release/*") { "develop" }
                     elseif ($BranchName -like "hotfix/*") { "main" }
                     else { "develop" }
        
        # Update base branch
        Write-BranchInfo "Updating base branch: $baseBranch"
        git checkout $baseBranch
        git pull origin $baseBranch
        
        # Switch back to target branch
        git checkout $BranchName
        
        # Merge or rebase base branch
        Write-BranchInfo "Syncing $BranchName with $baseBranch"
        git merge $baseBranch
        
        # Push changes
        git push origin $BranchName
        
        Write-BranchSuccess "Branch '$BranchName' synced successfully"
        return $true
    }
    catch {
        Write-BranchError "Failed to sync branch: $($_.Exception.Message)"
        return $false
    }
}

function Show-BranchStatus {
    <#
    .SYNOPSIS
        Shows comprehensive branch status
    #>
    [CmdletBinding()]
    param()
    
    try {
        $status = Get-BranchStatus
        
        Write-BranchHeader "Branch Status"
        Write-Host "Current Branch: $($status.CurrentBranch)" -ForegroundColor White
        Write-Host "Has Changes: $($status.HasChanges)" -ForegroundColor White
        Write-Host "Ahead: $($status.Ahead)" -ForegroundColor White
        Write-Host "Behind: $($status.Behind)" -ForegroundColor White
        
        if ($status.HasChanges) {
            Write-Host "`nUncommitted Changes:" -ForegroundColor Yellow
            $status.Status | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
        
        # Show branch hierarchy
        Write-Host "`nBranch Hierarchy:" -ForegroundColor Cyan
        $branches = Get-BranchList
        $branchTypes = @("feature", "release", "hotfix", "testing")
        
        foreach ($type in $branchTypes) {
            $typeBranches = $branches | Where-Object { $_ -like "$type/*" }
            if ($typeBranches) {
                Write-Host "`n$($type.ToUpper()):" -ForegroundColor Yellow
                $typeBranches | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
            }
        }
        
        return $true
    }
    catch {
        Write-BranchError "Failed to show branch status: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-BranchCleanup {
    <#
    .SYNOPSIS
        Cleans up old and merged branches
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-BranchInfo "Cleaning up merged branches..."
        
        # Get merged branches
        $mergedBranches = git branch --merged | Where-Object { 
            $_ -notmatch "main|develop" -and $_ -notmatch "\*" 
        }
        
        if ($mergedBranches.Count -eq 0) {
            Write-BranchInfo "No merged branches to clean up"
            return $true
        }
        
        # Delete merged branches
        foreach ($branch in $mergedBranches) {
            $branch = $branch.Trim()
            Write-BranchInfo "Deleting merged branch: $branch"
            git branch -d $branch
        }
        
        # Clean up remote references
        git remote prune origin
        
        Write-BranchSuccess "Branch cleanup completed"
        return $true
    }
    catch {
        Write-BranchError "Failed to cleanup branches: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
if (-not (Test-GitRepository)) {
    Write-BranchError "Not a Git repository. Please run this script from a Git repository root."
    exit 1
}

Write-BranchHeader "Windows Development Toolkit - Branch Management"

try {
    switch ($Action) {
        "create" {
            if (-not $BranchType -or -not $BranchName) {
                Write-BranchError "BranchType and BranchName are required for create action"
                exit 1
            }
            
            $success = switch ($BranchType) {
                "feature" { New-FeatureBranch -BranchName $BranchName -BaseBranch $BaseBranch }
                "release" { New-ReleaseBranch -Version $BranchName }
                "hotfix" { New-HotfixBranch -IssueNumber $BranchName }
                "testing" { New-TestingBranch -TestType $BranchName }
                default { Write-BranchError "Unknown branch type: $BranchType"; $false }
            }
            
            if ($success) {
                Write-BranchSuccess "Branch creation completed successfully"
            } else {
                Write-BranchError "Branch creation failed"
                exit 1
            }
        }
        "list" {
            $branches = Get-BranchList -BranchType $BranchType
            if ($branches.Count -gt 0) {
                Write-Host "`nBranches:" -ForegroundColor Cyan
                $branches | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
            } else {
                Write-BranchInfo "No branches found"
            }
        }
        "delete" {
            if (-not $BranchName) {
                Write-BranchError "BranchName is required for delete action"
                exit 1
            }
            
            $success = Remove-Branch -BranchName $BranchName -Force:$Force
            if (-not $success) {
                exit 1
            }
        }
        "sync" {
            if (-not $BranchName) {
                Write-BranchError "BranchName is required for sync action"
                exit 1
            }
            
            $success = Sync-Branch -BranchName $BranchName
            if (-not $success) {
                exit 1
            }
        }
        "status" {
            $success = Show-BranchStatus
            if (-not $success) {
                exit 1
            }
        }
        "cleanup" {
            $success = Invoke-BranchCleanup
            if (-not $success) {
                exit 1
            }
        }
        default {
            Write-BranchError "Unknown action: $Action"
            exit 1
        }
    }
}
catch {
    Write-BranchError "Script execution failed: $($_.Exception.Message)"
    exit 1
}

Write-BranchSuccess "Branch management completed successfully"
