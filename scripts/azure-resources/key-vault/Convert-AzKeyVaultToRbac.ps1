#-----------------------------------------------------------------------
# Convert-AzKeyVaultToRbac [-SubscriptionId <String>] [-Name <String[]>] [-SwitchToRbac] [-WhatIf]
#
# Migrates legacy access-policy Key Vaults to Azure RBAC (the recommended model).
# For every access policy it creates equivalent built-in role assignments at the vault scope:
#   keys:         write/lifecycle -> Key Vault Crypto Officer | crypto ops -> Key Vault Crypto User | get/list -> Key Vault Reader
#   secrets:      write/lifecycle -> Key Vault Secrets Officer | get/list -> Key Vault Secrets User
#   certificates: write/lifecycle -> Key Vault Certificates Officer | get/list -> Key Vault Reader
#   all three at officer level -> Key Vault Administrator
# Role assignments are created first; the vault is only flipped to RBAC when -SwitchToRbac is supplied
# and every assignment for that vault succeeded. Managed-storage ("storage") permissions are not mapped.
#
# Requires Owner or User Access Administrator on the vaults. ALWAYS run with -WhatIf first.
#
# Example: .\Convert-AzKeyVaultToRbac.ps1 -WhatIf
# Example: .\Convert-AzKeyVaultToRbac.ps1 -SubscriptionId aacn-devtest-200 -Name kv-devtest-cert-001 -SwitchToRbac
#-----------------------------------------------------------------------
[CmdletBinding(SupportsShouldProcess)]
param
(
    [string] $SubscriptionId,
    [string[]] $Name,
    [switch] $SwitchToRbac
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../../AzureCli.psm1') -Force

$keyWrite    = 'create','update','import','delete','recover','backup','restore','purge','rotate','setrotationpolicy'
$keyCrypto   = 'encrypt','decrypt','wrapkey','unwrapkey','sign','verify','release'
$secretWrite = 'set','delete','recover','backup','restore','purge'
$certWrite   = 'create','update','import','delete','recover','backup','restore','purge','managecontacts','manageissuers','setissuers','deleteissuers'
$read        = 'get','list'

function Get-RolesForPolicy($permissions) {
    $k = @($permissions.keys) | ForEach-Object { "$_".ToLower() }
    $s = @($permissions.secrets) | ForEach-Object { "$_".ToLower() }
    $c = @($permissions.certificates) | ForEach-Object { "$_".ToLower() }
    $any = { param($have, $want) [bool]($have | Where-Object { $_ -in $want -or $_ -eq 'all' }) }

    $keyOfficer  = & $any $k $keyWrite
    $secOfficer  = & $any $s $secretWrite
    $certOfficer = & $any $c $certWrite
    if ($keyOfficer -and $secOfficer -and $certOfficer) { return @('Key Vault Administrator') }

    $roles = @()
    if ($keyOfficer)                          { $roles += 'Key Vault Crypto Officer' }
    elseif (& $any $k $keyCrypto)             { $roles += 'Key Vault Crypto User' }
    elseif (& $any $k $read)                  { $roles += 'Key Vault Reader' }
    if ($secOfficer)                          { $roles += 'Key Vault Secrets Officer' }
    elseif (& $any $s $read)                  { $roles += 'Key Vault Secrets User' }
    if ($certOfficer)                         { $roles += 'Key Vault Certificates Officer' }
    elseif (& $any $c $read)                  { $roles += 'Key Vault Reader' }
    $roles | Select-Object -Unique
}

Connect-AzCliIfNeeded
if ($SubscriptionId) { Invoke-Az account set --subscription $SubscriptionId | Out-Null }
Write-Host "Subscription: $((Invoke-Az account show --query name -o tsv).Trim())"

$vaults = @(Invoke-Az keyvault list --query '[].{name:name,rg:resourceGroup}' -o json | ConvertFrom-Json)
if ($Name) {
    foreach ($m in ($Name | Where-Object { $_ -notin $vaults.name })) { Write-Warning "SKIP (not in this subscription): $m" }
    $vaults = @($vaults | Where-Object { $_.name -in $Name })
}

$results = foreach ($v in $vaults) {
    $vault = Invoke-Az keyvault show --name $v.name --resource-group $v.rg -o json | ConvertFrom-Json
    if ($vault.properties.enableRbacAuthorization) {
        [pscustomobject]@{ Vault = $v.name; ObjectId = '-'; Role = '-'; Status = 'Already RBAC' }
        continue
    }

    $failed = $false
    $assigned = @(Invoke-Az role assignment list --scope $vault.id --query '[].{p:principalId,r:roleDefinitionName}' -o json | ConvertFrom-Json)
    foreach ($policy in @($vault.properties.accessPolicies)) {
        foreach ($role in @(Get-RolesForPolicy $policy.permissions)) {
            $status = 'Created'
            if ($assigned | Where-Object { $_.p -eq $policy.objectId -and $_.r -eq $role }) { $status = 'Exists' }
            elseif ($PSCmdlet.ShouldProcess("$($v.name)", "Assign '$role' to $($policy.objectId)")) {
                try {
                    Invoke-Az role assignment create --assignee-object-id $policy.objectId --role $role --scope $vault.id -o none | Out-Null
                } catch {
                    if ($_.Exception.Message -match 'Cannot find user or service principal') { $status = 'Skipped (principal no longer exists)' }
                    else { $status = "FAILED: $($_.Exception.Message.Trim())"; $failed = $true }
                }
            } else { $status = 'WhatIf' }
            [pscustomobject]@{ Vault = $v.name; ObjectId = $policy.objectId; Role = $role; Status = $status }
        }
    }

    if ($SwitchToRbac) {
        if ($failed) { Write-Warning "Not switching $($v.name) to RBAC: some assignments failed." }
        elseif ($PSCmdlet.ShouldProcess($v.name, 'Enable RBAC authorization')) {
            Invoke-Az keyvault update --name $v.name --resource-group $v.rg --enable-rbac-authorization true -o none | Out-Null
            [pscustomobject]@{ Vault = $v.name; ObjectId = '-'; Role = '-'; Status = 'Switched to RBAC' }
        }
    }
}

$results | Format-Table -AutoSize
