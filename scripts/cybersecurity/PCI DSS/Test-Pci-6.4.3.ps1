#-----------------------------------------------------------------------
# Test-Pci-6.4.3 [TargetUrl [<String>]]
#
# Example: .\Test-Pci-6.4.3.ps1 -TargetUrl "www.example.com"
#-----------------------------------------------------------------------
# ---
# --- Parameters
# ---
param (
    [string]$TargetUrl
)

# ---
# --- Initialize
# ---
if ($IsWindows) { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
$VerbosePreference = 'SilentlyContinue' #'Continue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
[DateTime]$Now = Get-Date
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths
Write-Host "---------------------------"
Write-Host "--- Starting: $ThisScript on $Now"
Write-Host "---------------------------"

function Test-PciDss643 {
    param (
        [string]$Url
    )
    Write-host "Url to test: $Url"
    
    Add-Type -AssemblyName System.Web

    $maliciousParam = '<<<<<<foo"bar''314>>>>>=1'
    $encodedParam = [System.Web.HttpUtility]::UrlEncode($maliciousParam)
    $testUrl = "$Url" + "?" + $encodedParam

    Write-Host "Malicious URL: $testUrl"

    try {
        $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -ErrorAction Stop

        Write-Host "✅ Request succeeded."

        # Check for reflected input
        try {
            if ($response.Content -match [Regex]::Escape($maliciousParam)) {
                Write-Warning "⚠️ Potential XSS: Malicious parameter reflected in response."
            } else {
                Write-Host "✅ No reflection detected."
            }
        } catch {
            Write-Error "❌ Error checking for reflected input: $_"
        }

        # Check for error leakage
        try {
            if ($response.Content -match "Exception" -or $response.Content -match "Request.RawUrl") {
                Write-Warning "⚠️ Potential error leakage detected in response."
            } else {
                Write-Host "✅ No error leakage detected."
            }
        } catch {
            Write-Error "❌ Error checking for error leakage: $_"
        }

        # Check for CSP header
        try {
            if ($response.Headers["Content-Security-Policy"]) {
                Write-Host "✅ CSP header found: $($response.Headers["Content-Security-Policy"])"
            } else {
                Write-Warning "⚠️ Missing Content-Security-Policy header."
            }
        } catch {
            Write-Error "❌ Error checking for CSP header: $_"
        }

    } catch {
        Write-Error "❌ Request failed: $($_.Exception.Message)"
        if ($_.Exception.Response -ne $null) {
            Write-Host "`n🔍 Response Status Code: $($_.Exception.Response.StatusCode)"
            Write-Host "🔍 Response Description: $($_.Exception.Response.StatusDescription)"
        }
    }
}

Test-PciDss643 -Url $TargetUrl
