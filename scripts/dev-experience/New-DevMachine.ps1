<#
.SYNOPSIS
    Sets up a new developer machine with mainstream tools and optional extras.
.DESCRIPTION
    Installs .NET SDK, PowerShell, Visual Studio 2022, VS Code, SQL Server Developer Edition by default.
    Optionally installs JavaScript/Node.js, Python, Power Platform tools, and non-mainstream .NET SDKs.
.PARAMETER InstallNode
    Installs Node.js and JavaScript tooling if set to $true.
.PARAMETER InstallPython
    Installs Python if set to $true.
.PARAMETER InstallPowerPlatform
    Installs Power Platform CLI/tools if set to $true.
.PARAMETER InstallDotNetExtras
    Installs non-mainstream .NET SDKs if set to $true.
.EXAMPLE
    .\New-DevMachine.ps1 -InstallNode $true -InstallPython $false
#>

param(
    [bool]$InstallNode = $false,
    [bool]$InstallPython = $false,
    [bool]$InstallPowerPlatform = $false,
    [bool]$InstallDotNetExtras = $false
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
if (-not (Get-Command "PaintDotNet" -ErrorAction SilentlyContinue)) {
    winget install Paint.NET --silent
} else {
    Write-Host "Paint.NET already installed." -ForegroundColor DarkGray
}
if (-not (wsl -l -q | Select-String -Pattern "Ubuntu")) {
    wsl --install
} else {
    Write-Host "WSL already installed." -ForegroundColor DarkGray
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
    winget install --id Microsoft.DotNet.SDK.9 --silent
} else {
    Write-Host ".NET SDK already installed." -ForegroundColor DarkGray
}
if (-not (dotnet tool list -g | Select-String -Pattern "dotnet-ef")) {
    dotnet tool install --global dotnet-ef
} else {
    Write-Host "dotnet-ef tool already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command devenv -ErrorAction SilentlyContinue)) {
    winget install --id Microsoft.VisualStudio.2022.Community --override "--quiet --add Microsoft.Visualstudio.Workload.Azure --add Microsoft.VisualStudio.Workload.Data --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb"
} else {
    Write-Host "Visual Studio 2022 already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
} else {
    Write-Host "VS Code already installed." -ForegroundColor DarkGray
}
# VS Code Extensions
$extensions = @(
    "ms-dotnettools.csharp",
    "ms-dotnettools.vscodeintellicode-csharp",
    "ms-dotnettools.dotnet-interactive-vscode",
    "donjayamanne.kusto",
    "ms-vscode.hexeditor",
    "ms-vscode.powershell",
    "ms-vscode.copilot-mermaid-diagram",
    "ms-vscode-remote.remote-wsl",
    "redhat.vscode-xml",
    "redhat.vscode-yaml",
    "moshfeu.compare-folders",
    "ms-azuretools.vscode-azureresourcegroups",
    "ms-azuretools.vscode-azure-github-copilot",
    "GitHub.copilot",
    "GitHub.copilot-chat",
    "ms-windows-ai-studio.windows-ai-studio",
    "TeamsDevApp.vscode-ai-foundry",
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
if (-not (Get-Command sqlservr -ErrorAction SilentlyContinue)) {
    Write-Host "\n--- Installing SQL Server Developer Edition ---\n" -ForegroundColor Yellow
    winget install Microsoft.SQLServer.2022.Developer -e --override "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=SQLEXPRESS /ENU"
} else {
    Write-Host "SQL Server Developer Edition already installed." -ForegroundColor DarkGray
}
if (-not (Get-Command func -ErrorAction SilentlyContinue)) {
    Write-Host "\n--- Installing Azure Functions Core Tools ---\n" -ForegroundColor Yellow
    winget install Microsoft.Azure.FunctionsCoreTools --silent
} else {
    Write-Host "Azure Functions Core Tools already installed." -ForegroundColor DarkGray
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
}

Write-Host "Developer machine setup complete." -ForegroundColor Cyan

