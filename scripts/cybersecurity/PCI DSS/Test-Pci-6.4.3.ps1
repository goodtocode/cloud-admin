
#-----------------------------------------------------------------------
# Test-Pci-6.4.3 [TargetUrl <String>]
#
# Example: .\Test-Pci-6.4.3.ps1 -TargetUrl "https://www.example.com"
#
# This script tests PCI DSS v4.0 compliance for:
# - 6.4.3.1: Inventory of scripts
# - 6.4.3.2: Authorization of scripts (manual follow-up suggested)
# - 6.4.3.3: Integrity verification of scripts
# - 4.30: CGI Generic XSS (parameter name reflection, error leakage)
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

    # --- PCI DSS 4.30: Malicious parameter injection test ---
    $maliciousParam = '<<<<<<foo"bar''314>>>>>=1'
    $encodedParam = [System.Web.HttpUtility]::UrlEncode($maliciousParam)
    $testUrl = "$Url" + "?" + $encodedParam

    Write-Host "Malicious URL: $testUrl"

    $response = $null
    try {    
        $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -ErrorAction Stop
        Write-Host "✅ Request succeeded."
    }
    catch {
        Write-Error "❌ Request failed: $($_.Exception.Message)"
        if ($_.Exception.Response -ne $null) {
            Write-Host "`n🔍 Response Status Code: $($_.Exception.Response.StatusCode)"
            Write-Host "🔍 Response Description: $($_.Exception.Response.StatusDescription)"
        }
    }

    # --- PCI DSS 6.4.3.1: Script Inventory ---
    try {
        $scriptTags = Select-String -InputObject $response.Content -Pattern "<script[^>]*src=['""][^'""]+['""][^>]*>" -AllMatches
        $scripts = @()

        foreach ($match in $scriptTags.Matches) {
            $scriptLine = $match.Value
            $srcMatch = $scriptLine -match 'src\s*=\s*["'']([^"'']+)["'']'
            $src = if ($srcMatch) { $matches[1] } else { "❌ Not found" }

            $scripts += [PSCustomObject]@{
                ScriptSrc = $src
            }
        }

        Write-Host "`n📦 PCI DSS 6.4.3.1: Script Inventory"
        foreach ($script in $scripts) {
            Write-Host "🔹 Source: $($script.ScriptSrc)"
        }

        if ($scripts.Count -eq 0) {
            Write-Warning "⚠️ No script tags found. Manual inspection may be required."
        }
    }
    catch {
        Write-Error "❌ Error extracting script inventory: $_"
    }

    # --- PCI DSS 6.4.3.3: Integrity Verification ---
    try {
        $integrityTags = Select-String -InputObject $response.Content -Pattern "<script[^>]*src=['""][^'""]+['""][^>]*>" -AllMatches
        $integrityResults = @()

        foreach ($match in $integrityTags.Matches) {
            $scriptLine = $match.Value
            $srcMatch = $scriptLine -match 'src\s*=\s*["'']([^"'']+)["'']'
            $src = if ($srcMatch) { $matches[1] } else { "❌ Not found" }

            $integrityMatch = $scriptLine -match 'integrity\s*=\s*["'']([^"'']+)["'']'
            $integrity = if ($integrityMatch) { $matches[1] } else { "❌ Missing" }

            $integrityResults += [PSCustomObject]@{
                ScriptSrc = $src
                Integrity = $integrity
            }
        }

        Write-Host "`n🔐 PCI DSS 6.4.3.3: Integrity Verification"
        foreach ($result in $integrityResults) {
            Write-Host "🔹 Source: $($result.ScriptSrc)"
            Write-Host "🔸 Integrity: $($result.Integrity)"
        }

        if ($integrityResults.Count -eq 0) {
            Write-Warning "⚠️ No script tags found for integrity check."
        }
    }
    catch {
        Write-Error "❌ Error checking script integrity: $_"
    }

    #--- PCI DSS 4.30: Reflected Input (XSS) ---
    try {
        if ($response.Content -match [Regex]::Escape($maliciousParam)) {
            Write-Warning "⚠️ PCI DSS 4.30: Malicious parameter reflected in response (XSS risk)."
        }
        else {
            Write-Host "✅ PCI DSS 4.30: No reflected input detected."
        }

    }
    catch {
        Write-Error "❌ Error checking for reflected input: $_"
    }

    #--- PCI DSS 4.30: Error Leakage ---
    try {
        if ($response.Content -match "Exception" -or $response.Content -match "Request.RawUrl") {

            Write-Warning "⚠️ PCI DSS 4.30: Potential error leakage detected in response."
        }
        else {
            Write-Host "✅ PCI DSS 4.30: No error leakage detected."
        }
    }
    catch {
        Write-Error "❌ Error checking for error leakage: $_"
    }

    # --- PCI DSS 6.4.3.2: Script Authorization (Indirect) ---
    try {
        if ($response.Headers["Content-Security-Policy"]) {
            Write-Host "✅ PCI DSS 6.4.3.2: CSP header found — supports script authorization."
        }
        else {
            Write-Warning "⚠️ PCI DSS 6.4.3.2: Missing Content-Security-Policy header — script authorization not enforced."
        }

    }
    catch {
        Write-Error "❌ Error checking for CSP header: $_"
    }   
}

Test-PciDss643 -Url $TargetUrl
