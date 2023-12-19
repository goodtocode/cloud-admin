####################################################################################
# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Temp (wherever your script is)
#   4. In powershell, run script: 
#      .\Add-RemoteDesktopUsers.ps1 -ComputerName "Computer1" -UserName "User1", "User2", "User3"
####################################################################################

param (
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
 	[string]$Feature = $(throw '-Feature is a required parameter.') #RSAT
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


function Add-RemoteDesktopUsers {
    [cmdletbinding()]
    param (
        [string[]] $UserName,
        [string] $ComputerName
    )
    ForEach ($User in $UserName) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            NET LOCALGROUP "Remote Desktop Users" "$Using:User" /ADD
        }
    }
}

Add-RemoteDesktopUsers -ComputerName "vm-micro-qa-01" -UserName "rgood@aacn.org"
