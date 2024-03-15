**************
SQL Server Install
https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-on-server-core?view=sql-server-2017
/FEATURES=SQLEngine,Replication,FULLTEXT
For mixed mode: /SECURITYMODE=SQL /SAPWD="PASSWORD_HERE"
**************
- In hyper-v, click the VM and Settings: Assign CDROM to SQL Server .ISO file.
d:\Setup.exe /qs /SQLSYSADMINACCOUNTS="prod\Administrator" /ACTION=Install /FEATURES=SQLEngine /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="NT Service\MSSQLSERVER" /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /TCPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS

**************
SQL Server Remote Access
**************
"c:\program files\microsoft sql server\client sdk\odbc\130\tools\binn\SQLCMD.exe"
EXEC sys.sp_configure N'remote access', N'1'; GO;
RECONFIGURE WITH OVERRIDE; GO;
exit
Restart-Service -Name MSSQLSERVER -Force;

**************
SQL Server User
**************
"c:\program files\microsoft sql server\client sdk\odbc\130\tools\binn\SQLCMD.exe" -S localhost
EXEC sp_addsrvrolemember 'prod\domain admins', 'sysadmin'; GO
exit
Restart-Service -Name MSSQLSERVER -Force;

**************
Firewall Rules
-Profile @('Public', 'Domain', 'Private')
**************
Get-NetFirewallRule -DisplayName '*SQL*' | Select Name, DisplayName, Profile, Action, Enabled
Get-NetFirewallRule -DisplayName '*SQL*' | Get-NetFirewallPortFilter
New-NetFirewallRule -DisplayName 'SQL Server Engine' -Profile @('Public', 'Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('1433')
Enable-NetFirewallRule -DisplayName 'SQL Server Engine'
#Remove-NetFirewallRule -DisplayName 'SQL Server Engine'

**************
Setup DNS forward lookup Records
**************
# New Forward Lookup A Records
# On domain controller/dns server
Get-DnsServer
Add-DnsServerResourceRecordA -Name 'DatabaseServer' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.22;

**************
AD User for Code->DB Access
**************
# On AD Server
$User = 'CodeServiceUser'; `
$Password = 'PASSWORD_HERE'; `
New-ADUSer -Name "SQL User $User" -GivenName "Code" -Surname "User" -SAMAccountName "$User" -UserPrincipalName "$User@goodtocode.com" -AccountPassword (Read-Host -AsSecureString "$Password") -PassThru | Enable-ADAccount;

**************
Share Backup folder
# ACL Rights: Delete, FullControl, Modify, Read, ReadAndExecute, Write
**************
$User = "prod\domain admins"; `
$Path = "c:\Backup"; `
$ShareName = "Backup"; `
md $Path; `
$Acl = Get-Acl $Path; `
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"); `
$Acl.SetAccessRule($Ar); `
Set-Acl $Path $Acl; `
New-SmbShare -Name $ShareName -Path $Path -Description $ShareName; `
Grant-SmbShareAccess -Name $ShareName -AccountName $User -AccessRight Full;

**************
 SSMS as different user
**************
SHIFT + Right-Click SSMS icon -> Run as Different User
SSMS -> Security -> New Logon -> Domain Admins as sysadmin

**************
SQL Server MSSQLSERVER
**************
Get-Service | Select name, status
Get-Service -Name MSSQLSERVER
Set-Service -Name MSSQLSERVER -StartupType Automatic
Restart-Service -Name MSSQLSERVER -Force;

**************
(Optional) Change to mixed authentication mode
**************
regedit 
Navigate to the registry location: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.SQLEXPRESS\MSSQLServer, where MSSQL12.SQLEXPRESS is the name of your SQL Server instance. 
In the right panel, change the LoginMode from 1 to 2. 1 = Windows authentication Only. 2 = Mixed mode.

**************
(Optional) SQL Server Agent Service
**************
Get-Service -Name SQLSERVERAGENT 
- in CMD.EXE
sc config SQLSERVERAGENT start= auto
net start SQLSERVERAGENT

**************
(Optional) SQL Server Browser
**************
Get-Service -Name SQLBROWSER
# Not needed if port 1433 and default instance. Won't allow IP connections.
> sc config SQLBROWSER start= auto
> net start SQLBROWSER
Restart-Service -Name SQLBrowser -Force;

**************
(optional) SQL User with access only to 1 database
**************
create LOGIN TestUser WITH PASSWORD='57595709-9E9C-47EA-ABBF-4F3BAA1B0D37', CHECK_POLICY = OFF;
USE master;
GO
DENY VIEW ANY DATABASE TO TestUser;
USE master;
GO
create LOGIN PSCode WITH PASSWORD='3BDA23C9-337A-4139-999A-9395CBEA971E', CHECK_POLICY = OFF;
Go
USE master;
GO
create LOGIN PSAdmin WITH PASSWORD='EC391D2B-E9FA-48B5-B129-259CBB6649EC', CHECK_POLICY = OFF;
Go
USE master;
GO
create LOGIN GSAdmin WITH PASSWORD='570EB68C-51B6-4B43-B5E7-0C2B0FC53BC1', CHECK_POLICY = OFF;
Go

**************
TIPS
**************
Get-Service | Select name, status
Get-NetFirewallRule -DisplayName '*SQL*' | Select Name, DisplayName, Profile, Action, Enabled
