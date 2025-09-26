<#
.SYNOPSIS
    Logging Provider Module
.DESCRIPTION
    Provides centralized logging functionality for the Windows Development Toolkit
    Supports multiple log levels, file logging, and structured output
#>

# Logging configuration
$script:LogConfig = @{
    Level = "Info"
    LogToFile = $true
    LogPath = "logs"
    MaxLogFiles = 10
    MaxLogSizeMB = 50
}

# Log levels
$script:LogLevels = @{
    "Debug" = 0
    "Info" = 1
    "Warning" = 2
    "Error" = 3
    "Critical" = 4
}

class ToolkitLogger {
    [string]$LogLevel
    [bool]$LogToFile
    [string]$LogPath
    [int]$MaxLogFiles
    [int]$MaxLogSizeMB
    [string]$LogFile
    [hashtable]$LogLevels
    
    ToolkitLogger([string]$Level, [bool]$LogToFile, [string]$LogPath, [int]$MaxLogFiles, [int]$MaxLogSizeMB) {
        $this.LogLevel = $Level
        $this.LogToFile = $LogToFile
        $this.LogPath = $LogPath
        $this.MaxLogFiles = $MaxLogFiles
        $this.MaxLogSizeMB = $MaxLogSizeMB
        $this.LogLevels = @{
            "Debug" = 0
            "Info" = 1
            "Warning" = 2
            "Error" = 3
            "Critical" = 4
        }
        
        $this.InitializeLogFile()
    }
    
    [void] InitializeLogFile() {
        if ($this.LogToFile) {
            # Ensure log directory exists
            if (-not (Test-Path $this.LogPath)) {
                New-Item -ItemType Directory -Path $this.LogPath -Force | Out-Null
            }
            
            # Create log file with timestamp
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $this.LogFile = Join-Path $this.LogPath "toolkit-$timestamp.log"
        }
    }
    
    [void] Log([string]$Message, [string]$Level = "Info", [string]$Category = "General") {
        $currentLevel = $this.LogLevels[$this.LogLevel]
        $messageLevel = $this.LogLevels[$Level]
        
        # Only log if message level is >= current level
        if ($messageLevel -ge $currentLevel) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [$Level] [$Category] $Message"
            
            # Console output
            $this.WriteToConsole($logEntry, $Level)
            
            # File output
            if ($this.LogToFile) {
                $this.WriteToFile($logEntry)
            }
        }
    }
    
    [void] WriteToConsole([string]$Message, [string]$Level) {
        $color = switch ($Level) {
            "Debug" { "Gray" }
            "Info" { "Cyan" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Critical" { "Magenta" }
            default { "White" }
        }
        
        Write-Host $Message -ForegroundColor $color
    }
    
    [void] WriteToFile([string]$Message) {
        try {
            Add-Content -Path $this.LogFile -Value $Message -Encoding UTF8
            $this.RotateLogIfNeeded()
        }
        catch {
            Write-Warning "Failed to write to log file: $($_.Exception.Message)"
        }
    }
    
    [void] RotateLogIfNeeded() {
        if (Test-Path $this.LogFile) {
            $fileSize = (Get-Item $this.LogFile).Length / 1MB
            if ($fileSize -gt $this.MaxLogSizeMB) {
                $this.RotateLogFile()
            }
        }
    }
    
    [void] RotateLogFile() {
        try {
            # Get existing log files
            $logFiles = Get-ChildItem -Path $this.LogPath -Filter "toolkit-*.log" | Sort-Object LastWriteTime -Descending
            
            # Remove old files if we exceed max count
            if ($logFiles.Count -ge $this.MaxLogFiles) {
                $filesToRemove = $logFiles | Select-Object -Skip ($this.MaxLogFiles - 1)
                foreach ($file in $filesToRemove) {
                    Remove-Item $file.FullName -Force
                }
            }
            
            # Create new log file
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $this.LogFile = Join-Path $this.LogPath "toolkit-$timestamp.log"
        }
        catch {
            Write-Warning "Failed to rotate log file: $($_.Exception.Message)"
        }
    }
    
    [void] Debug([string]$Message, [string]$Category = "General") {
        $this.Log($Message, "Debug", $Category)
    }
    
    [void] Info([string]$Message, [string]$Category = "General") {
        $this.Log($Message, "Info", $Category)
    }
    
    [void] Warning([string]$Message, [string]$Category = "General") {
        $this.Log($Message, "Warning", $Category)
    }
    
    [void] Error([string]$Message, [string]$Category = "General") {
        $this.Log($Message, "Error", $Category)
    }
    
    [void] Critical([string]$Message, [string]$Category = "General") {
        $this.Log($Message, "Critical", $Category)
    }
    
    [void] Success([string]$Message, [string]$Category = "General") {
        $this.Log("✓ $Message", "Info", $Category)
    }
    
    [void] Failure([string]$Message, [string]$Category = "General") {
        $this.Log("✗ $Message", "Error", $Category)
    }
    
    [void] Step([string]$Message, [string]$Category = "General") {
        $this.Log("→ $Message", "Info", $Category)
    }
}

function Initialize-ToolkitLogging {
    <#
    .SYNOPSIS
        Initializes the toolkit logging system
    .PARAMETER LogLevel
        The minimum log level to output
    .PARAMETER LogToFile
        Whether to log to file
    .PARAMETER LogPath
        Path to log files
    .PARAMETER MaxLogFiles
        Maximum number of log files to keep
    .PARAMETER MaxLogSizeMB
        Maximum size of a log file in MB
    #>
    [CmdletBinding()]
    param(
        [string]$LogLevel = "Info",
        [bool]$LogToFile = $true,
        [string]$LogPath = "logs",
        [int]$MaxLogFiles = 10,
        [int]$MaxLogSizeMB = 50
    )
    
    return [ToolkitLogger]::new($LogLevel, $LogToFile, $LogPath, $MaxLogFiles, $MaxLogSizeMB)
}

function Write-LogHeader {
    <#
    .SYNOPSIS
        Writes a formatted header to the log
    .PARAMETER Message
        Header message
    .PARAMETER Logger
        Logger instance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ToolkitLogger]$Logger
    )
    
    $separator = "=" * 50
    $Logger.Info($separator)
    $Logger.Info($Message)
    $Logger.Info($separator)
}

function Write-LogSection {
    <#
    .SYNOPSIS
        Writes a formatted section to the log
    .PARAMETER Message
        Section message
    .PARAMETER Logger
        Logger instance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ToolkitLogger]$Logger
    )
    
    $Logger.Info("")
    $Logger.Info("--- $Message ---")
}

function Write-LogSummary {
    <#
    .SYNOPSIS
        Writes a formatted summary to the log
    .PARAMETER Summary
        Summary hashtable
    .PARAMETER Logger
        Logger instance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Summary,
        
        [ToolkitLogger]$Logger
    )
    
    $Logger.Info("")
    $Logger.Info("=== SUMMARY ===")
    
    foreach ($key in $Summary.Keys) {
        $value = $Summary[$key]
        if ($value -is [bool]) {
            $status = if ($value) { "✓" } else { "✗" }
            $Logger.Info("$key: $status")
        } else {
            $Logger.Info("$key: $value")
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-ToolkitLogging',
    'Write-LogHeader',
    'Write-LogSection',
    'Write-LogSummary'
)
