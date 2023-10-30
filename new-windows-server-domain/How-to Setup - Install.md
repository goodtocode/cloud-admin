Bare Metal System (Older Dell)
- Boot Usb with Windows Server 2012 R2
- Install Windows Server 2012 R2 Datacenter - With GUI (Desktop Experience)
- Change computer name - Reboot
- Team Adapters
- Install Hyper-V
- Enable RDC

**************
1. Install without desktop experience
**************
* Note, 2016 does not work on older hardware. Hangs at spinny
- Boot from USB (bare metal) or mount ISO and boot (VM)
- Use Setup.exe GUI

**************
2. Set Admin Password
**************
- Console forces Administrator password at logon time
- Command Prompt (cmd.exe) is shown after password change
- Enter/type for PS: powershell

**************
(Optional) Enter/Change Product Key + Activate Windows
**************
- If cmd.exe: slmgr -ipk XXXX-XXXX-XXXX-XXXX
> (Get-WmiObject -query -select * from SoftwareLicensingService-).OA3xOriginalProductKey
> $computer = gc env:computername
> $key = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
> $service = get-wmiObject -query "select * from SoftwareLicensingService" -computername $computer
> $service.InstallProductKey($key)
> $service.RefreshLicenseStatus()

**************
4, 5, 6, 7. Basic configuration in 1 step
**************
- sconfig.cmd

**************
6. Change Computer Name
**************
> Get-WmiObject Win32_ComputerSystem;
> Rename-Computer "Cloud-Dc-02"; 

**************
6. Set IP Address + Subnet
**************
> Get-NetAdapter
> New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.112 -DefaultGateway 192.168.1.254 -PrefixLength 24 -AddressFamily IPv4

**************
7. Set DNS Server to AD DNS
**************
> Get-DNSServer
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.112, 192.168.1.111

**************
8. For new computer name to take effect
**************
> Restart-Computer;

**************
9. Timezone
**************
> Get-Timezone
> Set-Timezone -ID "Pacific Standard Time"

**************
8a. (Optional) FIRST Setup: Forest + Domain Controller
**************
> Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
> Install-ADDSForest -DomainName test.TestDomain.org -DomainNetBIOSName TEST
> Add-DnsServerForwarder
Verify
> Get-ADDomain
> Get-DNSServer
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.0.0.1, 192.168.1.111;
> Restart-Computer;


**************
8a. (Optional) SECOND Setup: Domain
**************
> Install-ADDSDomain

**************
8b. (Optional) Create Additional Domain Controller
**************
> Get-ADDomain
> Get-DNSServer
> Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.0.0.1, 192.168.1.111;
> Restart-Computer;
> Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
> Install-ADDSDomainController -Credential (Get-Credential prod\Administrator) -DomainName "prod.goodtocode.com"

> Add-DnsServerForwarder
-- First check if DNS IN is enabled in firewall for root hints to work

**************
8b. Join Domain
**************
> Get-ADDomain
> Add-Computer -DomainName prod.goodtocode.com -Credential prod\Administrator -Restart

**************
(Optional) Create New AD User
**************
> New-ADUSer -Name "Robert J. Good" -GivenName "Robert" -Surname "Good" -SAMAccountName "rjgood" -UserPrincipalName "robert.good@goodtocode.com" -AccountPassword (Read-Host -AsSecureString "PASSWORD_HERE") -PassThru | Enable-ADAccount
> Add-ADGroupMember -Identity "Domain Admins" -Members rjgood;

**************
(Optional) Verify Active Directory
**************
> DCDiag
> Get-Service adws,kdc,netlogon,dns
> Get-SmbShare
> Get-EventLog "Directory Service" | Select entrytype, source, eventid, message
> Get-EventLog "Active Directory Web Services" | Select entrytype, source, eventid, message

**************
(Optional) Update windows
**************
> Install-Package
> Import-Module PSWindowsUpdate
> Get-WUInstall -MicrosoftUpdate -ListOnly 
Import-Module PSWindowsUpdate; Get-WindowsUpdate; Install-WindowsUpdate;

**************
(Optional) Add local administrators
**************
> Add-LocalGroupMember -Group "Administrators" -Member "AzureAD\\'group name with spaces'"

**************
(Optional) Install winget
**************
Add-AppxPackage -Path "C:\Program Files\WindowsApps\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Add-AppxPackage -Path "C:\path\to\winget.msixbundle" -LicensePath "C:\path\to\winget-cli-license.xml"
Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile "C:\path\to\winget.msixbundle"

**************
Share folder
**************
Install-SmbShare -Name MyShare -Path X:\ -FullAccess 'Everybody' `
  -Description 'My super-awesome file share!'
Grant-Permission -Identity Everyone -Permission FullControl -Path X:\

**************
Installer Options (i.e. build tools)
**************
- vs_installershell.exe /finalizeinstall [command [options]]
- Commands: install, modify, update, repair, resume, uninstall
vs_buildtools__1198963523.1528481771.exe /finalizeInstall uninstall

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
Get-EventLog "DNS" | Select entrytype, source, eventid, message