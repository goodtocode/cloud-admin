####################################################################################
# To execute
#   1. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   2. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   3. In powershell, run script: 
#      .\Update-LoadBalancer.ps1 -IPAddress 111.222.333.4444 -SiteId 12345 -ApiKey 00000000-0000-0000-0000-000000000000 -ApiId 12345
# Imperva Swagger: https://docs.imperva.com/bundle/cloud-application-security/page/cloud-v1-api-definition.htm
####################################################################################

param (
    [string]$ApiId = $(throw '-ApiId is a required parameter.'),
	[string]$ApiKey = $(throw '-ApiKey is a required parameter.'),	
    [string]$SiteId = $(throw '-SiteId is a required parameter.'),
 	[string]$IPAddress = $(throw '-IPAddress is a required parameter.'),
	[string]$Enabled = $(throw '-Enabled is a required parameter.')
)
####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'Continue'
####################################################################################

$headers = @{
    'accept' = 'application/json'
    'x-API-Key' = "$ApiKey"
    'x-API-Id' = "$ApiId"
}

$headersObj = New-Object PSObject -Property $headers

$headersObj | Select-Object accept, 'x-API-Id' | Format-Table

# Query ServerID Here
$response = Invoke-RestMethod -Uri "https://my.imperva.com/api/prov/v1/sites/dataCenters/list?site_id=$SiteId" `
                                -Method 'POST' `
                                -Headers $headers

$serverId = $null
if ($null -ne $response -and $response.DCs -and $response.DCs.Count -gt 0 -and $response.DCs[0].servers) {
    foreach ($server in $response.DCs[0].servers) {
        if ($server.address -eq $IPAddress) {
            $serverId = $server.id
            break
        }
    }
}

if ($null -eq $serverId) {
    Write-Host "Server with IP address $IPAddress not found."
} else {
    $response = Invoke-RestMethod -Uri "https://my.imperva.com/api/prov/v1/sites/dataCenters/servers/edit?server_id=$serverId&server_address=$IPAddress&is_enabled=$Enabled&is_standby=false" `
                                   -Method 'POST' `
                                   -Headers $headers `
                                   -Body ''

    Write-Host "Response from API:"
    Write-Host ($response | ConvertTo-Json -Depth 10)
}