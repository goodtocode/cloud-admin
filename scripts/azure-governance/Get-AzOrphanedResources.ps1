#-----------------------------------------------------------------------
# Get-AzOrphanedResources [-SubscriptionId <String[]>] [-SnapshotAgeDays <Int>] [-OutputPath <String>]
#
# Read-only cost/hygiene report of orphaned Azure resources across subscriptions (Azure Resource Graph):
# unattached disks, unassociated public IPs, orphaned NICs, unused NSGs, empty App Service plans, old snapshots.
# Review before deleting; this script never deletes anything.
#
# Example: .\Get-AzOrphanedResources.ps1
# Example: .\Get-AzOrphanedResources.ps1 -SubscriptionId aacn-devtest-200 -SnapshotAgeDays 60 -OutputPath .\orphans.csv
#-----------------------------------------------------------------------
[CmdletBinding()]
param
(
    [string[]] $SubscriptionId,
    [int] $SnapshotAgeDays = 90,
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../AzureCli.psm1') -Force

Connect-AzCliIfNeeded
$subs = @(Get-AzCliSubscription -Subscription $SubscriptionId)
if (-not $subs) { throw 'No matching enabled subscriptions.' }
$subName = @{}; $subs | ForEach-Object { $subName[$_.id] = $_.name }

$query = @"
resources
| where (type =~ 'microsoft.compute/disks' and properties.diskState =~ 'Unattached' and isempty(managedBy))
    or (type =~ 'microsoft.network/publicipaddresses' and isnull(properties.ipConfiguration) and isnull(properties.natGateway))
    or (type =~ 'microsoft.network/networkinterfaces' and isnull(properties.virtualMachine) and isnull(properties.privateEndpoint))
    or (type =~ 'microsoft.network/networksecuritygroups' and isnull(properties.networkInterfaces) and isnull(properties.subnets))
    or (type =~ 'microsoft.web/serverfarms' and tolong(properties.numberOfSites) == 0)
    or (type =~ 'microsoft.compute/snapshots' and todatetime(properties.timeCreated) < ago(${SnapshotAgeDays}d))
| project name, type = tolower(type), resourceGroup, subscriptionId, location, sku = tostring(sku.name), id
"@

$labels = @{
    'microsoft.compute/disks'                 = 'Unattached disk'
    'microsoft.network/publicipaddresses'     = 'Unassociated public IP'
    'microsoft.network/networkinterfaces'     = 'Orphaned NIC'
    'microsoft.network/networksecuritygroups' = 'Unused NSG'
    'microsoft.web/serverfarms'               = 'Empty App Service plan'
    'microsoft.compute/snapshots'             = "Snapshot older than $SnapshotAgeDays days"
}

$report = @(Invoke-AzResourceGraph -Query $query -SubscriptionId $subs.id | ForEach-Object {
    [pscustomobject]@{
        Subscription  = $subName[$_.subscriptionId]
        Category      = $labels[$_.type]
        Name          = $_.name
        ResourceGroup = $_.resourceGroup
        Location      = $_.location
        Sku           = $_.sku
        ResourceId    = $_.id
    }
} | Sort-Object Category, Subscription, Name)

$report | Format-Table Subscription, Category, Name, ResourceGroup, Sku -AutoSize
$report | Group-Object Category | Sort-Object Count -Descending | Format-Table Name, Count -AutoSize

if ($OutputPath) { $report | Export-Csv -Path $OutputPath -NoTypeInformation; Write-Host "Saved: $OutputPath" }
