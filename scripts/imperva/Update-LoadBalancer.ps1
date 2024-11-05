####################################################################################
# To execute
#   1. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   2. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   3. In powershell, run script: 
#      .\Update-LoadBalancer.ps1 -IPAddress 111.222.333.4444 -ServerId 12345 -ApiKey 00000000-0000-0000-0000-000000000000 -ApiId 12345
# Imperva Swagger: https://docs.imperva.com/bundle/cloud-application-security/page/cloud-v1-api-definition.htm
####################################################################################

param (
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
 	[string]$IPAddress = $(throw '-IPAddress is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$ServerId = $(throw '-ServerId is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[string]$ApiKey = $(throw '-ApiKey is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[string]$ApiId = $(throw '-ApiId is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[string]$Enabled = $(throw '-Enabled is a required parameter.')
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

$headers = @{
    'accept' = 'application/json'
    'x-API-Key' = $ApiKey
    'x-API-Id' = $ApiId
}

$headers | Select-Object accept, x-API-Key, x-API-Id | Format-Table 

$uri = "https://my.imperva.com/api/prov/v1/sites/dataCenters/servers/edit?server_id=$ServerId&server_address=$IPAddress&is_enabled=$Enabled&is_standby=false"

Write-Host "URI: $uri"

$response = Invoke-RestMethod -Uri $uri `
                               -Method 'POST' `
                               -Headers $headers `
                               -Body ''