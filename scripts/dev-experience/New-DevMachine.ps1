<#
.SYNOPSIS
    Sets up a new developer machine with mainstream tools and optional extras.
.DESCRIPTION
    Installs .NET SDK, PowerShell, Visual Studio, VS Code, SQL Server Developer Edition by default.
    Also installs Ollama, Microsoft Scout Agent, and Microsoft 365 Copilot by default for local AI
    model/runtime support and pulls Phi-4.
    JavaScript/Node.js and Python are strongly optional and are only installed when explicitly requested.
    Optionally installs Power Platform tools and non-mainstream .NET SDKs.
.PARAMETER InstallNode
    Installs Node.js and JavaScript tooling if set to $true.
.PARAMETER InstallPython
    Installs Python if set to $true.
.PARAMETER InstallPowerPlatform
    Installs Power Platform CLI/tools if set to $true.
.PARAMETER InstallDotNetExtras
    Installs non-mainstream .NET SDKs if set to $true.
.PARAMETER GitUserName
    Sets git config --global user.name to this value if provided.
.PARAMETER GitUserEmail
    Sets git config --global user.email to this value if provided.
.EXAMPLE
    .\New-DevMachine.ps1 -InstallNode $true -InstallPython $false -GitUserName "Your Name" -GitUserEmail "you@example.com"
#>

param(
    [bool]$InstallNode = $false,
    [bool]$InstallPython = $false,
    [bool]$InstallPowerPlatform = $false,
    [bool]$InstallDotNetExtras = $false,
    [string]$GitUserName = "",
    [string]$GitUserEmail = ""
)

####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'SilentlyContinue' # 'Continue'
if ($MyInvocation.MyCommand.Path) {
    [String]$ThisScript = $MyInvocation.MyCommand.Path
} else {
    [String]$ThisScript = (Get-Location).Path
}
[String]$ThisDir = Split-Path $ThisScript
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths

Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript On: $(Get-Date)"
Write-Host "*****************************"
####################################################################################

Write-Host "Starting developer machine setup..." -ForegroundColor Cyan

# General Developer Experience
Write-Host "\n==============================="
Write-Host "Installing PowerShell..." -ForegroundColor Yellow
Write-Host "===============================\n"
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.PowerShell --silent
} else {
    Write-Host "PowerShell already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command wt -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.WindowsTerminal --silent
} else {
    Write-Host "Windows Terminal already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command powertoys -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.PowerToys --source winget
} else {
    Write-Host "PowerToys already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command "StorageExplorer" -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.Azure.StorageExplorer -e
} else {
    Write-Host "Azure Storage Explorer already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git --silent
} else {
    Write-Host "Git already installed." -ForegroundColor DarkGray
}
if ($GitUserName) {
    git config --global user.name $GitUserName
}
if ($GitUserEmail) {
    git config --global user.email $GitUserEmail
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    winget install --id GitHub.cli --silent
} else {
    Write-Host "GitHub CLI already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command "PaintDotNet" -ErrorAction SilentlyContinue)) {
    winget install Paint.NET --silent
} else {
    Write-Host "Paint.NET already installed." -ForegroundColor DarkGray
}
try {
    if (-not (wsl -l -q | Select-String -Pattern "Ubuntu")) {
        wsl --install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "WSL installation failed or is corrupted. Please repair WSL manually and re-run this script." -ForegroundColor Red
        }
    } else {
        Write-Host "WSL already installed." -ForegroundColor DarkGray
    }
} catch {
    Write-Host "WSL installation encountered an error: $_.Exception.Message. Please repair WSL manually and re-run this script." -ForegroundColor Red
}

# Azure Developer Experience
Write-Host "\n==============================="
Write-Host "Installing Azure tooling..." -ForegroundColor Yellow
Write-Host "===============================\n"
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    winget install Microsoft.AzureCLI --silent
} else {
    Write-Host "Azure CLI already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command bicep -ErrorAction SilentlyContinue)) {
    winget install -e --id Microsoft.Bicep --silent
} else {
    Write-Host "Azure Bicep CLI already installed." -ForegroundColor DarkGray
}

# .NET Developer Experience
Write-Host "\n==============================="
Write-Host "Installing .NET developer experience..." -ForegroundColor Yellow
Write-Host "===============================\n"
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.DotNet.SDK.10 --silent
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine) + ";" + [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        Write-Host "dotnet still not found after install. Please restart your shell and re-run this script to complete .NET setup." -ForegroundColor Red
    } else {
        if (-not (dotnet tool list -g | Select-String -Pattern "dotnet-ef")) {
            dotnet tool install --global dotnet-ef
        } else {
            Write-Host "dotnet-ef tool already installed." -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host ".NET SDK already installed." -ForegroundColor DarkGray
    if (-not (dotnet tool list -g | Select-String -Pattern "dotnet-ef")) {
        dotnet tool install --global dotnet-ef
    } else {
        Write-Host "dotnet-ef tool already installed." -ForegroundColor DarkGray
    }
}
dotnet dev-certs https --trust
if (-not (Get-Command devenv -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.VisualStudio.Community --override "--quiet --add Microsoft.Visualstudio.Workload.Azure --add Microsoft.VisualStudio.Workload.Data --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb"
} else {
    Write-Host "Visual Studio already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.VisualStudioCode --exact --silent --accept-package-agreements --accept-source-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine) + ";" + [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Host "VS Code still not found after install. Please restart your shell and re-run this script to complete VS Code setup and extension installation." -ForegroundColor Red
    }
}
if (Get-Command code -ErrorAction SilentlyContinue) {
    # Critical: C# (csharp), SQL Project, SSMS (mssql), Bicep, YAML (redhat), PowerShell. DBCode and redhat.vscode-yaml are the only non-Microsoft exceptions kept.
    $extensions = @(
        "ms-dotnettools.csharp",
        "ms-dotnettools.vscodeintellicode-csharp",
        "ms-vscode.hexeditor",
        "ms-vscode.powershell",
        "ms-vscode.copilot-mermaid-diagram",
        "ms-vscode-remote.remote-wsl",
        "redhat.vscode-yaml",
        "ms-azuretools.vscode-bicep",
        "ms-azuretools.vscode-azureresourcegroups",
        "ms-azuretools.vscode-azure-github-copilot",
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "ms-windows-ai-studio.windows-ai-studio",
        "ms-mssql.mssql",
        "ms-mssql.sql-database-projects-vscode",
        "DBCode.dbcode"
    )
    foreach ($ext in $extensions) {
        if (-not (code --list-extensions | Select-String -Pattern "^$ext$")) {
            Write-Host "\n--- Installing VS Code extension: $ext ---\n" -ForegroundColor Green
            code --install-extension $ext
        } else {
            Write-Host "VS Code extension $ext already installed." -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "VS Code command not found. Please restart your shell and re-run this script to install extensions." -ForegroundColor Red
}
if (-not (Get-Command sqlservr -ErrorAction SilentlyContinue)) {
    Write-Host "\n--- Installing SQL Server Developer Edition ---\n" -ForegroundColor Yellow
    winget install Microsoft.SQLServer.2022.Developer -e --override "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /ENU"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "SQL Server installation did not complete successfully (exit code $LASTEXITCODE). You may need to retry or install manually." -ForegroundColor Red
    } else {
        Write-Host "SQL Server Developer installed using default instance settings." -ForegroundColor DarkGray
    }
} else {
    Write-Host "SQL Server Developer Edition already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command func -ErrorAction SilentlyContinue)) {
    Write-Host "\n--- Installing Azure Functions Core Tools ---\n" -ForegroundColor Yellow
    winget install Microsoft.Azure.FunctionsCoreTools --silent
} else {
    Write-Host "Azure Functions Core Tools already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "\n--- Installing Ollama ---\n" -ForegroundColor Yellow
    winget install --id Ollama.Ollama -e --silent
} else {
    Write-Host "Ollama already installed." -ForegroundColor DarkGray
}
Write-Host "\n--- Installing Microsoft Scout Agent ---\n" -ForegroundColor Yellow
winget install --id Microsoft.ScoutAgent --exact --silent --accept-package-agreements --accept-source-agreements
Write-Host "\n--- Installing Microsoft 365 Copilot ---\n" -ForegroundColor Yellow
winget install --id Microsoft.365Copilot --exact --silent --accept-package-agreements --accept-source-agreements

$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine) + ";" + [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "Ollama command not found after install. Please open a new terminal window and run: ollama pull phi4" -ForegroundColor Red
} else {
    $phi4Installed = $false
    try {
        $phi4Installed = [bool](ollama list 2>$null | Where-Object { $_ -match '^\s*phi4(?::\S+)?\s' })
    } catch {
        Write-Host "Unable to query existing Ollama models. Attempting to pull Phi-4 anyway..." -ForegroundColor Yellow
    }

    if (-not $phi4Installed) {
        Write-Host "\n--- Pulling Phi-4 model in Ollama ---\n" -ForegroundColor Yellow
        ollama pull phi4
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Phi-4 pull failed. If this is a fresh install, open a new terminal window and re-run: ollama pull phi4" -ForegroundColor Red
        }
    } else {
        Write-Host "Phi-4 already installed in Ollama." -ForegroundColor DarkGray
    }
}

# Optional installations
if ($InstallNode) {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "\n--- Installing Node.js and JavaScript tooling ---\n" -ForegroundColor Green
        winget install --id OpenJS.NodeJS --silent
        # Optionally install npm, yarn, etc.
    } else {
        Write-Host "Node.js already installed." -ForegroundColor DarkGray
    }
}

if ($InstallPython) {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "\n--- Installing Python ---\n" -ForegroundColor Green
        winget install --id Python.Python.3 --silent
    } else {
        Write-Host "Python already installed." -ForegroundColor DarkGray
    }
}

if ($InstallPowerPlatform) {
    if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
        Write-Host "\n--- Installing Power Platform CLI ---\n" -ForegroundColor Green
        winget install --id Microsoft.PowerPlatformCLI --silent
    } else {
        Write-Host "Power Platform CLI already installed." -ForegroundColor DarkGray
    }
    if (Get-Command code -ErrorAction SilentlyContinue) {
        if (-not (code --list-extensions | Select-String -Pattern "^microsoft-IsvExpTools.powerplatform-vscode$")) {
            code --install-extension microsoft-IsvExpTools.powerplatform-vscode
        } else {
            Write-Host "Power Platform VS Code extension already installed." -ForegroundColor DarkGray
        }
    }
}

Write-Host "Developer machine setup complete." -ForegroundColor Cyan

