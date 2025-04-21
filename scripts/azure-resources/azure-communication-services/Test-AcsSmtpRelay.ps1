####################################################################################
# To execute
#   1. Run Powershell as Administrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Test-AcsSmtpRelay.ps1 
####################################################################################
param (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$UserClientId = $(throw '-UserClientId is a required parameter.'), #For User-assigned Identity: "<ACS Resource Name>|<Client ID>|<Tenant ID>"
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$PasswordSecret = $(throw '-PasswordSecret is a required parameter.'),
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$From = $(throw '-From is a required parameter.'),
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$To = $(throw '-To is a required parameter.'),
    [string]$SmtpServer = "smtp.azurecomm.net",
    [int]$SmtpPort = 587,
    [string]$Subject = "Test Email from ACS",
    [string]$Body = "This is a test email sent via Azure Communication Services."
)

####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue' # 'SilentlyContinue' # 'Continue'

# Check if the script is being run in a saved file or not
if ($MyInvocation.MyCommand.Path) {
    [String]$ThisScript = $MyInvocation.MyCommand.Path
} else {
    # Fallback for unsaved scripts in the debugger
    [String]$ThisScript = (Get-Location).Path
}

[String]$ThisDir = Split-Path $ThisScript
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths

Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript On: $(Get-Date)"
Write-Host "*****************************"
####################################################################################
# Imports
#Import-Module "../../System.psm1"

# Execute
$smtpClient = New-Object System.Net.Mail.SmtpClient($SmtpServer, $SmtpPort)
$smtpClient.EnableSsl = $true
$smtpClient.Credentials = New-Object System.Net.NetworkCredential($UserClientId, $PasswordSecret)

$mailMessage = New-Object System.Net.Mail.MailMessage($From, $To, $Subject, $Body)
$smtpClient.Send($mailMessage)

Write-Host "Test email sent successfully!"