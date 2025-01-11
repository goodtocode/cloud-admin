####################################################################################
# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Restart-WebAppPool.ps1 -Name "www.mysite.com"
####################################################################################

param (
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]	
 	[string]$WebSiteName = $(throw '-WebSiteName is a required parameter.'), #www.mysite.com
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]	
 	[string]$AppPoolName = $(throw '-AppPoolName is a required parameter.') #www.mysite.com-pool
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
#
# Modules
#
Install-Module -Name IISAdministration -Force

#
# Execute
#
if ((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped") {
    Stop-WebAppPool -Name $AppPoolName
}
$appPoolTimeout = 180 
$appPoolCounter = 0
while ((Get-WebAppPoolState -Name $AppPoolName).Value -ne "Stopped" -and $appPoolCounter -lt $appPoolTimeout) {
    Start-Sleep -Seconds 1
    $appPoolCounter++
}
if ((Get-WebAppPoolState -Name $AppPoolName).Value -eq "Stopped") {
    if ((Get-WebsiteState -Name $WebSiteName).Value -ne "Stopped") {
        Stop-Website -Name $WebSiteName
    }
    $websiteTimeout = 180
    $websiteCounter = 0
    while ((Get-WebsiteState -Name $WebSiteName).Value -ne "Stopped" -and $websiteCounter -lt $websiteTimeout) {
        Start-Sleep -Seconds 1
        $websiteCounter++
    }
    if ((Get-WebsiteState -Name $WebSiteName).Value -eq "Stopped") {
        Start-WebAppPool -Name $AppPoolName
		Write-Host "Started application pool: $AppPoolName"
        Start-Website -Name $WebSiteName
		Write-Host "Started website: $WebSiteName"
    } else {
        Write-Error "Failed to stop the website within the timeout period."
    }
} else {
    Write-Error "Failed to stop the application pool within the timeout period."
}
