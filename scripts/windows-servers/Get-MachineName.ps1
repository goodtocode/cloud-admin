#-----------------------------------------------------------------------
# Get-DnsRecord [FQDN [<String>]]
#
# Example: .\Get-MachineName.ps1 -FQDN "www.example.com"
#-----------------------------------------------------------------------
# ---
# --- Parameters
# ---
param
(
	[string] $IP=$(throw '-IP is a required parameter. (www.example.com)')
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
# May need RSAT (Admin): Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Import-Module "../System.psm1"
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Install-Module -Name ActiveDirectory -Force -Confirm:$false
}

# ---
# --- Execute
# ---
# Function to get the machine name from an IP address
function Get-MachineNameFromIP {
    param (
        [string] $IPAddress
    )

    try {
        $reverseLookup = [System.Net.Dns]::GetHostEntry($IPAddress)
        if ($reverseLookup.HostName) {
            Write-Output "The IP address $IPAddress is associated with the machine name: $($reverseLookup.HostName)."
        } else {
            Write-Output "No machine name is associated with the IP address $IPAddress."
        }
    } catch {
        Write-Output "Reverse DNS lookup failed for IP address $IPAddress."
    }
}

Get-MachineNameFromIP -IPAddress $ip
