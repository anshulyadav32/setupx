<#
.SYNOPSIS
    Configuration Manager Module
.DESCRIPTION
    Handles all configuration management for the Windows Development Toolkit
    Provides centralized configuration loading, validation, and management
#>

# Configuration paths
$script:ConfigRoot = Join-Path (Split-Path (Split-Path $PSCommandPath)) "config"
$script:TemplateRoot = Join-Path (Split-Path (Split-Path $PSCommandPath)) "templates"

function Get-ToolkitConfigPath {
    <#
    .SYNOPSIS
        Gets the main toolkit configuration file path
    #>
    return Join-Path $script:ConfigRoot "toolkit.config.json"
}

function Get-ToolkitConfiguration {
    <#
    .SYNOPSIS
        Loads the main toolkit configuration
    .PARAMETER ConfigPath
        Path to the configuration file
    #>
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Get-ToolkitConfigPath)
    )
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "Configuration file not found at $ConfigPath. Using defaults."
        return Get-DefaultConfiguration
    }
    
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
        return $config
    }
    catch {
        Write-Error "Failed to load configuration: $($_.Exception.Message)"
        return Get-DefaultConfiguration
    }
}

function Get-DefaultConfiguration {
    <#
    .SYNOPSIS
        Returns default toolkit configuration
    #>
    return @{
        version = "2.0.0"
        logging = @{
            level = "Info"
            logToFile = $true
            logPath = "logs"
            maxLogFiles = 10
            maxLogSizeMB = 50
        }
        installation = @{
            retryCount = 3
            retryDelay = 5
            timeoutSeconds = 300
            preferredPackageManager = "winget"
            fallbackToChocolatey = $true
            parallelInstallation = $false
        }
        testing = @{
            functionalityTestPassRate = 0.7
            pathVerificationRequired = $true
            versionVerificationRequired = $true
            parallelExecution = $true
            testTimeout = 120
        }
        categories = @{
            "package-managers" = @{
                enabled = $true
                priority = 1
                tools = @("winget", "chocolatey", "scoop")
            }
            "development-tools" = @{
                enabled = $true
                priority = 2
                tools = @("git", "nodejs", "python", "vscode")
            }
            "cloud-tools" = @{
                enabled = $true
                priority = 3
                tools = @("aws-cli", "azure-cli", "gcloud", "kubectl")
            }
            "applications" = @{
                enabled = $true
                priority = 4
                tools = @("chrome", "firefox", "postman", "docker")
            }
            "ai-tools" = @{
                enabled = $true
                priority = 5
                tools = @("tensorflow", "pytorch", "jupyter", "anaconda")
            }
        }
        paths = @{
            templates = "templates"
            logs = "logs"
            cache = "cache"
            backup = "backup"
        }
    }
}

function Get-SoftwareDefinitions {
    <#
    .SYNOPSIS
        Loads software definitions from configuration
    #>
    $definitionsPath = Join-Path $script:ConfigRoot "software-definitions.json"
    
    if (Test-Path $definitionsPath) {
        return Get-Content $definitionsPath -Raw | ConvertFrom-Json -AsHashtable
    }
    
    return Get-DefaultSoftwareDefinitions
}

function Get-DefaultSoftwareDefinitions {
    <#
    .SYNOPSIS
        Returns default software definitions
    #>
    return @{
        "package-managers" = @{
            "winget" = @{
                name = "WinGet"
                executableNames = @("winget.exe", "winget")
                versionCommands = @("winget --version")
                testCommands = @("winget --version", "winget search notepad --count 1")
                installMethod = "builtin"
                updateCommands = @("winget upgrade --id Microsoft.AppInstaller")
            }
            "chocolatey" = @{
                name = "Chocolatey"
                executableNames = @("choco.exe", "choco")
                versionCommands = @("choco --version")
                testCommands = @("choco --version", "choco search chocolatey --limit-output")
                installMethod = "script"
                installScript = "https://chocolatey.org/install.ps1"
                updateCommands = @("choco upgrade chocolatey -y")
            }
            "scoop" = @{
                name = "Scoop"
                executableNames = @("scoop.exe", "scoop")
                versionCommands = @("scoop --version")
                testCommands = @("scoop --version", "scoop search git")
                installMethod = "script"
                installScript = "https://get.scoop.sh"
                updateCommands = @("scoop update scoop")
            }
        }
        "development-tools" = @{
            "git" = @{
                name = "Git"
                executableNames = @("git.exe", "git")
                versionCommands = @("git --version")
                testCommands = @("git --version")
                wingetId = "Git.Git"
                chocoId = "git"
                updateCommands = @("winget upgrade Git.Git")
            }
            "nodejs" = @{
                name = "Node.js"
                executableNames = @("node.exe", "node", "npm.exe", "npm")
                versionCommands = @("node --version", "npm --version")
                testCommands = @("node --version", "npm --version")
                wingetId = "OpenJS.NodeJS"
                chocoId = "nodejs"
                updateCommands = @("winget upgrade OpenJS.NodeJS")
            }
            "python" = @{
                name = "Python"
                executableNames = @("python.exe", "python", "pip.exe", "pip")
                versionCommands = @("python --version", "pip --version")
                testCommands = @("python --version", "pip --version")
                wingetId = "Python.Python.3"
                chocoId = "python"
                updateCommands = @("winget upgrade Python.Python.3")
            }
            "vscode" = @{
                name = "Visual Studio Code"
                executableNames = @("code.exe", "code")
                versionCommands = @("code --version")
                testCommands = @("code --version")
                wingetId = "Microsoft.VisualStudioCode"
                chocoId = "vscode"
                updateCommands = @("winget upgrade Microsoft.VisualStudioCode")
            }
        }
        "cloud-tools" = @{
            "aws-cli" = @{
                name = "AWS CLI"
                executableNames = @("aws.exe", "aws")
                versionCommands = @("aws --version")
                testCommands = @("aws --version")
                wingetId = "Amazon.AWSCLI"
                chocoId = "awscli"
                updateCommands = @("winget upgrade Amazon.AWSCLI")
            }
            "azure-cli" = @{
                name = "Azure CLI"
                executableNames = @("az.exe", "az")
                versionCommands = @("az --version")
                testCommands = @("az --version")
                wingetId = "Microsoft.AzureCLI"
                chocoId = "azure-cli"
                updateCommands = @("winget upgrade Microsoft.AzureCLI")
            }
            "gcloud" = @{
                name = "Google Cloud SDK"
                executableNames = @("gcloud.exe", "gcloud")
                versionCommands = @("gcloud --version")
                testCommands = @("gcloud --version")
                wingetId = "Google.CloudSDK"
                chocoId = "gcloudsdk"
                updateCommands = @("winget upgrade Google.CloudSDK")
            }
            "kubectl" = @{
                name = "Kubernetes CLI"
                executableNames = @("kubectl.exe", "kubectl")
                versionCommands = @("kubectl version --client")
                testCommands = @("kubectl version --client")
                wingetId = "Kubernetes.kubectl"
                chocoId = "kubernetes-cli"
                updateCommands = @("winget upgrade Kubernetes.kubectl")
            }
        }
        "applications" = @{
            "chrome" = @{
                name = "Google Chrome"
                executableNames = @("chrome.exe")
                versionCommands = @()
                testCommands = @("Test-Path `"${env:ProgramFiles}\Google\Chrome\Application\chrome.exe`"")
                wingetId = "Google.Chrome"
                chocoId = "googlechrome"
                updateCommands = @("winget upgrade Google.Chrome")
            }
            "firefox" = @{
                name = "Mozilla Firefox"
                executableNames = @("firefox.exe")
                versionCommands = @()
                testCommands = @("Test-Path `"${env:ProgramFiles}\Mozilla Firefox\firefox.exe`"")
                wingetId = "Mozilla.Firefox"
                chocoId = "firefox"
                updateCommands = @("winget upgrade Mozilla.Firefox")
            }
            "postman" = @{
                name = "Postman"
                executableNames = @("postman.exe")
                versionCommands = @()
                testCommands = @("Test-Path `"${env:ProgramFiles}\Postman\Postman.exe`"")
                wingetId = "Postman.Postman"
                chocoId = "postman"
                updateCommands = @("winget upgrade Postman.Postman")
            }
            "docker" = @{
                name = "Docker Desktop"
                executableNames = @("docker.exe", "docker")
                versionCommands = @("docker --version")
                testCommands = @("docker --version")
                wingetId = "Docker.DockerDesktop"
                chocoId = "docker-desktop"
                updateCommands = @("winget upgrade Docker.DockerDesktop")
            }
        }
        "ai-tools" = @{
            "tensorflow" = @{
                name = "TensorFlow"
                executableNames = @("python.exe")
                versionCommands = @("python -c `"import tensorflow as tf; print(tf.__version__)`"")
                testCommands = @("python -c `"import tensorflow as tf; print(tf.__version__)`"")
                installMethod = "pip"
                installCommands = @("pip install tensorflow")
                updateCommands = @("pip install --upgrade tensorflow")
            }
            "pytorch" = @{
                name = "PyTorch"
                executableNames = @("python.exe")
                versionCommands = @("python -c `"import torch; print(torch.__version__)`"")
                testCommands = @("python -c `"import torch; print(torch.__version__)`"")
                installMethod = "pip"
                installCommands = @("pip install torch torchvision torchaudio")
                updateCommands = @("pip install --upgrade torch torchvision torchaudio")
            }
            "jupyter" = @{
                name = "Jupyter Notebook"
                executableNames = @("jupyter.exe", "jupyter")
                versionCommands = @("jupyter --version")
                testCommands = @("jupyter --version")
                installMethod = "pip"
                installCommands = @("pip install jupyter")
                updateCommands = @("pip install --upgrade jupyter")
            }
            "anaconda" = @{
                name = "Anaconda"
                executableNames = @("conda.exe", "conda")
                versionCommands = @("conda --version")
                testCommands = @("conda --version")
                wingetId = "Anaconda.Miniconda3"
                chocoId = "anaconda3"
                updateCommands = @("conda update conda")
            }
        }
    }
}

function Save-Configuration {
    <#
    .SYNOPSIS
        Saves configuration to file
    .PARAMETER Configuration
        Configuration hashtable to save
    .PARAMETER ConfigPath
        Path to save configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,
        
        [string]$ConfigPath = (Get-ToolkitConfigPath)
    )
    
    try {
        # Ensure directory exists
        $configDir = Split-Path $ConfigPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Save configuration
        $Configuration | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
        
        Write-Host "Configuration saved to: $ConfigPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to save configuration: $($_.Exception.Message)"
        return $false
    }
}

function Validate-Configuration {
    <#
    .SYNOPSIS
        Validates configuration structure
    .PARAMETER Configuration
        Configuration to validate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )
    
    $requiredKeys = @("version", "logging", "installation", "testing", "categories")
    $errors = @()
    
    foreach ($key in $requiredKeys) {
        if (-not $Configuration.ContainsKey($key)) {
            $errors += "Missing required key: $key"
        }
    }
    
    if ($errors.Count -gt 0) {
        return @{
            IsValid = $false
            Errors = $errors
        }
    }
    
    return @{
        IsValid = $true
        Errors = @()
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ToolkitConfigPath',
    'Get-ToolkitConfiguration', 
    'Get-DefaultConfiguration',
    'Get-SoftwareDefinitions',
    'Get-DefaultSoftwareDefinitions',
    'Save-Configuration',
    'Validate-Configuration'
)
