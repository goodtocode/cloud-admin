**************
 FIRST Setup: Forest + Domain Controller
**************
> Get-ADDomain
> Get-DNSServer
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.111,192.168.1.112;
> Restart-Computer;
> Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
> Install-ADDSForest -DomainName prod.goodtocode.com -DomainNetBIOSName PROD
> Add-DnsServerForwarder

**************
 SECOND Setup: Domain
**************
> Install-ADDSDomain

**************
 Create Additional Domain Controller
**************
> Get-ADDomain
> Get-DNSServer
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.111,192.168.1.112;
> Restart-Computer;
> Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
> Install-ADDSDomainController -Credential (Get-Credential prod\Administrator) -DomainName "prod.goodtocode.com"

> Add-DnsServerForwarder
-- First check if DNS IN is enabled in firewall for root hints to work

**************
 Join Domain
**************
> Get-ADDomain
> Add-Computer -DomainName prod.goodtocode.com -Credential prod\Administrator -Restart

**************
 Create New AD Group
**************
New-ADGroup -Name "GoodToCode Agents" -SamAccountName GoodToCodeAgents `
 -DisplayName "GoodToCode Agents" -Path "CN=Users,DC=Dev,DC=GoodToCode,DC=Com" `
 -Description "GoodToCode Build/Backup Agents" `
 -GroupCategory Security -GroupScope Global

New-ADUSer -Name "GoodToCode Build Agent" -GivenName "GoodToCodeBuild" -Surname "Agent" `
 -SAMAccountName "GoodToCodeBuildAgent" -UserPrincipalName "buildagent@goodtocode.com" `
 -AccountPassword (Read-Host -AsSecureString "PASSWORD_HERE") -PassThru | Enable-ADAccount; `
Add-ADGroupMember -Identity "GoodToCodeAgents" -Members GoodToCodeBuildAgent; `

New-ADUSer -Name "GoodToCode Backup Agent" -GivenName "GoodToCodeBackup" -Surname "Agent" `
 -SAMAccountName "GoodToCodeBackupAgent" -UserPrincipalName "backupagent@goodtocode.com" `
 -AccountPassword (Read-Host -AsSecureString "PASSWORD_HERE") -PassThru | Enable-ADAccount; `
Add-ADGroupMember -Identity "GoodToCodeAgents" -Members GoodToCodeBackupAgent; `

**************
 Create New AD User
**************
New-ADUSer -Name "Robert J. Good" -GivenName "Robert" -Surname "Good" -SAMAccountName "rjgood" `
 -UserPrincipalName "robert.good@goodtocode.com" '
 -AccountPassword (Read-Host -AsSecureString "ENTER_PASSWORD_HERE") -PassThru | Enable-ADAccount; '
Add-ADGroupMember -Identity "Domain Admins" -Members rjgood;

**************
 Create gMSA User (Group Managed Service Account)
**************
# Create a new KDS Root Key that will be used by DC to generate managed passwords
Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)
# Create a new GMSA
New-ADServiceAccount -Name 'TFSService' -DNSHostName 'dev.goodtocode.com'
#
# Get gMSA password
#
# Allow a user to access password
Set-ADServiceAccount -Identity 'TFSService' -PrincipalsAllowedToRetrieveManagedPassword 'rgood'
# We have to explicitly ask for the value of the msDS-ManagedPassword attribute. Even a wildcard (*) would not work.
Get-ADServiceAccount -Identity 'TFSService' -Properties 'msDS-ManagedPassword'
# Save the blob to a variable; `
$gmsa = Get-ADServiceAccount -Identity 'TFSService' -Properties 'msDS-ManagedPassword'; `
$mp = $gmsa.'msDS-ManagedPassword'; `
# Decode the data structure using the DSInternals module; `
ConvertFrom-ADManagedPasswordBlob $mp; 

**************
 Change Service user
**************
Get-Service -name '*AD*'
$service = gwmi win32_service -computer [computername] -filter "name='*VSTS*'"
$service.change($null,$null,$null,$null,$null,$null,"prod\rjgood","P@ssw0rd")


**************
 Verify Active Directory
**************
> DCDiag
> Get-Service adws,kdc,netlogon,dns
> Get-EventLog "Directory Service" | Select entrytype, source, eventid, message
> Get-EventLog "Active Directory Web Services" | Select entrytype, source, eventid, message

**************
 Folder Permissions
 # ACL Rights: Delete, FullControl, Modify, Read, ReadAndExecute, Write
**************
$User = "dev\Domain Admins"; `
$ShareName = "Sites"; `
$Path = "c:\Sites"; `
$Access = 'FullControl'; `
md $Path; `
$Acl = Get-Acl $Path; `
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "$Access", "ContainerInherit,ObjectInherit", "None", "Allow"); `
$Acl.SetAccessRule($Ar); `
Set-Acl $Path $Acl; `
New-SmbShare -Name $ShareName -Path $Path -Description $ShareName; `

**************
 Folder Share
**************
$User = "dev\GoodToCodeAgents"; `
$ShareName = "Sites"; `
Grant-SmbShareAccess -Name $ShareName -AccountName $User -AccessRight Full;

**************
 Folder Delete
**************
Remove-Item -Path FOLDER -Recurse -Force

**************
 Take Ownership when don't have credentials
**************
* HDDs
takeown /F x:\ /R
CACLS x:\ /G Administrator:F
* apply patch ps1 (RDC error)
https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2018-0886

**************
 AD Trust broken for DC
**************
Invoke-Command dev-dc-02 {Test-ComputerSecureChannel}
Reset-ComputerMachinePassword -Server "Dev-Dc-02" -Credential dev\administrator

**************
Windows Services
**************
Get-Service | Select name, status
Set-Service -Name BITS -StartupType Automatic
Set-Service -Name DNS -StartupType Automatic
Start-Service -Name DNS 
dcdiag /test:dns

**************
(Optional) Update windows
**************
# only v5+ has windows update
$PSVersionTable.PSVersion
Set-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2/ -InstallationPolicy Trusted; `
Install-Module PSWindowsUpdate; `
Get-Command -module PSWindowsUpdate; `
Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d; `
Get-WUInstall -MicrosoftUpdate -AcceptAll -AutoReboot

# Other
# Get-WUInstall -MicrosoftUpdate -ListOnly 
# Import-Module PSWindowsUpdate; `
# Get-WindowsUpdate; Install-WindowsUpdate; 

**************
Firewall Rules
**************
Test-NetConnection -Informationlevel Detailed -ComputerName microsoft.com -port 80
- already open with server manager
> Get-NetFirewallRule | Select Profile, Direction, Action, DisplayName
> Get-NetFirewallRule | Where { $_.Enabled -eq 'True' } | Select Profile, Direction, Action, DisplayName
> Get-NetFirewallRule | Where { $_.Description -like '*HTTPs*' } | Select Profile, Direction, Action, DisplayName 
> Get-NetFirewallRule | Where { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' -and $_.Description -like '*COM*' } | Select Profile, Direction, Action, DisplayName 
> Get-NetFirewallProfile -Name Public | Get-NetFirewallRule
> Enable-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)"

**************
Setup NPM To synchronize the domain controller with an external time source
**************
# 1. 
w32tm /config /manualpeerlist:time-a-b.nist.gov,time-b-b.nist.gov,time-c-b.nist.gov /syncfromflags:MANUAL
 w32tm /config /update
 w32tm /resync
# 2.  Hyper-V -> Settings -> Integration Settings -> Turn off Time Sync
w32tm /config /manualpeerlist:pool.ntp.org,time-a-b.nist.gov /syncfromflags:MANUAL
Stop-Service w32time
Start-Service w32time

**************
Scheduled Tasks
**************
Get-ScheduledTask | Get-ScheduledTaskInfo | Select TaskName,TaskPath,LastRunTime,LastTaskResult


**************
 TIPS
**************
Get-DNSServer
Get-DnsServerDiagnostics
Get-DnsServerForwarder
Get-DnsServerRootHint
Get-DnsServerSetting
Get-DnsServerStatistics
Get-DnsServerZone
Get-DnsServerZoneScope
Get-EventLog "DNS" | Select entrytype, source, eventid, message, timegenerated | Format-List