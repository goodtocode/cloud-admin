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
Write-Host "Installing PowerShell..." -ForegroundColor Yellow
winget install --id Microsoft.PowerShell --silent
winget install --id Microsoft.WindowsTerminal --silent
winget install --id Microsoft.PowerToys --source winget
winget install --id Git.Git --silent
winget install Paint.NET --silent
wsl --install

# Azure Developer Experience
Write-Host "Installing Azure tooling..." -ForegroundColor Yellow
winget install Microsoft.AzureCLI --silent
winget install -e --id Microsoft.Bicep --silent
# .NET Developer Experience
Write-Host "Installing .NET developer experience..." -ForegroundColor Yellow
winget install --id Microsoft.DotNet.SDK.9 --silent

dotnet tool install --global dotnet-ef
winget install --id Microsoft.VisualStudio.2022.Community --override "--quiet --add Microsoft.Visualstudio.Workload.Azure --add Microsoft.VisualStudio.Workload.Data --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb"

winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
code --install-extension ms-dotnettools.csharp
dotnet tool install -g Microsoft.dotnet-interactive
dotnet interactive jupyter install

winget install Microsoft.SQLServer.2022.Developer -e --override "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=SQLEXPRESS /ENU"

winget install Microsoft.Azure.FunctionsCoreTools --silent

# Optional installations
if ($InstallNode) {
    Write-Host "Installing Node.js and JavaScript tooling..." -ForegroundColor Green
    winget install --id OpenJS.NodeJS --silent
    # Optionally install npm, yarn, etc.
}

if ($InstallPython) {
    Write-Host "Installing Python..." -ForegroundColor Green
    winget install --id Python.Python.3 --silent
}

if ($InstallPowerPlatform) {
    Write-Host "Installing Power Platform CLI..." -ForegroundColor Green
    winget install --id Microsoft.PowerPlatformCLI --silent
}

Write-Host "Developer machine setup complete." -ForegroundColor Cyan

