#-----------------------------------------------------------------------
# Remove-StorageVaultBackupItems [-Path [<String>]] [-VersionToReplace [<String>]]
#
# Example: .\Remove-RecoveryServiceVault -TenantId -SubscriptionId -ResourceGroup -StorageAccount
#-----------------------------------------------------------------------
# ***
# *** Parameters
# ***
param
(
	[string] $TenantId=$(throw '-TenantId is a required parameter. (00000000-0000-0000-0000-000000000000)'),
    [string] $SubscriptionId=$(throw '-TenantId is a required parameter. (00000000-0000-0000-0000-000000000000)'),
	[string] $ResourceGroup=$(throw '-ResourceGroup is a required parameter. (rg-PRODUCT-ENVIRONMENT-001)'),
    [string] $ContainerName=$(throw '-ContainerName is a required parameter. (rg-PRODUCT-ENVIRONMENT-001)'),
    [string] $RecoveryVaultName=$(throw '-RecoveryVaultName is a required parameter. (vaultPRODUCTENVIRONMENT001)'),
    [string] $ContainerType="AzureStorage",
    [string] $WorkloadType="AzureFiles"
)

# ***
# *** Initialize
# ***
if ($IsWindows) { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
$VerbosePreference = 'SilentlyContinue' #'Continue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
[DateTime]$Now = Get-Date
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths
Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript on $Now"
Write-Host "*****************************"
# Imports
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Import-Module "../../Azure.psm1"
Import-Module "../../System.psm1"
# Install the necessary modules
Install-Module -Name Az.Accounts -AllowClobber -Scope CurrentUser
Install-Module -Name Az.Resources -AllowClobber -Scope CurrentUser
Install-Module -Name Az.Storage -AllowClobber -Scope CurrentUser
Install-Module -Name Az.RecoveryServices -AllowClobber -Scope CurrentUser

# Connect to the Azure account
Connect-IfNotAuthenticated -TenantId $TenantId -SubscriptionId $SubscriptionId

# Get the Recovery Services vault
$vault = Get-AzRecoveryServicesVault -Name $RecoveryVaultName
Set-AzRecoveryServicesVaultContext -Vault $vault

# Get the backup containers
$containers = Get-AzRecoveryServicesBackupContainer -VaultId $vault.ID -ContainerType $ContainerType
$containers | Format-Table -Property Name, ContainerType, HealthStatus, FriendlyName

# Get the specific container
$container = $containers | Where-Object { $_.FriendlyName -eq $ContainerName }

$softDeletedItems = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -Container $container -WorkloadType $WorkloadType | Where-Object { $_.DeleteState -eq "ToBeDeleted" }
foreach ($item in $softDeletedItems) {
    Write-host "Undo ByContainer: $($item.Name) from $($item.ContainerName)"
    $item | Format-Table -Property Name, ContainerName, WorkloadType, ProtectionStatus, DeleteState
    Undo-AzRecoveryServicesBackupItemDeletion -Item $item -VaultId $vault.ID
    Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force
}

#$backupItems = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -BackupManagementType $ContainerType -WorkloadType $WorkloadType
$backupItems = Get-AzRecoveryServicesBackupItem -VaultId $vault.ID -Container $container -WorkloadType $WorkloadType
foreach ($item in $backupItems) {
    Write-host "Disable ByContainer: $($item.Name) from $($item.ContainerName)"
    $item | Format-Table -Property Name, ContainerName, WorkloadType, ProtectionStatus, DeleteState
    Disable-AzRecoveryServicesBackupProtection -Item $item -RemoveRecoveryPoints -Force
}

Remove-AzRecoveryServicesVault -Vault $vault -Force