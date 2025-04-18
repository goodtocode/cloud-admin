$Username = "USER"
$UserPassword = ConvertTo-SecureString "PASSWORD" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential $Username, $UserPassword
$PSCommand = ""
Start-Process powershell.exe -Credential $Credential -ArgumentList "-NoExit", "-Command $PSCommand"