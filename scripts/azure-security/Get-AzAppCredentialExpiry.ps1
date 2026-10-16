#-----------------------------------------------------------------------
# Get-AzAppCredentialExpiry [-WithinDays <Int>] [-IncludeServicePrincipals] [-ExcludeExpired] [-OutputPath <String>]
#
# Read-only report of Entra ID app registration secrets and certificates that are expired or
# expiring soon, to prevent credential-expiry outages. Prefer federated credentials / managed
# identities; use this to find what still depends on secrets.
#
# Requires: az login with permission to read applications (Application.Read.All or Directory Reader).
#
# Example: .\Get-AzAppCredentialExpiry.ps1 -WithinDays 60
# Example: .\Get-AzAppCredentialExpiry.ps1 -WithinDays 30 -IncludeServicePrincipals -OutputPath .\expiring.csv
#-----------------------------------------------------------------------
[CmdletBinding()]
param
(
    [int] $WithinDays = 60,
    [switch] $IncludeServicePrincipals,
    [switch] $ExcludeExpired,
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../AzureCli.psm1') -Force
Connect-AzCliIfNeeded

$now = Get-Date
$projection = '[].{name:displayName,appId:appId,secrets:passwordCredentials,certs:keyCredentials}'

function ConvertTo-CredentialRow($items, $kind) {
    foreach ($i in $items) {
        foreach ($c in @($i.secrets)) { if ($c) { [pscustomobject]@{ Kind = $kind; Application = $i.name; AppId = $i.appId; Type = 'Secret'; Credential = $c.displayName; KeyId = $c.keyId; EndDate = [datetime]$c.endDateTime } } }
        foreach ($c in @($i.certs))   { if ($c) { [pscustomobject]@{ Kind = $kind; Application = $i.name; AppId = $i.appId; Type = 'Certificate'; Credential = $c.displayName; KeyId = $c.keyId; EndDate = [datetime]$c.endDateTime } } }
    }
}

Write-Host 'Reading app registrations...'
$rows = @(ConvertTo-CredentialRow @(Invoke-Az ad app list --all --query $projection -o json | ConvertFrom-Json) 'AppRegistration')
if ($IncludeServicePrincipals) {
    Write-Host 'Reading service principals...'
    $rows += @(ConvertTo-CredentialRow @(Invoke-Az ad sp list --all --query $projection -o json | ConvertFrom-Json) 'ServicePrincipal')
}

$report = $rows | ForEach-Object {
    $days = [int][math]::Floor(($_.EndDate - $now).TotalDays)
    $_ | Add-Member -NotePropertyName DaysRemaining -NotePropertyValue $days -PassThru |
         Add-Member -NotePropertyName Status -NotePropertyValue $(if ($days -lt 0) { 'Expired' } else { 'Expiring' }) -PassThru
} | Where-Object { $_.DaysRemaining -le $WithinDays -and -not ($ExcludeExpired -and $_.Status -eq 'Expired') } |
    Sort-Object DaysRemaining

$report = @($report)
$report | Format-Table Kind, Application, Type, EndDate, DaysRemaining, Status -AutoSize
Write-Host "Expired: $(@($report | Where-Object Status -eq 'Expired').Count) | Expiring within $WithinDays days: $(@($report | Where-Object Status -eq 'Expiring').Count)"

if ($OutputPath) { $report | Export-Csv -Path $OutputPath -NoTypeInformation; Write-Host "Saved: $OutputPath" }
