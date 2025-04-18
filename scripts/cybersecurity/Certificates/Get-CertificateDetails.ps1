####################################################################################
# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Get-CertificateDetails.ps1 
####################################################################################

param (
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
 	[string]$PathFile = $(throw '-Path is a required parameter.'), #.\Certs\MyCert.pfx
    [securestring]$Password = $(throw '-Password is a required parameter.')
)

####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'SilentlyContinue' # 'Continue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths
Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript On: $(Get-Date)"
Write-Host "*****************************"
####################################################################################
# Imports
Import-Module "../../System.psm1"

(Get-PfxData -FilePath $PathFile -Password $Password).EndEntityCertificates | Format-List *