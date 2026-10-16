# cloud-admin

A collection of PowerShell scripts, Azure/DevOps tooling, and SQL utilities for managing cloud infrastructure, developer environments, and Active Directory.

## ⭐ Showcase: New-DevMachine.ps1
[scripts/dev-experience/New-DevMachine.ps1](scripts/dev-experience/New-DevMachine.ps1) bootstraps a new Windows 11 developer machine end-to-end via `winget`: PowerShell, Windows Terminal, PowerToys, Git/GitHub CLI, Azure CLI/Bicep, .NET SDK, Visual Studio, VS Code (with a curated critical extension set), SQL Server Developer Edition, Azure Functions Core Tools, Ollama (+ Phi-4 model pull), Microsoft Scout Agent, and Microsoft 365 Copilot. Node.js, Python, and Power Platform tooling are available as opt-in extras.

```powershell
./scripts/dev-experience/New-DevMachine.ps1 -GitUserName "Your Name" -GitUserEmail "you@example.com"
```

See [docs/How-to Setup - Dev Machine.md](docs/How-to%20Setup%20-%20Dev%20Machine.md) for the full manual walkthrough this script automates.

## Repository Structure
Organized by intent: **know your estate** (governance), **reduce risk** (security), **change things safely** (resources), and **run the platform** (everything else).

| Folder | Purpose |
|---|---|
| [docs/](docs) | How-to guides and command references (AD, SQL, SSL, web, build server, Azure CLI). |
| [scripts/azure-governance/](scripts/azure-governance) | Estate-wide inventory and FinOps hygiene via Azure Resource Graph (read-only). |
| [scripts/azure-security/](scripts/azure-security) | Posture and identity-hygiene reports: Key Vault audit, expiring app credentials (read-only). |
| [scripts/azure-resources/](scripts/azure-resources) | Create/change/remove Azure resources: Key Vault, storage, SQL, Front Door, Logic Apps, Entra, Monitor. |
| [scripts/azure-devops/](scripts/azure-devops) | Azure DevOps helpers (branch names, library variables, pull requests). |
| [scripts/azure-functions/](scripts/azure-functions) | Local Azure Functions host and certificate helpers. |
| [scripts/cybersecurity/](scripts/cybersecurity) | Tokens, certificates, cryptography, TLS readiness, PCI DSS tests, event logs. |
| [scripts/dev-experience/](scripts/dev-experience) | Developer machine bootstrap and terminal profile. |
| [scripts/dns/](scripts/dns), [scripts/iis-web-server/](scripts/iis-web-server), [scripts/windows-servers/](scripts/windows-servers) | Classic infrastructure and server administration. |
| [scripts/dotnet/](scripts/dotnet), [scripts/sitecore/](scripts/sitecore), [scripts/imperva/](scripts/imperva) | App-specific build, publish, and load-balancer tooling. |
| [t-sql/](t-sql) | SQL Server DBA scripts. |

Shared modules: [scripts/AzureCli.psm1](scripts/AzureCli.psm1) (az CLI + Resource Graph helpers), [scripts/Azure.psm1](scripts/Azure.psm1), [scripts/System.psm1](scripts/System.psm1).

## Modern Azure scripts (start here)
All read-only unless noted, `az` CLI only (no extensions), work across every subscription you can access, and export CSV with `-OutputPath`.

| Script | Use it to |
|---|---|
| [Get-AzKeyVaultSecurityAudit.ps1](scripts/azure-security/Get-AzKeyVaultSecurityAudit.ps1) | Find vaults on legacy access policies, without purge protection, or open to the public internet. |
| [Get-AzAppCredentialExpiry.ps1](scripts/azure-security/Get-AzAppCredentialExpiry.ps1) | Prevent outages from expired Entra app secrets/certificates. |
| [Get-AzOrphanedResources.ps1](scripts/azure-governance/Get-AzOrphanedResources.ps1) | Find unattached disks, idle public IPs, orphaned NICs and other waste. |
| [Convert-AzKeyVaultToRbac.ps1](scripts/azure-resources/key-vault/Convert-AzKeyVaultToRbac.ps1) | **Changes state.** Migrate access-policy vaults to RBAC with equivalent built-in roles. Run with `-WhatIf` first. |

```powershell
./scripts/azure-security/Get-AzKeyVaultSecurityAudit.ps1 -OutputPath ./kv-audit.csv
./scripts/azure-resources/key-vault/Convert-AzKeyVaultToRbac.ps1 -SubscriptionId "<name-or-id>" -WhatIf
```

[Set-AzKeyVaultAclGroup.ps1](scripts/azure-resources/key-vault/Set-AzKeyVaultAclGroup.ps1) grants groups access-policy permissions on legacy vaults. Use it only as a short-term bridge (for example, data migrations) until vaults are moved to RBAC.

## Modernization backlog
Older scripts predate current practice. When touching them, prefer: Microsoft Graph / `az ad` over the retired `AzureAD` module (for example [Add-ManagedIdentityRole.ps1](scripts/azure-resources/azure-ad/Add-ManagedIdentityRole.ps1)), `[Parameter(Mandatory)]` over `$(throw ...)` defaults, no `Set-ExecutionPolicy Unrestricted`, and `-WhatIf` on every destructive script.

## Conventions
- Shared modules live only in [scripts/](scripts). Import them with `Join-Path $PSScriptRoot` (new scripts) or a relative path (older scripts).
- Scripts that change state support `-WhatIf` (`SupportsShouldProcess`). Run with `-WhatIf` first.
- No secrets, tenant/subscription IDs, or customer data in the repo; use placeholders (`00000000-...`).
- See [.github/copilot-instructions.md](.github/copilot-instructions.md) for full authoring guidance.