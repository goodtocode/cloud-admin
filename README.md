# cloud-admin

A collection of PowerShell scripts, Azure/DevOps tooling, and SQL utilities for managing cloud infrastructure, developer environments, and Active Directory.

## ⭐ Showcase: New-DevMachine.ps1
[scripts/dev-experience/New-DevMachine.ps1](scripts/dev-experience/New-DevMachine.ps1) bootstraps a new Windows 11 developer machine end-to-end via `winget`: PowerShell, Windows Terminal, PowerToys, Git/GitHub CLI, Azure CLI/Bicep, .NET SDK, Visual Studio, VS Code (with a curated critical extension set), SQL Server Developer Edition, Azure Functions Core Tools, Ollama (+ Phi-4 model pull), Microsoft Scout Agent, and Microsoft 365 Copilot. Node.js, Python, and Power Platform tooling are available as opt-in extras.

```powershell
./scripts/dev-experience/New-DevMachine.ps1 -GitUserName "Your Name" -GitUserEmail "you@example.com"
```

See [docs/How-to Setup - Dev Machine.md](docs/How-to%20Setup%20-%20Dev%20Machine.md) for the full manual walkthrough this script automates.

## Repository Structure
| Folder | Description |
|---|---|
| [docs/](docs) | How-to guides and command references |
| [scripts/](scripts) | PowerShell scripts for Azure, DevOps, dev machine setup, and Windows servers |
| [t-sql/](t-sql) | SQL Server DBA scripts |