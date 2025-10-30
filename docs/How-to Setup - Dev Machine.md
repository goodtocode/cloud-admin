# How-to: Setup Windows 11 Development Machine
## Pre-Requisites
1. Windows 11
1. Winget package manager (winget)

## Terminals and scripting
### Windows Terminal
```
winget install --id Microsoft.WindowsTerminal --silent
```

### Powershell
```
winget install --id Microsoft.PowerShell --silent
```

### Windows Power Toys
```
winget install --id Microsoft.PowerToys --source winget
```

### Windows Subsystem for Linux (wsl)
```
wsl --install
```

### Smartbear SoapUI API Testing
```
winget install --id Smartbear.SoapUI --source winget
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

### GitHub CLI (gh)
```
winget install --id GitHub.cli --silent
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
Install VS Code
```
winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
```
Add C# DevKit to VS Code
```
code --install-extension ms-dotnettools.csharp
```
IntelliCode for C#
```
code --install-extension ms-dotnettools.vscodeintellicode-csharp
```
Add Notebook to VS Code
Polyglot (.dib) no python needed
```
code --install-extension ms-dotnettools.dotnet-interactive-vscode
```
Add Kusto KQL and Log Analytics Workspace
```
code --install-extension donjayamanne.kusto
```

### General VS Code Extensions
Hex Editor
```
code --install-extension ms-vscode.hexeditor
```
PowerShell Extension
```
code --install-extension ms-vscode.powershell
```
Mermaid Diagram Extension
```
code --install-extension ms-vscode.copilot-mermaid-diagram
```
Remote WSL Extension
```
code --install-extension ms-vscode-remote.remote-wsl
```
XML Extension
```
code --install-extension redhat.vscode-xml
```
YAML Extension
```
code --install-extension redhat.vscode-yaml
```
Compare Folders Extension
```
code --install-extension moshfeu.compare-folders
```

### Paint.NET
```
winget install Paint.NET --silent
```

## .NET Development
### .NET SDK (dotnet)
```
winget install Microsoft.DotNet.SDK.9 --silent
```

### .NET Entity Framework CLI (dotnet ef)
Installf
```
dotnet tool install --global dotnet-ef
```
Remember to add the following package to appropriate project for migrations and scaffolding
```
dotnet add package Microsoft.EntityFrameworkCore.Design
```

## Azure Development
### Azure Management
```
code --install-extension ms-azuretools.vscode-azureresourcegroups
code --install-extension ms-azuretools.vscode-azure-github-copilot
```
### Azure CLI
```
winget install Microsoft.AzureCLI --silent
```
### Azure Bicep CLI (install python first)
```
winget install -e --id Microsoft.Bicep --silent
```
### Azure Function Core Tools CLI (func)
```
winget install Microsoft.Azure.FunctionsCoreTools --silent
```
(Optional) Run an Azure Function host in https
```
func host start --useHttps --cert host/certs/dev.myorg.com.pfx --password MyPass1234 --verbose
```

### Azurite Storage Emulator
```
npm install -g azurite
```

## AI Development
### GitHub Copilot Extension
```
code --install-extension GitHub.copilot
```
### GitHub Copilot Chat Extension
```
code --install-extension GitHub.copilot-chat
```
### Windows AI Studio Extension
```
code --install-extension ms-windows-ai-studio.windows-ai-studio
```
### Teams AI Foundry Extension
```
code --install-extension TeamsDevApp.vscode-ai-foundry
```

## Database Development
### SQL Server 2022  Developer Edition
Visual Studio installs SQL Express. If you want full-featured SQL Server, install the SQL Server Developer Edition or above.
[SQL Server Developer Edition or above](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
```
winget install Microsoft.SQLServer.2022.Developer -e --override "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=SQLEXPRESS /ENU"
```
Add Sql Server Management to VS Code
```
code --install-extension ms-mssql.mssql
code --install-extension ms-mssql.sql-database-projects-vscode
```

### Database Queries/ERD
```
code --install-extension DBCode.dbcode
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

## Power Platform Development
### Pac CLI in Visual Studio Code (pac)
Install VS Code Extension
```
code --install-extension microsoft-IsvExpTools.powerplatform-vscode
```

Command not found? Ensure path environment variable is updated with tools folder
```
[System.Environment]::SetEnvironmentVariable("Path", [System.Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Users\[your_user_name]\AppData\Roaming\Code\User\globalStorage\microsoft-isvexptools.powerplatform-vscode\pac\tools", "User")
```

Command not found? Try npm update
```
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

### .NET Development SSL Certificate (dotnet)
Allows dotnet run to use a developer certificate for https operations
- Generate and install to the cert store (trust) the certificate
    ```
    dotnet dev-certs https --trust
    ```
- (Optional) Export the certificate
    ```
    dotnet dev-certs https -ep ./certificate.crt -p $CREDENTIAL_PLACEHOLDER$ --trust --format PEM
    ```
- (Optional) Register certificate to IIS Express
    ```
    &"C:\Program Files (x86)\IIS Express\IisExpressAdminCmd.exe" setupSslUrl -url:https://localhost:<port> -CertHash:<CertificateThumbprint>
    ```