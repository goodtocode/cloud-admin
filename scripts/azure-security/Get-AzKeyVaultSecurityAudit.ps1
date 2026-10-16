#-----------------------------------------------------------------------
# Get-AzKeyVaultSecurityAudit [-SubscriptionId <String[]>] [-OutputPath <String>]
#
# Read-only posture audit of every Key Vault across your subscriptions (one Azure Resource Graph query).
# Flags: legacy access-policy model, purge protection off, soft delete off, open public network access.
#
# Example: .\Get-AzKeyVaultSecurityAudit.ps1
# Example: .\Get-AzKeyVaultSecurityAudit.ps1 -SubscriptionId aacn-devtest-200 -OutputPath .\kv-audit.csv
#-----------------------------------------------------------------------
[CmdletBinding()]
param
(
    [string[]] $SubscriptionId,
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../AzureCli.psm1') -Force

Connect-AzCliIfNeeded
$subs = @(Get-AzCliSubscription -Subscription $SubscriptionId)
if (-not $subs) { throw 'No matching enabled subscriptions.' }

$query = @'
resources
| where type =~ 'microsoft.keyvault/vaults'
| project name, resourceGroup, subscriptionId, location,
    accessModel = iff(properties.enableRbacAuthorization == true, 'RBAC', 'AccessPolicy'),
    softDelete = properties.enableSoftDelete,
    purgeProtection = properties.enablePurgeProtection,
    publicNetworkAccess = tostring(properties.publicNetworkAccess),
    firewallDefault = tostring(properties.networkAcls.defaultAction),
    privateEndpoints = array_length(properties.privateEndpointConnections)
'@

$subName = @{}; $subs | ForEach-Object { $subName[$_.id] = $_.name }
$vaults = @(Invoke-AzResourceGraph -Query $query -SubscriptionId $subs.id)

$report = foreach ($v in $vaults) {
    $findings = @()
    if ($v.accessModel -eq 'AccessPolicy') { $findings += 'Legacy access policies (migrate to RBAC)' }
    if (-not $v.purgeProtection)           { $findings += 'Purge protection off' }
    if ($v.softDelete -eq $false)          { $findings += 'Soft delete off' }
    if ($v.publicNetworkAccess -ne 'Disabled' -and $v.firewallDefault -ne 'Deny') { $findings += 'Open to public network' }
    [pscustomobject]@{
        Subscription     = $subName[$v.subscriptionId]
        Vault            = $v.name
        ResourceGroup    = $v.resourceGroup
        AccessModel      = $v.accessModel
        PurgeProtection  = [bool]$v.purgeProtection
        PublicAccess     = $v.publicNetworkAccess
        FirewallDefault  = $v.firewallDefault
        PrivateEndpoints = [int]$v.privateEndpoints
        FindingCount     = $findings.Count
        Findings         = $findings -join '; '
    }
}

$report = @($report | Sort-Object FindingCount -Descending)
$report | Format-Table Subscription, Vault, AccessModel, PurgeProtection, PublicAccess, FindingCount -AutoSize

Write-Host "Vaults: $($report.Count) | Access policies: $(@($report | Where-Object AccessModel -eq 'AccessPolicy').Count) | No purge protection: $(@($report | Where-Object { -not $_.PurgeProtection }).Count) | Open to public: $(@($report | Where-Object Findings -like '*public network*').Count)"

if ($OutputPath) { $report | Export-Csv -Path $OutputPath -NoTypeInformation; Write-Host "Saved: $OutputPath" }
