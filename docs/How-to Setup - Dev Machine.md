# How-to: Setup Windows 11 Development Machine
## Pre-Requisites
1. Windows 11
1. Winget package manager (winget)

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

## IDEs, Editors and Terminal
### Visual Studio
```
winget install --id Microsoft.VisualStudio.2022.Community --override "--quiet --add Microsoft.Visualstudio.Workload.Azure"
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

### Windows Terminal
```
winget install Microsoft.WindowsTerminal --silent
```

### Azure Data Studio (code)
```
winget install Microsoft.AzureDataStudio --silent
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
```
Optionally connect and download metadata
```
pac auth create
pac org select -env ENV_GUID
pac portal list
pac paportal list
pac paportal download -p ./src -id PORTAL_GUID -o true -mv 2
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
winget install Microsoft.AzureStorageEmulator --silent
```





