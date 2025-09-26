# SetWinX CLI Installation Script
# This script installs SetWinX CLI to c:\dev0-1\setupx-cli and adds it to PATH

param(
    [string]$InstallPath = "c:\dev0-1\setupx-cli",
    [string]$GitHubRepo = "https://github.com/anshulyadav32/setupx.git",
    [switch]$Force
)

Write-Host "SetWinX CLI Installation Script" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Check if Git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Git is not installed. Please install Git first." -ForegroundColor Red
    exit 1
}

# Create installation directory
Write-Host "Creating installation directory: $InstallPath" -ForegroundColor Yellow
if (Test-Path $InstallPath) {
    if ($Force) {
        Write-Host "Directory exists. Removing due to -Force flag..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $InstallPath
    } else {
        Write-Host "ERROR: Directory already exists. Use -Force to overwrite." -ForegroundColor Red
        exit 1
    }
}

try {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "SUCCESS: Directory created" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create directory: $_" -ForegroundColor Red
    exit 1
}

# Clone repository
Write-Host "Cloning repository from GitHub..." -ForegroundColor Yellow
try {
    git clone $GitHubRepo $InstallPath
    Write-Host "SUCCESS: Repository cloned" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to clone repository: $_" -ForegroundColor Red
    exit 1
}

# Set up the CLI path (pointing to windows_scripts directory)
$CLIPath = Join-Path $InstallPath "windows_scripts"
if (-not (Test-Path $CLIPath)) {
    Write-Host "ERROR: CLI scripts not found in: $CLIPath" -ForegroundColor Red
    exit 1
}

# Add to PATH
Write-Host "Adding CLI to system PATH..." -ForegroundColor Yellow
try {
    # Get current PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    # Check if already in PATH
    if ($currentPath -split ";" -contains $CLIPath) {
        Write-Host "SUCCESS: CLI path already exists in PATH" -ForegroundColor Green
    } else {
        # Add to PATH
        $newPath = $currentPath + ";" + $CLIPath
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        
        # Update current session PATH
        $env:Path = $newPath
        
        Write-Host "SUCCESS: CLI added to PATH" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to add to PATH: $_" -ForegroundColor Red
    exit 1
}

# Create batch file for easier access
$BatchFile = Join-Path $CLIPath "setwinx.bat"
$BatchContent = "@echo off`npowershell.exe -ExecutionPolicy Bypass -File `"%~dp0setwinx.ps1`" %*"

try {
    Set-Content -Path $BatchFile -Value $BatchContent
    Write-Host "SUCCESS: Created setwinx.bat" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Could not create batch file" -ForegroundColor Yellow
}

# Test installation
Write-Host "Testing installation..." -ForegroundColor Yellow
try {
    Push-Location $CLIPath
    $testResult = & ".\setwinx.ps1" --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Installation test passed!" -ForegroundColor Green
        Write-Host "Version: $testResult" -ForegroundColor Cyan
    } else {
        Write-Host "WARNING: Installation completed but test failed" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not test installation: $_" -ForegroundColor Yellow
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "SetWinX CLI Installation Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed to: $CLIPath" -ForegroundColor Cyan
Write-Host "Added to PATH: Yes" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  setwinx --help          # Show help" -ForegroundColor Gray
Write-Host "  setwinx --list-modules  # List available modules" -ForegroundColor Gray
Write-Host "  setwinx --status        # Check component status" -ForegroundColor Gray
Write-Host ""
Write-Host "NOTE: You may need to restart your terminal for PATH changes to take effect." -ForegroundColor Yellow