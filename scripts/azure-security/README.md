# azure-security

**Purpose:** read-only posture and identity-hygiene reporting across all subscriptions/tenant, so risks are found before they become incidents or outages.

| Script | What it does |
|---|---|
| [Get-AzKeyVaultSecurityAudit.ps1](Get-AzKeyVaultSecurityAudit.ps1) | Audits every Key Vault: legacy access policies, purge protection, soft delete, public network exposure. |
| [Get-AzAppCredentialExpiry.ps1](Get-AzAppCredentialExpiry.ps1) | Lists expired/expiring Entra app registration (and optionally service principal) secrets and certificates. |

All scripts are read-only, use the `az` CLI with no extensions, and can export to CSV with `-OutputPath`.
Related: [../azure-resources/key-vault/Convert-AzKeyVaultToRbac.ps1](../azure-resources/key-vault/Convert-AzKeyVaultToRbac.ps1) remediates the access-policy finding.
