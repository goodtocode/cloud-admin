####################################################################################
# To execute
#   1. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   2. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   3. In powershell, run script: 
#      .\Publish-Item.ps1 -DatabaseName web -Paths "/sitecore/content/Global Settings/Blogs", "/sitecore/content/Global Settings/News"
####################################################################################

param (
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
 	[string]$DatabaseName = $(throw '-DatabaseName is a required parameter.'),
    [string[]]$Paths = $(throw '-Paths is a required parameter.')
)
####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'Continue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths
Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript On: $(Get-Date)"
Write-Host "*****************************"
####################################################################################

$targetDatabase = "web"

$publishWithChildrenPaths = @(
    "/sitecore/templates/My/Content/Pages/Blog",
    "/sitecore/templates/My/Content/Auxiliary/Blog Author"
)

$publishWithoutChildrenPaths = @(
    "/sitecore/content/My Website/Shared/People"
)

foreach ($path in $publishWithChildrenPaths) {
    $item = Get-Item -Path $path
    if ($null -ne $item) {
        Publish-Item -Item $item -Target $targetDatabase -PublishMode Smart -Recurse
    }
    else {
        Write-Host "Item not found at path: $path"
    }
}

foreach ($path in $publishWithoutChildrenPaths) {
    $item = Get-Item -Path $path
    if ($null -ne $item) {
        Publish-Item -Item $item -Target $targetDatabase -PublishMode Smart -Recurse:$false
    }
    else {
        Write-Host "Item not found at path: $path"
    }
}