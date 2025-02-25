#-----------------------------------------------------------------------
# Remove-StorageVaultBackupItems [-Path [<String>]] [-VersionToReplace [<String>]]
#
# Example: .\Remove-RecoveryServiceVault -TenantId -SubscriptionId -ResourceGroup -StorageAccount
#-----------------------------------------------------------------------
# ---
# --- Parameters
# ---
param
(
	[string] $TenantId=$(throw '-TenantId is a required parameter. (00000000-0000-0000-0000-000000000000)'),
    [string] $SubscriptionId=$(throw '-TenantId is a required parameter. (00000000-0000-0000-0000-000000000000)'),
	[string] $ResourceGroup=$(throw '-ResourceGroup is a required parameter. (rg-PRODUCT-ENVIRONMENT-001)'),
    [string] $ContainerName=$(throw '-ContainerName is a required parameter. (rg-PRODUCT-ENVIRONMENT-001)'),
    [string] $RecoveryVaultName=$(throw '-RecoveryVaultName is a required parameter. (vaultPRODUCTENVIRONMENT001)'),
    [string] $ContainerType="AzureStorage"
)

# ---
# --- Initialize
# ---
if ($IsWindows) { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
$VerbosePreference = 'SilentlyContinue' #'Continue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
[DateTime]$Now = Get-Date
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths
Write-Host "---------------------------"
Write-Host "--- Starting: $ThisScript on $Now"
Write-Host "---------------------------"
# Imports
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Import-Module "../../Azure.psm1"
Import-Module "../../System.psm1"
# ---
# --- Install required modules
# ---
Install-Module -Name Az.Accounts -AllowClobber -Scope CurrentUser
Install-Module -Name Az.Resources -AllowClobber -Scope CurrentUser
Install-Module -Name Az.Storage -AllowClobber -Scope CurrentUser
Install-Module -Name Az.RecoveryServices -AllowClobber -Scope CurrentUser

# ---
# --- Auth
# ---
Connect-IfNotAuthenticated -TenantId $TenantId -SubscriptionId $SubscriptionId

# ---
# --- Execute
# ---
$vault = Get-AzRecoveryServicesVault -Name $RecoveryVaultName
Set-AzRecoveryServicesVaultContext -Vault $vault

$containers = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType $ContainerType
foreach ($container in $containers) {
    $container | Format-Table -Property Name, ContainerType, HealthStatus, FriendlyName

    switch ($container.ContainerType) {
        "AzureVM" { $WorkloadType = "AzureVM" }
        "MAB" { $WorkloadType = "MAB" }
        "AzureSQL" { $WorkloadType = "SQLDatabase" }
        default { $WorkloadType = "AzureFiles" }
    }

    $backupItems = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -Container $container -WorkloadType $WorkloadType
    foreach ($item in $backupItems) {
        $item | Format-Table -Property Name, ContainerName, WorkloadType, ProtectionStatus, DeleteState
        if ($item.WorkloadType -eq 'AzureVM') {
            Write-host "Undo-AzRecoveryServicesBackupItemDeletion -Item $item -VaultId $vault.ID"
            Undo-AzRecoveryServicesBackupItemDeletion -Item $item -VaultId $vault.ID
        } else {
            Write-Host "Undo-deletion is not supported for $($item.WorkloadType)"
        }
        Write-host "Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force"    
        Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force
    }
}

Remove-AzRecoveryServicesVault -Vault $vault
