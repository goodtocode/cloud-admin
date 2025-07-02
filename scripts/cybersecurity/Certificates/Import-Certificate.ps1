# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Import-Certificate -Path .\dev.myorg.com.pfx -Password MyPass1234

param (
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
 	[string]$Path = $(throw '-Path is a required parameter.'),
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$Password = $(throw '-Password is a required parameter.'),
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
$mypwd = ConvertTo-SecureString -String $Password -AsPlainText -Force
Import-PfxCertificate -FilePath $Path -CertStoreLocation $CertStoreLocation -Password $mypwd