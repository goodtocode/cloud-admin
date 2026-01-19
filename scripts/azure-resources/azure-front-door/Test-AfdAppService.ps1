
#
# SYNOPSIS
#   Tests the Azure Front Door App Service for a specified parameter.
#
# DESCRIPTION
#   This script tests the Azure Front Door App Service by accepting a parameter to specify the target for testing. It is used to verify the configuration and connectivity of the App Service through Azure Front Door for any given input.
#
# PARAMETER <ParameterName>
#   The value to specify the target for testing (replace <ParameterName> with your actual parameter name).
#
# EXAMPLE
#   PS> .\Test-AfdAppService.ps1 -ParameterName "MyValue"
#   This will test the Azure Front Door App Service for the specified value "MyValue".
#
# NOTES
#   Author: GoodToCode
#

param(
    [string]$AfdEndpointUrl, # https://afdend-mydomain-dev-hmhasdfasdfa6h3.a03.azurefd.net
    [string]$AfdOriginUrl, # https://web-myproduct-dev-001.azurewebsites.net
    [string]$AfdSubPath, # "weather",
    [string]$AfdAssetToTest = "app.css"
)


# Test the endpoint after setup (always with subpath)
Write-Host "Testing endpoint: $AfdEndpointUrl/$AfdSubPath"
try {
    $response = Invoke-WebRequest -Uri "$AfdEndpointUrl/$AfdSubPath" -UseBasicParsing -TimeoutSec 30
    Write-Host "--- Test Result ---"
    Write-Host "Status Code: $($response.StatusCode)"
    Write-Host "Status Description: $($response.StatusDescription)"
    if ($response.Content.Length -gt 0) {
        Write-Host "Response Content (first 200 chars):"
        Write-Host ($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))
    } else {
        Write-Host "No content returned."
    }
} catch {
    Write-Host "--- Test Result ---"
    Write-Host "Request failed: $($_.Exception.Message)"
}

Write-Host "=== Testing App Service with AFD Host Header ==="
try {
    $afdHost = ([uri]$AfdEndpointUrl).Host
    $response = Invoke-WebRequest -Uri "https://$AfdOriginUrl/$AfdSubPath" -Headers @{ "Host" = $afdHost } -UseBasicParsing
    Write-Host "App Service with AFD Host Header Status: $($response.StatusCode)"
} catch {
    Write-Host "App Service with AFD Host Header Error: $($_.Exception.Message) Inner: $($_.Exception.InnerException.Message)"
}

Write-Host "=== Testing Front Door Endpoint (with subpath) ==="
try {
    $afdResponseRoot = Invoke-WebRequest -Uri "$AfdEndpointUrl/$AfdSubPath" -UseBasicParsing
    Write-Host "SubPath Status: $($afdResponseRoot.StatusCode)"
} catch {
    Write-Host "SubPath Error: $($_.Exception.Message)"
}

Write-Host "=== Testing Origin Health Probe (HEAD /) ==="
try {
    $originProbe = Invoke-WebRequest -Uri "https://$AfdOriginUrl/" -Method Head -UseBasicParsing
    Write-Host "Origin HEAD Status: $($originProbe.StatusCode)"
} catch {
    Write-Host "Origin HEAD Error: $($_.Exception.Message)"
}

Write-Host "=== Testing Origin GET ==="
try {
    $originGet = Invoke-WebRequest -Uri "https://$AfdOriginUrl/" -UseBasicParsing
    Write-Host "Origin GET Status: $($originGet.StatusCode)"
} catch {
    Write-Host "Origin GET Error: $($_.Exception.Message)"
}

Write-Host "=== Checking SSL Certificate ==="
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient($AfdOriginUrl, 443)
    $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({ $true }))
    $sslStream.AuthenticateAsClient($AfdOriginUrl)
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

# --- Custom Rewrite/Asset Path Tests (all path-based) ---
$afdTests = @(
    @{ Name = "App Root"; Url = "$AfdEndpointUrl/$AfdSubPath"; ExpectSuccess = $true },
    @{ Name = "Asset in Subpath"; Url = "$AfdEndpointUrl/$AfdSubPath/$AfdAssetToTest"; ExpectSuccess = $true },
    @{ Name = "Asset at Root (should fail)"; Url = "$AfdEndpointUrl/$AfdAssetToTest"; ExpectSuccess = $false }
)

Write-Host "--- Azure Front Door Rewrite/Asset Path Tests (Path-Based) ---" -ForegroundColor Cyan
foreach ($test in $afdTests) {
    Write-Host "Testing $($test.Name): $($test.Url)" -NoNewline
    try {
        $resp = Invoke-WebRequest -Uri $test.Url -Method GET -UseBasicParsing -ErrorAction Stop
        if ($test.ExpectSuccess -and $resp.StatusCode -eq 200) {
            Write-Host " [PASS]" -ForegroundColor Green
        } elseif (-not $test.ExpectSuccess -and $resp.StatusCode -eq 404) {
            Write-Host " [PASS] (404 as expected)" -ForegroundColor Green
        } else {
            Write-Host " [UNEXPECTED STATUS: $($resp.StatusCode)]" -ForegroundColor Yellow
        }
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if (-not $test.ExpectSuccess -and $status -eq 404) {
            Write-Host " [PASS] (404 as expected)" -ForegroundColor Green
        } else {
            Write-Host " [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "--- Test Complete ---" -ForegroundColor Cyan