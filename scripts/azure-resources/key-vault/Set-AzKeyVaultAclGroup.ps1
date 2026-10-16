#-----------------------------------------------------------------------
# Set-AzKeyVaultAclGroup [-Group <String[]>] [-KeyVault <String[]>] [-WhatIf]
#
# Grants one or more Entra ID security groups ALL key/secret/certificate
# permissions on legacy Access Policy (non-RBAC) Key Vaults in a subscription.
# Does az login, lets the user pick a subscription from a UI list.
#
# -Group     Group display names or object IDs (GUIDs).
# -KeyVault  Optional. Vault names to limit to. Default: every access-policy vault in the subscription.
#
# Example: .\Set-AzKeyVaultAclGroup.ps1 -Group "Cloud Engineers"
# -Template  Portal-style permission template (default 'All'): Key Management, Secret Management,
#            Certificate Management, Key & Secret Management, Secret & Certificate Management,
#            Key, Secret, & Certificate Management, SQL Server Connector,
#            Azure Data Lake Storage or Azure Storage, Azure Backup, Exchange Online Customer Key,
#            SharePoint Online Customer Key, Azure Information BYOK
# -KeyPermissions / -SecretPermissions / -CertificatePermissions
#            Override the template for that category (e.g. -SecretPermissions get,list). @() grants none.
#
# Example: .\Set-AzKeyVaultAclGroup.ps1 -Group "Cloud Engineers" -KeyVault kv-devtest-myproduct-001,kv-devtest-myplatform-001
# Example: .\Set-AzKeyVaultAclGroup.ps1 -Group "Cloud Engineers" -Template "Secret Management"
# Example: .\Set-AzKeyVaultAclGroup.ps1 -Group "Cloud Engineers" -Template "All" -KeyPermissions get,list
#-----------------------------------------------------------------------
[CmdletBinding(SupportsShouldProcess)]
param
(
    [Parameter(Mandatory)][string[]] $Group,
    [string[]] $KeyVault,
    [ValidateSet('All','Key Management','Secret Management','Certificate Management',
        'Key & Secret Management','Secret & Certificate Management','Key, Secret, & Certificate Management',
        'SQL Server Connector','Azure Data Lake Storage or Azure Storage','Azure Backup',
        'Exchange Online Customer Key','SharePoint Online Customer Key','Azure Information BYOK')]
    [string] $Template = 'All',
    # Explicit lists override the template for that category. Use @() to grant none.
    [string[]] $KeyPermissions,
    [string[]] $SecretPermissions,
    [string[]] $CertificatePermissions
)

$ErrorActionPreference = 'Stop'

# Same permission sets as the Azure portal access policy templates
$allKey = 'get','list','update','create','import','delete','recover','backup','restore','purge',
    'decrypt','encrypt','unwrapKey','wrapKey','verify','sign','release','rotate','getrotationpolicy','setrotationpolicy'
$allSecret = 'get','list','set','delete','recover','backup','restore','purge'
$allCert = 'get','list','update','create','import','delete','recover','backup','restore',
    'managecontacts','manageissuers','getissuers','listissuers','setissuers','deleteissuers','purge'
$mgmtKey = 'get','list','update','create','import','delete','recover','backup','restore','rotate','getrotationpolicy','setrotationpolicy','purge'
$mgmtSecret = 'get','list','set','delete','recover','backup','restore','purge'
$mgmtCert = 'get','list','update','create','import','delete','recover','backup','restore',
    'managecontacts','manageissuers','getissuers','listissuers','setissuers','deleteissuers','purge'

$templates = @{
    'All'                                    = @{ Key = $allKey;  Secret = $allSecret;  Cert = $allCert }
    'Key Management'                         = @{ Key = $mgmtKey; Secret = @();         Cert = @() }
    'Secret Management'                      = @{ Key = @();      Secret = $mgmtSecret; Cert = @() }
    'Certificate Management'                 = @{ Key = @();      Secret = @();         Cert = $mgmtCert }
    'Key & Secret Management'                = @{ Key = $mgmtKey; Secret = $mgmtSecret; Cert = @() }
    'Secret & Certificate Management'        = @{ Key = @();      Secret = $mgmtSecret; Cert = $mgmtCert }
    'Key, Secret, & Certificate Management'  = @{ Key = $mgmtKey; Secret = $mgmtSecret; Cert = $mgmtCert }
    'SQL Server Connector'                   = @{ Key = 'get','list','wrapKey','unwrapKey'; Secret = @(); Cert = @() }
    'Azure Data Lake Storage or Azure Storage' = @{ Key = 'get','list','unwrapKey'; Secret = @(); Cert = @() }
    'Azure Backup'                           = @{ Key = 'get','list','backup'; Secret = 'get','list','backup'; Cert = @() }
    'Exchange Online Customer Key'           = @{ Key = 'get','create','delete','list','update','unwrapKey','wrapKey'; Secret = @(); Cert = @() }
    'SharePoint Online Customer Key'         = @{ Key = 'get','list','wrapKey','unwrapKey'; Secret = @(); Cert = @() }
    'Azure Information BYOK'                 = @{ Key = 'get','decrypt','sign'; Secret = @(); Cert = @() }
}
$t = $templates[$Template]
if (-not $PSBoundParameters.ContainsKey('KeyPermissions'))         { $KeyPermissions = $t.Key }
if (-not $PSBoundParameters.ContainsKey('SecretPermissions'))      { $SecretPermissions = $t.Secret }
if (-not $PSBoundParameters.ContainsKey('CertificatePermissions')) { $CertificatePermissions = $t.Cert }

$permArgs = @()
if ($KeyPermissions)         { $permArgs += '--key-permissions';         $permArgs += $KeyPermissions }
if ($SecretPermissions)      { $permArgs += '--secret-permissions';      $permArgs += $SecretPermissions }
if ($CertificatePermissions) { $permArgs += '--certificate-permissions'; $permArgs += $CertificatePermissions }
if (-not $permArgs) { throw 'No permissions selected.' }
Write-Host "Template: $Template"
Write-Host "Keys: $($KeyPermissions -join ',') | Secrets: $($SecretPermissions -join ',') | Certs: $($CertificatePermissions -join ',')"

# A corrupt/locked extension folder in ~/.azure breaks every az command; use a clean one.
# Only core commands are needed here, so no extensions are required.
$env:AZURE_EXTENSION_DIR = Join-Path $env:TEMP 'az-clean-extensions'
New-Item -ItemType Directory -Force -Path $env:AZURE_EXTENSION_DIR | Out-Null

function Invoke-Az {
    $errFile = New-TemporaryFile
    try {
        $out = & az @args 2>$errFile
        if ($LASTEXITCODE -ne 0) { throw ((Get-Content $errFile -Raw) + ($out | Out-String)) }
        $out
    } finally { Remove-Item $errFile -ErrorAction SilentlyContinue }
}

# ***
# *** Auth + subscription selection
# ***
Write-Host '*** Login ***'
Invoke-Az login --only-show-errors | Out-Null

$subs = @(Invoke-Az account list --query "[?state=='Enabled']" -o json | ConvertFrom-Json)
if (-not $subs) { throw 'No enabled subscriptions found.' }

$choice = $null
if (Get-Command Out-GridView -ErrorAction SilentlyContinue) {
    $choice = $subs | Select-Object name, id, tenantId |
        Out-GridView -Title 'Select a subscription' -OutputMode Single
} else {
    for ($i = 0; $i -lt $subs.Count; $i++) { Write-Host "[$i] $($subs[$i].name) ($($subs[$i].id))" }
    $idx = Read-Host 'Select subscription number'
    $choice = $subs[[int]$idx]
}
if (-not $choice) { throw 'No subscription selected.' }
Invoke-Az account set --subscription $choice.id | Out-Null
Write-Host "Subscription: $($choice.name)"

# ***
# *** Resolve groups to object IDs
# ***
$groupIds = foreach ($g in $Group) {
    if ($g -match '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$') { $g; continue }
    $found = @(Invoke-Az ad group list --display-name $g --query '[].id' -o json | ConvertFrom-Json)
    if (-not $found) { throw "Group not found: $g" }
    if ($found.Count -gt 1) { throw "Multiple groups named '$g'. Use the object ID." }
    $found[0]
}

# ***
# *** Select vaults
# ***
$vaults = @(Invoke-Az keyvault list --query '[].{name:name,rg:resourceGroup}' -o json | ConvertFrom-Json)
if ($KeyVault) {
    $missing = $KeyVault | Where-Object { $_ -notin $vaults.name }
    foreach ($m in $missing) { Write-Warning "SKIP (not in this subscription): $m" }
    $vaults = @($vaults | Where-Object { $_.name -in $KeyVault })
    if (-not $vaults) { Write-Warning 'None of the requested vaults exist in this subscription.'; return }
}

# ***
# *** Apply
# ***
$results = foreach ($v in $vaults) {
    $rbac = Invoke-Az keyvault show --name $v.name --resource-group $v.rg --query 'properties.enableRbacAuthorization' -o tsv
    if ($rbac -eq 'true') {
        Write-Host "SKIP (RBAC): $($v.name)"
        [pscustomobject]@{ Vault = $v.name; Group = '-'; Status = 'Skipped (RBAC)' }
        continue
    }
    foreach ($id in $groupIds) {
        $status = 'OK'
        if ($PSCmdlet.ShouldProcess("$($v.name)", "Grant all permissions to $id")) {
            try {
                Invoke-Az keyvault set-policy --name $v.name --resource-group $v.rg                 --object-id $id @permArgs -o none | Out-Null
            } catch { $status = "FAILED: $($_.Exception.Message.Trim())" }
        } else { $status = 'WhatIf' }
        Write-Host "$($v.name) <- $id : $status"
        [pscustomobject]@{ Vault = $v.name; Group = $id; Status = $status }
    }
}

Write-Host '*** Summary ***'
$results | Format-Table -AutoSize
