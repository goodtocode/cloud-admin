####################################################################################
# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Add-LocalGroupMember -Member
####################################################################################

param (	
 	[string]$VerifyUrl = 'https://api.ipify.org?format=json'
)

####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'SilentlyContinue' # 'Continue'
####################################################################################

$publicIP = (Invoke-RestMethod -Uri $VerifyUrl).ip
Write-Host "Your public IP address is: $publicIP"