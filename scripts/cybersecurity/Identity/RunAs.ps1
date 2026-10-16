$Credential = Get-Credential -Message "Enter the account to run as"
$PSCommand = ""
Start-Process powershell.exe -Credential $Credential -ArgumentList "-NoExit", "-Command $PSCommand"