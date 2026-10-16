# azure-governance

**Purpose:** estate-wide visibility and cost hygiene (FinOps) using Azure Resource Graph. Scripts here report; they never delete.

| Script | What it does |
|---|---|
| [Get-AzOrphanedResources.ps1](Get-AzOrphanedResources.ps1) | Finds unattached disks, unassociated public IPs, orphaned NICs, unused NSGs, empty App Service plans, and old snapshots across subscriptions. |

Output can be exported with `-OutputPath` for review before any cleanup.
