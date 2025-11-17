<#
.SYNOPSIS
Tests the Azure Front Door App Service for a specified parameter.

.DESCRIPTION
This script tests the Azure Front Door App Service by accepting a parameter to specify the target for testing. It is used to verify the configuration and connectivity of the App Service through Azure Front Door for any given input.

.PARAMETER <ParameterName>
The value to specify the target for testing (replace <ParameterName> with your actual parameter name).

.EXAMPLE
PS> .\Test-AfdAppService.ps1 -ParameterName "MyValue"
This will test the Azure Front Door App Service for the specified value "MyValue".

.NOTES
Author: GoodToCode
#>

param(
    [string]$AfdUrl,
    [string]$AppUrl
)

Write-Host "=== Testing App Service with AFD Host Header ==="
try {
    $afdHost = ([uri]$AfdUrl).Host
    $response = Invoke-WebRequest -Uri "https://$AppUrl/" -Headers @{ "Host" = $afdHost } -UseBasicParsing
    Write-Host "App Service with AFD Host Header Status: $($response.StatusCode)"
} catch {
    Write-Host "App Service with AFD Host Header Error: $($_.Exception.Message) Inner: $($_.Exception.InnerException.Message)"
}

Write-Host "=== Testing Front Door Endpoint ==="
try {
    $afdResponseRoot = Invoke-WebRequest -Uri "$AfdUrl/" -UseBasicParsing
    Write-Host "Root Path Status: $($afdResponseRoot.StatusCode)"
} catch {
    Write-Host "Root Path Error: $($_.Exception.Message)"
}

Write-Host "=== Testing Origin Health Probe (HEAD /) ==="
try {
    $originProbe = Invoke-WebRequest -Uri "https://$AppUrl/" -Method Head -UseBasicParsing
    Write-Host "Origin HEAD Status: $($originProbe.StatusCode)"
} catch {
    Write-Host "Origin HEAD Error: $($_.Exception.Message)"
}

Write-Host "=== Testing Origin GET ==="
try {
    $originGet = Invoke-WebRequest -Uri "https://$AppUrl/" -UseBasicParsing
    Write-Host "Origin GET Status: $($originGet.StatusCode)"
} catch {
    Write-Host "Origin GET Error: $($_.Exception.Message)"
}

Write-Host "=== Checking SSL Certificate ==="
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient($AppUrl, 443)
    $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({ $true }))
    $sslStream.AuthenticateAsClient($AppUrl)
    $cert = $sslStream.RemoteCertificate
    Write-Host "SSL Subject: $($cert.Subject)"
    Write-Host "SSL Issuer: $($cert.Issuer)"
    Write-Host "SSL Valid Until: $($cert.GetExpirationDateString())"
    $sslStream.Close()
    $tcpClient.Close()
} catch {
    Write-Host "SSL Check Error: $($_.Exception.Message)"
}

# === Azure Front Door CDN Resource Checks ===
Write-Host "=== Azure Front Door CDN Resource Checks ==="
try {
    $resourceGroup = "rg-platform-connectivity-westus2-001"
    $profileName = "afd-platform-hub-westus2-001"
    $endpointName = "afdend-appaacnorg-dev"
    $ruleSetName = "RewriteToRoot"

    Write-Host "-- CDN Profile --"
    $cdnProfile = Get-AzFrontDoorCdnProfile -ResourceGroupName $resourceGroup
    $cdnProfile | Format-List | Out-String | Write-Host

    Write-Host "-- CDN Endpoint --"
    $cdnEndpoint = Get-AzFrontDoorCdnEndpoint -ResourceGroupName $resourceGroup -ProfileName $profileName
    $cdnEndpoint | Format-List | Out-String | Write-Host

    Write-Host "-- CDN Route --"
    $cdnRoute = Get-AzFrontDoorCdnRoute -ResourceGroupName $resourceGroup -ProfileName $profileName -EndpointName $endpointName
    $cdnRoute | Format-List | Out-String | Write-Host

    Write-Host "-- CDN RuleSet --"
    $cdnRuleSet = Get-AzFrontDoorCdnRuleSet -ResourceGroupName $resourceGroup -ProfileName $profileName
    $cdnRuleSet | Format-List | Out-String | Write-Host

    Write-Host "-- CDN Rule --"
    $cdnRule = Get-AzFrontDoorCdnRule -ResourceGroupName $resourceGroup -ProfileName $profileName -RuleSetName $ruleSetName
    $cdnRule | Format-List | Out-String | Write-Host
} catch {
    Write-Host "Azure Front Door CDN Resource Check Error: $($_.Exception.Message)"
}