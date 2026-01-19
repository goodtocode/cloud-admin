param(
    [guid]$TenantId = "ca4fd2d7-85ea-42d2-b7b3-30ef2666c7ab",
    [guid]$subscriptionId = "fce95a24-209c-4e69-98de-885660170e1d",
    [string]$resourceGroup = "rg-platform-users-westus2-001",
    [string]$storageAccount = "stplatformdept001",
    [string]$containerName = "devops",
    [string]$userPrincipalId = "SourceVed Engineers"  # Can be UPN or Object ID
)

###############################################################
# Initialize
###############################################################
if ($IsWindows) { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
$VerbosePreference = 'SilentlyContinue' # Set to 'Continue' for verbose output
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
[DateTime]$Now = Get-Date
Set-Location $ThisDir # Ensure script runs from its own directory
Write-Host "---------------------------"
Write-Host "--- Starting: $ThisScript on $Now"
Write-Host "---------------------------"

###############################################################
# Execute
###############################################################
$requiredModules = @('Az.Accounts', 'Az.Cdn', 'Az.FrontDoor', 'Az.Resources')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Module $module not found. Installing..."
        try {
            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
        } catch {
            Write-Error "Failed to install module $module. Please install manually."
            exit 1
        }
    }
}

Connect-AzAccount -Tenant $TenantId -ErrorAction Stop
Set-AzContext -SubscriptionId $subscriptionId

# Get the storage account resource ID
$storageAccountResourceId = (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount).Id

# Get the container resource ID
$containerResourceId = "$storageAccountResourceId/blobServices/default/containers/$containerName"

# Assign Reader role at storage account level (to see it in Storage Explorer)
New-AzRoleAssignment -ObjectId $userPrincipalId `
    -RoleDefinitionName "Reader" `
    -Scope $storageAccountResourceId

# Assign Storage Blob Data Contributor at container level (to upload, create folders, list blobs)
New-AzRoleAssignment -ObjectId $userPrincipalId `
    -RoleDefinitionName "Storage Blob Data Contributor" `
    -Scope $containerResourceId