####################################################################################
# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Get-AzureAd.ps1
####################################################################################

param (
)

####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'SilentlyContinue' # 'Continue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths
Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript On: $(Get-Date)"
Write-Host "*****************************"
####################################################################################
$srcResourceGroupName = "YourSourceResourceGroup"
$srcStorageAccountName = "YourSourceStorageAccount"
$srcContainer = "YourSourceContainer"
$destResourceGroupName = "YourDestResourceGroup"
$destStorageAccountName = "YourDestStorageAccount"
$destContainer = "YourDestContainer"

$srcStorageKey = (Get-AzStorageAccountKey -ResourceGroupName $srcResourceGroupName -Name $srcStorageAccountName)[0].Value
$destStorageKey = (Get-AzStorageAccountKey -ResourceGroupName $destResourceGroupName -Name $destStorageAccountName)[0].Value

$srcContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName -StorageAccountKey $srcStorageKey
$destContext = New-AzStorageContext -StorageAccountName $destStorageAccountName -StorageAccountKey $destStorageKey

Get-AzStorageBlob -Container $srcContainer -Context $srcContext | ForEach-Object {
    Start-AzStorageBlobCopy -SrcBlob $_.Name -DestContainer $destContainer -DestContext $destContext -Force
}
