#-----------------------------------------------------------------------
# Get-DnsRecord [FQDN [<String>]]
#
# Example: .\Get-DnsRecord.ps1 -FQDN "www.example.com"
#-----------------------------------------------------------------------
# ---
# --- Parameters
# ---
param
(
	[string] $FQDN=$(throw '-FQDN is a required parameter. (www.example.com)')
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
# ---
# --- Install/Import
# ---
#May need RSAT (Admin): Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Import-Module "../System.psm1"
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Install-Module -Name ActiveDirectory -Force -Confirm:$false
}

# ---
# --- Execute
# ---
try {
    $dnsRecord = [System.Net.Dns]::GetHostEntry($FQDN)
    if ($dnsRecord.AddressList) {
        $ip = $dnsRecord.AddressList[0].IPAddressToString
        Write-Output "$FQDN is a DNS A record with IP: $ip."
        
        # Check for an Active Directory object with the same name
        Import-Module ActiveDirectory
        $adObject = Get-ADComputer -Filter "DNSHostName -eq '$FQDN'"
        
        if ($adObject) {
            Write-Output "$FQDN is associated with a Windows machine."
        } else {
            Write-Output "$FQDN is likely a manual DNS A record."
        }
    }
} catch {
    Write-Output "$FQDN is not a DNS A record."
}
