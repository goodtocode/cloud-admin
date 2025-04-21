# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Get-CertificateThumbprint -Dns dev.myorg.com

param (
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[string]$Dns = $(throw '-Dns is a required parameter.'),
	[string]$CertStoreLocation = 'cert:\LocalMachine\My'
)
####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'SilentlyContinue' # 'Continue'
if ($MyInvocation.MyCommand.Path) {
    [String]$ThisScript = $MyInvocation.MyCommand.Path
} else {
    [String]$ThisScript = (Get-Location).Path
}
[String]$ThisDir = Split-Path $ThisScript
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths

Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript On: $(Get-Date)"
Write-Host "*****************************"
####################################################################################
$foundCert = Get-ChildItem -Path $CertStoreLocation | Where-Object Subject -eq "CN=$Dns" | Select-Object -First 1
if($foundCert.Thumbprint.Length -gt 0)
{    
    ## Found
    $thumbprint=$foundCert.Thumbprint
    Write-host "Found cert matching $CertStoreLocation CN=$Dns Thumbprint=$thumbprint"
}
else {
    Write-host "No cert found matching $CertStoreLocation CN=$Dns"
}