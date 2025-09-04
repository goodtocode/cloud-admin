# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\New-FileHash -Path "C:\Path\To\Your\File.txt"

param (
	[string]$Path = "D:\source\goodtocode\semantickernel-microservice\src\Presentation.Blazor\wwwroot\lib\bootstrap\dist\js\bootstrap.js",
    [string]$Algorithm = "SHA256"
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

$hex = Get-FileHash $Path -Algorithm $Algorithm
$bytes = for ($i = 0; $i -lt $hex.Hash.Length; $i += 2) { [Convert]::ToByte($hex.Hash.Substring($i, 2), 16) }
$base64 = [Convert]::ToBase64String($bytes)
$base64
