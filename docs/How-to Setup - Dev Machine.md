# How-to: Setup Windows 11 Development Machine
## Pre-Requisites
1. Windows 11
1. Winget package manager (winget)

## Terminals and scripting
### Windows Terminal
```
winget install Microsoft.WindowsTerminal --silent
```

### Powershell
```
winget install --id Microsoft.PowerShell
```

## Git version control system
### Git CLI (git)
```
winget install --id Git.Git --silent
```

Configure your name and email for commits
```
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

## IDEs and Editors
### Visual Studio
[Visual Studio Workload IDs](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022&preserve-view=true)
```
winget install --id Microsoft.VisualStudio.2022.Community --override "--quiet --add Microsoft.Visualstudio.Workload.Azure --add Microsoft.VisualStudio.Workload.Data --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb"
```
Common workloads:
* Microsoft.Visualstudio.Workload.Azure
* Microsoft.VisualStudio.Workload.NetCrossPlat
* Microsoft.VisualStudio.Workload.NetWeb
* Microsoft.VisualStudio.Workload.Node
* Microsoft.VisualStudio.Workload.ManagedGame
* Microsoft.VisualStudio.Workload.ManagedDesktop 
* Microsoft.VisualStudio.Workload.Office
* Microsoft.VisualStudio.Workload.Python
* Microsoft.VisualStudio.Workload.Universal
* Microsoft.VisualStudio.Workload.VisualStudioExtension

### VS Code (code .)
```
winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
```

### Azure Data Studio (code)
```
winget install Microsoft.AzureDataStudio --silent
```

### Paint.NET
```
winget install Paint.NET --silent
```

## .NET Development
### .NET SDK (dotnet)
```
winget install Microsoft.DotNet.SDK.8 --silent
```

## Javascript Development
### Node.js (node and npm)
```
winget install -e --id OpenJS.NodeJS --silent
```

## Python Development
### Python (pip)
```
winget install python.python.3.12 --silent
```
(Optional) Refresh PATH environment variable
```
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

## Power Platform Development
### Pac CLI in Visual Studio Code (pac)
```
code --install-extension microsoft-IsvExpTools.powerplatform-vscode

// Was still missing npm dependencies
cd c:\Users\[username]\AppData\Roaming\Code\User\globalStorage\microsoft-isvexptools.powerplatform-vscode\powerpages
npm update
```
Optionally connect and download metadata
```
pac auth create
pac org select -env ENV_GUID
pac paportal list
pac paportal download -p ./src -id PORTAL_GUID -o true -mv 2
```
Optionally connect and upload metadata
```
pac auth create
pac org select -env ENV_GUID
> pac paportal upload -p ./src
```

## Azure Development
### Azure Function Core Tools CLI (func)
```
winget install Microsoft.AzureFunctionsCoreTools --silent
```
(Optional) Run an Azure Function host in https
```
func host start --useHttps --cert host/certs/dev.myorg.com.pfx --password MyPass1234 --verbose
```

### Azurite Storage Emulator
```
npm install -g azurite
```





