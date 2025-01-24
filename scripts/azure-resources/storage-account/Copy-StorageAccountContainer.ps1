####################################################################################
# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Copy-StorageAccountContainer.ps1 
####################################################################################

param (
    [Parameter(Mandatory=$true)][string]$SrcResourceGroupName,
    [Parameter(Mandatory=$true)][string]$SrcStorageAccountName,
    [Parameter(Mandatory=$true)][string]$SrcContainer,
    [Parameter(Mandatory=$true)][string]$DestResourceGroupName,
    [Parameter(Mandatory=$true)][string]$DestStorageAccountName,
    [Parameter(Mandatory=$true)][string]$DestContainer
)

####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'SilentlyContinue' # 'Continue'
####################################################################################

$SrcStorageKey = (Get-AzStorageAccountKey -ResourceGroupName $SrcResourceGroupName -Name $SrcStorageAccountName)[0].Value
$DestStorageKey = (Get-AzStorageAccountKey -ResourceGroupName $DestResourceGroupName -Name $DestStorageAccountName)[0].Value

$SrcContext = New-AzStorageContext -StorageAccountName $SrcStorageAccountName -StorageAccountKey $SrcStorageKey
$DestContext = New-AzStorageContext -StorageAccountName $DestStorageAccountName -StorageAccountKey $DestStorageKey

Get-AzStorageBlob -Container $SrcContainer -Context $SrcContext | ForEach-Object {
    Start-AzStorageBlobCopy -SrcBlob $_.Name -DestContainer $DestContainer -DestContext $DestContext -Force
}


