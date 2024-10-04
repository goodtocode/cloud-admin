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
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$TenantId = $(throw '-TenantId is a required parameter.'),
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$ClientId = $(throw '-ClientId is a required parameter.'),
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$ClientSecret = $(throw '-ClientSecret is a required parameter.'),
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$ScopeClientId = $(throw '-ScopeClientId is a required parameter.')
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

# Your curl command
Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -Method Post `
    -ContentType "application/x-www-form-urlencoded" `
    -Headers @{"Cookie" = "stsservicecookie=estsfd; x-ms-gateway-slice=estsfd" } `
    -Body @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "api://$ScopeClientId/.default"
}
