# SetupX Installer - Modular Windows Development Setup
# Author: Anshul Yadav
# Repository: https://github.com/anshulyadav32/setupx

param(
    [switch]$Force,
    [string]$InstallPath = "$env:USERPROFILE\SetupX"
)

# Configuration
$RepoOwner = "anshulyadav32"
$RepoName = "setupx"
$Branch = "master"
$GitHubApiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName"
$DownloadUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow" 
    Error   = "Red"
    Info    = "Cyan"
    Header  = "Magenta"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Header {
    param([string]$Text)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor $Colors.Header
    Write-Host " $Text" -ForegroundColor $Colors.Header
    Write-Host "=" * 60 -ForegroundColor $Colors.Header
    Write-Host ""
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PowerShellVersion {
    return $PSVersionTable.PSVersion.Major -ge 5
}

function Get-UserConfirmation {
    param([string]$Message)
    
    if ($Force) { return $true }
    
    do {
        $response = Read-Host "$Message (y/N)"
        $response = $response.ToLower()
    } while ($response -notin @('', 'y', 'yes', 'n', 'no'))
    
    return $response -in @('y', 'yes')
}

function Test-InternetConnection {
    try {
        Invoke-RestMethod -Uri $GitHubApiUrl -TimeoutSec 10 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-ColorOutput "[ERROR] Cannot connect to GitHub. Please check your internet connection." "Error"
        return $false
    }
}

function New-TempDirectory {
    $tempPath = Join-Path $env:TEMP "SetupX-Install-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    return $tempPath
}

function Install-SetupX {
    Write-Header "SetupX Installation Started"
    
    # Prerequisites Check
    Write-ColorOutput "[INFO] Checking prerequisites..." "Info"
    
    if (-not (Test-PowerShellVersion)) {
        Write-ColorOutput "[ERROR] PowerShell 5.0 or higher is required." "Error"
        return $false
    }
    
    if (-not (Test-InternetConnection)) {
        return $false
    }
    
    # Check if installation directory exists
    if (Test-Path $InstallPath) {
        Write-ColorOutput "[WARNING] Installation directory already exists: $InstallPath" "Warning"
        if (-not (Get-UserConfirmation "Do you want to overwrite the existing installation?")) {
            Write-ColorOutput "[ERROR] Installation cancelled by user." "Warning"
            return $false
        }
        
        Write-ColorOutput "[INFO] Removing existing installation..." "Info"
        Remove-Item $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Create temporary directory
    Write-ColorOutput "[INFO] Creating temporary directory..." "Info"
    $tempDir = New-TempDirectory
    $zipPath = Join-Path $tempDir "setupx.zip"
    
    try {
        # Download the repository
        Write-ColorOutput "[INFO] Downloading SetupX from GitHub..." "Info"
        Write-ColorOutput "       Source: $DownloadUrl" "Info"
        
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath -UseBasicParsing
        
        # Extract the archive
        Write-ColorOutput "[INFO] Extracting files..." "Info"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)
        
        # Find the extracted directory
        $extractedDir = Get-ChildItem $tempDir -Directory | Where-Object { $_.Name -like "$RepoName-*" } | Select-Object -First 1
        
        if (-not $extractedDir) {
            throw "Could not find extracted directory"
        }
        
        # Look for windows_scripts directory
        $windowsScriptsPath = Join-Path $extractedDir.FullName "windows_scripts"
        
        if (-not (Test-Path $windowsScriptsPath)) {
            throw "SetupX framework not found in downloaded archive"
        }
        
        # Create installation directory
        Write-ColorOutput "[INFO] Creating installation directory..." "Info"
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        
        # Copy SetupX framework
        Write-ColorOutput "[INFO] Installing SetupX framework..." "Info"
        Copy-Item -Path "$windowsScriptsPath\*" -Destination $InstallPath -Recurse -Force
        
        # Add to PATH if requested
        $addToPath = Get-UserConfirmation "Do you want to add SetupX to your PATH environment variable?"
        
        if ($addToPath) {
            Write-ColorOutput "[INFO] Adding SetupX to PATH..." "Info"
            
            # Get current PATH
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            
            # Check if already in PATH
            if ($currentPath -split ";" -contains $InstallPath) {
                Write-ColorOutput "[INFO] SetupX is already in PATH" "Info"
            } else {
                $newPath = if ($currentPath) { "$currentPath;$InstallPath" } else { $InstallPath }
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                Write-ColorOutput "[SUCCESS] SetupX added to PATH" "Success"
            }
        }
        
        Write-Header "SetupX Installation Complete"
        Write-ColorOutput "[SUCCESS] Installation Location: $InstallPath" "Success"
        Write-ColorOutput "" "Info"
        Write-ColorOutput "[INFO] Quick Start Commands:" "Header"
        Write-ColorOutput "       PowerShell: .\setwinx.ps1" "Info"
        Write-ColorOutput "       Full Path: $InstallPath\setwinx.ps1" "Info"
        Write-ColorOutput "" "Info"
        Write-ColorOutput "[INFO] Documentation: https://github.com/$RepoOwner/$RepoName" "Info"
        
        if ($addToPath) {
            Write-ColorOutput "[WARNING] Note: Restart your terminal or run refreshenv to use PATH updates" "Warning"
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "[ERROR] Installation failed: $($_.Exception.Message)" "Error"
        return $false
    }
    finally {
        # Clean up temporary files
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Show-WelcomeMessage {
    Write-Host @"

    ================================================================
                        SetupX Installer                           
                                                                   
            Modular Windows Development Setup Tool                 
                                                                   
    ================================================================

"@ -ForegroundColor $Colors.Header
}

# Main execution
try {
    Show-WelcomeMessage
    
    Write-ColorOutput "[INFO] Target Installation Path: $InstallPath" "Info"
    
    if (-not $Force) {
        Write-ColorOutput "[INFO] Running in interactive mode. Use -Force to skip prompts." "Info"
    }
    
    $success = Install-SetupX
    
    if ($success) {
        Write-ColorOutput "`n[SUCCESS] Thank you for installing SetupX! Happy coding!" "Success"
        exit 0
    } else {
        Write-ColorOutput "`n[ERROR] Installation failed. Please check the error messages above." "Error"
        exit 1
    }
}
catch {
    Write-ColorOutput "[ERROR] Unexpected error: $($_.Exception.Message)" "Error"
    Write-ColorOutput "[INFO] Please report this issue at: https://github.com/$RepoOwner/$RepoName/issues" "Info"
    exit 1
}