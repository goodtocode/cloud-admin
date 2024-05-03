# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Temp (wherever your script is)
#   4. In powershell, run script: 
#      .\Export-SelfSignedCert -Path .\dev.myorg.com.pfx -Password MyPass1234 -Dns dev.myorg.com

param (
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
 	[string]$Path = $(throw '-Path is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$Password = $(throw '-Password is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[string]$Dns = $(throw '-Dns is a required parameter.'),
	[string]$CertStoreLocation = 'cert:\LocalMachine\My'
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
$foundCert = Get-ChildItem -Path $CertStoreLocation | Where-Object Subject -eq "CN=$Dns" | Select-Object *
if($foundCert.Thumbprint.Length -gt 0)
{    
    ## Found
    $thumbprint=$foundCert.Thumbprint
    Write-host "Found cert with thumbprint $thumbprint"
    ## Export
    $securePw = ConvertTo-SecureString -String $Password -Force –AsPlainText
    Export-PfxCertificate -Cert "$CertStoreLocation\$thumbprint" -FilePath $Path -Password $securePw
}