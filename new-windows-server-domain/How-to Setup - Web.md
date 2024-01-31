**************
Install-WindowsFeature
**************
> Install-WindowsFeature Web-Server

***********
IIS: Management console
***********
Install-WindowsFeature -Name Web-Mgmt-Console
c:\windows\system32\inetsrv\inetmgr.exe

**************
Remove WebDAV Publishing - it blocks PUT and DELETE
**************
Uninstall-WindowsFeature -Name Web-DAV-Publishing

**************
Install-WindowsFeature Web-Mgmt-Service
**************
> Install-WindowsFeature Web-Mgmt-Service
- regedit 
 - HK_Local_Machine\SOFTWARE\Microsoft\WebManagement\Server
 - EnableRemoteManagement -> 1 (decimal)

Get-Service | Select-Object Name, Status, StartType
Start-Service -Name "WMSVC"
Set-Service -Name "WMSVC" -StartupType Automatic

# Add Anonymous authentication
Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.webServer/security/authentication/anonymousAuthentication' -Name 'enabled' -Value 'True'
Restart-Service -Name 'W3SVC' -Force
# Get anonymous authentication value for website
Get-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name "value" -PSPath 'IIS:\Sites\YourWebsiteName' | Select-Object value
# Set For website
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name 'enabled' -Value $true -PSPath 'IIS:\Sites\YourWebsiteName'
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/YourWebsiteName' -filter "system.webServer/security/authentication/anonymousAuthentication" -name "enabled" -value "True"
# Set For subfolder
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/YourWebsiteName' -filter "system.webServer/security/authentication/anonymousAuthentication" -name "enabled" -value "True" -Location "Subfolder"


iisreset

# Get running windows services
Get-Service | Where-Object {$_.Status -eq 'Running'}



**************
Disable Firewall
**************
Set-NetFirewallProfile -Enabled False
Set-NetFirewallProfile -Profile Domain -Enabled False
# Check status of firewall enabled/disabled
Get-NetFirewallProfile | Format-Table Name, Enabled

**************
Firewall Rules
**************
- already open with server manager
> Get-NetFirewallRule | Select-Object Name, DisplayName, Profile, Action, Enabled
> Enable-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)"
> Enable-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In)"
> Enable-NetFirewallRule -DisplayName "World Wide Web Services (HTTPS Traffic-In)"
> Set-NetFirewallRule -Name RemoteEventLongSvc-In-Tcp -Profile Private, Domain
 - Remote management: 8172
Set-NetFirewallRule -Name RemoteEventLongSvc-In-Tcp -Profile Private <commands>
# Service Fabric
Get-NetFirewallRule -DisplayName '*Service Fabric*' | Select Name, DisplayName, Profile, Action, Enabled
Get-NetFirewallRule -DisplayName '*Service Fabric*' | Get-NetFirewallPortFilter
New-NetFirewallRule -DisplayName 'Service Fabric' -Profile @('Public', 'Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('1433')
Enable-NetFirewallRule -DisplayName 'SQL Server Engine'
#Remove-NetFirewallRule -DisplayName 'SQL Server Engine'

**************
View sites and app pools
**************
# Test default site
Test-NetConnection -ComputerName localhost -Port 80
Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing | select-object -expand content 
Invoke-WebRequest -Uri "http://IP_ADDRESS" -UseBasicParsing
# Get IIS Info
Get-IISAppPool
Get-Website
Get-WebApplication
Get-WebBinding
Get-WebVirtualDirectory -Site "Default Web Site" -Application "TestApp"
# Remove default site
Remove-IISSite -Name "MyWebsite"
Remove-WebAppPool -Name "MyAppPool"

# Test Microservice
> $uri = 'https://microservices.domain.com/VirtualDir/Endpoint?key=ad790f32-f501-4838-8e4a-c1b057c44f30&api-version=1.0.0'
> $token = 'BEARER-TOKEN-HERE'
> $headers = @{
>     'accept' = 'text/plain'
>     'Authorization' = "Bearer $token"
> }
> Invoke-RestMethod -Uri $uri -Headers $headers -Method Get


**************
Start sites and app pools
**************
# Using Start-IISSite
Start-IISSite -Name "Default Web Site"
# Using Start-Website
Start-Website -Name "Default Web Site"

**************
Environment variables
**************
# Set ASPNETCORE_ENVIRONMENT
setx ASPNETCORE_ENVIRONMENT Development /M
$Env:ASPNETCORE_ENVIRONMENT = "Development"
Set-Item -Path Env:ASPNETCORE_ENVIRONMENT -Value "Development"
Get-Childitem env:
# Get 


**************
Share Sites folder
# ACL Rights: Delete, FullControl, Modify, Read, ReadAndExecute, Write
**************
$User = "dev\Domain Admins"; `
$Path = "c:\Sites"; `
$ShareName = "Sites"; `
md $Path; `
$Acl = Get-Acl $Path; `
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"); `
$Acl.SetAccessRule($Ar); `
Set-Acl $Path $Acl; `
New-SmbShare -Name $ShareName -Path $Path -Description $ShareName; `
Grant-SmbShareAccess -Name $ShareName -AccountName $User -AccessRight Full; 

**************
Bind IP Addresses to NIC
**************
Get-NetIpConfiguration | Select-Object interfaceindex, interfacealias, Ipv4address
Get-NetIPInterface
netsh interface ipv4 show interfaces
netsh interface ipv4 add address 5 192.168.1.50 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.51 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.52 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.53 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.54 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.55 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.56 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.57 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.58 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.59 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.60 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.61 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.62 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.63 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.64 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.65 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.66 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.67 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.68 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.69 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.70 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.71 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.72 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.73 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.74 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.75 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.76 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.77 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.78 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.79 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.80 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.81 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.82 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.83 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.84 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.85 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.86 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.87 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.88 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.89 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.90 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.91 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.92 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.93 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.94 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.95 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.96 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.97 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.98 255.255.255.0; `
netsh interface ipv4 add address 5 192.168.1.99 255.255.255.0; `

**************
Web Site (App pool, Site, Port 80 + Header, Port 80 + IP Address)
**************
c:\Windows\System32\inetsrv\inetmgr.exe
> Get-WebSite
> Get-WebConfiguration -filter '/system.applicationHost/sites/site/*'
> Get-WebConfiguration -filter '/system.applicationHost/sites/site/[@name='cart.goodtocode.com']/*' 
# www.goodtocode.com ; `
$SiteName = "www.goodtocode.com"; $IPAddress = "192.168.1.50"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# cart.goodtocode.com ; `
$SiteName = "cart.goodtocode.com"; $IPAddress = "192.168.1.51"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# cloud.goodtocode.com ; `
$SiteName = "cloud.goodtocode.com"; $IPAddress = "192.168.1.52"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# docs.goodtocode.com ; `
$SiteName = "docs.goodtocode.com"; $IPAddress = "192.168.1.53"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# help.goodtocode.com ; `
$SiteName = "help.goodtocode.com"; $IPAddress = "192.168.1.54"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# nuget.goodtocode.com ; `
$SiteName = "nuget.goodtocode.com"; $IPAddress = "192.168.1.55"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# sampler.goodtocode.com ; `
$SiteName = "sampler.goodtocode.com"; $IPAddress = "192.168.1.56"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# test.goodtocode.com ; `
$SiteName = "test.goodtocode.com"; $IPAddress = "192.168.1.57"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# www.CloudDevEnvironment.com ; `
$SiteName = "www.CloudDevEnvironment.com"; $IPAddress = "192.168.1.60"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `
# www.BalanceSupplies.com ; `
$SiteName = "www.BalanceSupplies.com"; $IPAddress = "192.168.1.191"; $SiteFolder = "C:\Sites\$SiteName"; `
md -force $SiteFolder; New-WebAppPool $SiteName; Start-WebAppPool $SiteName; New-WebSite -Name $SiteName -PhysicalPath $SiteFolder -ApplicationPool $SiteName -Port 80 -HostHeader $SiteName -Force; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$SiteName"},@{protocol="http";bindingInformation="*:80:$IPAddress"}); Start-WebSite $SiteName; `

**************
 Create New AD User
**************
New-ADUSer -Name "CodeServiceUser" -GivenName "CodeService" -Surname "User" -SAMAccountName "CodeServiceUser" `
 -UserPrincipalName "CodeServiceUser@goodtocode.com" `
 -AccountPassword (Read-Host -AsSecureString "PASSWORD_HERE") -PassThru | Enable-ADAccount; `
#Add-ADGroupMember -Identity "Domain Admins" -Members CodeServiceUser;

**************
App Pool Identity
**************
$Site = 'sampler.goodtocode.com'; `
$User = 'dev\CodeServiceUser'; `
$Password = 'PASSWORD_HERE'; `
Set-ItemProperty "IIS:\AppPools\$Site" -name processModel -value @{userName="$User";password="$Password";identitytype=3};

**************
(Optional) Web Site Host Header binding - Remove
**************
Remove-IISSiteBinding -Name "dev.goodtocode.com" -BindingInformation "*:30001:" -Protocol "http"

**************
(Optional) Web Site Host Header binding
**************
> Get-WebSite
> Get-WebConfiguration -filter '/system.applicationHost/sites/site/*'
$SiteName = "www.goodtocode.com"; $BindingUrl = "dev.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "cloud.goodtocode.com"; $BindingUrl = "cloud.dev.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "docs.goodtocode.com"; $BindingUrl = "docs.dev.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "help.goodtocode.com"; $BindingUrl = "help.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "nuget.goodtocode.com"; $BindingUrl = "nuget.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "sampler.goodtocode.com"; $BindingUrl = "sampler.dev.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "cart.goodtocode.com"; $BindingUrl = "cart.dev.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "cart.goodtocode.com"; $BindingUrl = "dev.GoodToCodeStack.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "cart.goodtocode.com"; $BindingUrl = "dev.GoodToCodeFramework.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "cart.goodtocode.com"; $BindingUrl = "dev.GoodToCodeEntities.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "cart.goodtocode.com"; $BindingUrl = "dev.GoodToCodeAppKit.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "cart.goodtocode.com"; $BindingUrl = "cart.dev.goodtocode.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"});
$SiteName = "www.CloudDevEnvironment.com"; $BindingUrl = dev.CloudDevEnvironment.com"; Set-WebConfiguration -filter "/system.applicationHost/sites/site[@name='$SiteName']/bindings" -PSPath IIS:\ -value (@{protocol="http";bindingInformation="*:80:$BindingUrl"}); `

**************
(Optional) Remove Web Site and App Pool
**************
$SiteName = "www.goodtocode.com";Remove-Website $SiteName;Remove-WebAppPool $SiteName;

**************
Setup DNS forward lookup Zones
**************
Get-DNSServerZone
Add-DnsServerPrimaryZone -Name "goodtocode.com" -ReplicationScope "Forest" -PassThru
Add-DnsServerPrimaryZone -Name "goodtocodestack.com" -ReplicationScope "Forest" -PassThru;
Add-DnsServerPrimaryZone -Name "goodtocodeframework.com" -ReplicationScope "Forest" -PassThru;
Add-DnsServerPrimaryZone -Name "goodtocodeentities.com" -ReplicationScope "Forest" -PassThru;
Add-DnsServerPrimaryZone -Name "goodtocodeappkit.com" -ReplicationScope "Forest" -PassThru;
Add-DnsServerPrimaryZone -Name "clouddevenvironment.com" -ReplicationScope "Forest" -PassThru;
Add-DnsServerPrimaryZone -Name "balancesupplies.com" -ReplicationScope "Forest" -PassThru

**************
Setup DNS forward lookup Records
**************
# New Forward Lookup A Records
Get-DnsServer
***
************** prod **************
***
# goodtocode.com
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.150; `
Add-DnsServerResourceRecordA -Name 'cart' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.151; `
Add-DnsServerResourceRecordA -Name 'cloud' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.152; `
Add-DnsServerResourceRecordA -Name 'api' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.152; `
Add-DnsServerResourceRecordA -Name 'docs' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.153; `
Add-DnsServerResourceRecordA -Name 'kb' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.153; `
Add-DnsServerResourceRecordA -Name 'code' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.153; `
Add-DnsServerResourceRecordA -Name 'help' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.154; `
Add-DnsServerResourceRecordA -Name 'nuget' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.155; `
Add-DnsServerResourceRecordA -Name 'sampler' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.156; `
Add-DnsServerResourceRecordA -Name 'test' -ZoneName 'goodtocode.com' -IPv4Address 192.168.1.157; `
# GoodToCodeStack.com; `
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'GoodToCodeStack.com' -IPv4Address 192.168.1.151; `
# GoodToCodeFramework.com; `
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'GoodToCodeFramework.com' -IPv4Address 192.168.1.151; `
# GoodToCodeEntities.com; `
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'GoodToCodeEntities.com' -IPv4Address 192.168.1.151; `
# GoodToCodeAppKit.com; `
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'GoodToCodeAppKit.com' -IPv4Address 192.168.1.151; `
# CloudDevEnvironment.com; `
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'CloudDevEnvironment.com' -IPv4Address 192.168.1.160; `
# BalanceSupplies.com; `
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'BalanceSupplies.com' -IPv4Address 192.168.1.91; `
Restart-Service -Name DNS -Force;
***
************** dev **************
***
# goodtocode.com
Add-DnsServerResourceRecordA -Name 'www' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.50; `
Add-DnsServerResourceRecordA -Name 'cart' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.51; `
Add-DnsServerResourceRecordA -Name 'cloud' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.52; `
Add-DnsServerResourceRecordA -Name 'api' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.52; `
Add-DnsServerResourceRecordA -Name 'docs' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.53; `
Add-DnsServerResourceRecordA -Name 'kb' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.53; `
Add-DnsServerResourceRecordA -Name 'code' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.53; `
Add-DnsServerResourceRecordA -Name 'help' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.54; `
Add-DnsServerResourceRecordA -Name 'nuget' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.55; `
Add-DnsServerResourceRecordA -Name 'sampler' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.56; `
Add-DnsServerResourceRecordA -Name 'test' -ZoneName 'dev.goodtocode.com' -IPv4Address 192.168.1.57; `
# GoodToCodeStack.com; `
Add-DnsServerResourceRecordA -Name 'dev' -ZoneName 'GoodToCodeStack.com' -IPv4Address 192.168.1.51; `
# GoodToCodeFramework.com; `
Add-DnsServerResourceRecordA -Name 'dev' -ZoneName 'GoodToCodeFramework.com' -IPv4Address 192.168.1.51; `
# GoodToCodeEntities.com; `
Add-DnsServerResourceRecordA -Name 'dev' -ZoneName 'GoodToCodeEntities.com' -IPv4Address 192.168.1.51; `
# GoodToCodeAppKit.com; `
Add-DnsServerResourceRecordA -Name 'dev' -ZoneName 'GoodToCodeAppKit.com' -IPv4Address 192.168.1.51; `
# CloudDevEnvironment.com; `
Add-DnsServerResourceRecordA -Name 'dev' -ZoneName 'CloudDevEnvironment.com' -IPv4Address 192.168.1.60; `
# BalanceSupplies.com; `
Add-DnsServerResourceRecordA -Name 'dev' -ZoneName 'BalanceSupplies.com' -IPv4Address 192.168.1.91; `
Restart-Service -Name DNS -Force;

**************
(Optional) SSL Cert
**************
letsencrypt.org
#
# Creating a cert
#
# Create in Powershell: https://docs.microsoft.com/en-us/powershell/module/pkiclient/export-pfxcertificate?view=win10-ps
New-SelfSignedCertificate -DnsName "www.fabrikam.com", "www.contoso.com" -CertStoreLocation "cert:\LocalMachine\My"
# Export from store
$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Get-ChildItem -Path cert:\LocalMachine\my | Export-PfxCertificate -FilePath C:\mypfx.pfx -Password $mypwd

#
# Get strong name from file
#
function Get-AssemblyStrongName($assemblyPath)
{
    [System.Reflection.AssemblyName]::GetAssemblyName($assemblyPath).FullName 
}
$Path = 'c:\test\'
$File = Get-ChildItem -Path $Path -Include @("*.dll","*.exe") -Recurse
Foreach ($f in $File)
{
  $assembly=$f.FullName
  Get-AssemblyStrongName $assembly
}

#
# Registering a cert
#
 - MMC.exe -> File -> Add/Remove Snapin -> Certificates
 - Create CSR Request (see text file)
 - MMC.exe -> Certificates -> Personal -> Import -> cer file
OR - certutil -addstore MY <Cer_File>
* now shows in IIS manager, but wont bind

$hostname = "www.goodtocodestack.com"; `
$iisSite = "www.goodtocodestack.com"; `
dir certs:\localmachine\my
$cert = (Get-ChildItem cert:\LocalMachine\My 
      | where-object { $_.Subject -like "*$hostname*" } 
      | Select-Object -First 1).Thumbprint

#
# Bind to hostname
#
$guid = [guid]::NewGuid().ToString("B")
netsh http add sslcert hostnameport="${hostname}:443" certhash=$cert certstorename=MY appid="$guid"

#
# Bind to IP
#
New-WebBinding -name $iisSite -Protocol https  -HostHeader $hostname -Port 443 -SslFlags 1

#
# Remove 
#
netsh http delete sslcert hostnameport=test.west-wind.com:443

**************
Event Log
**************
#
## General
#
Get-EventLog -LogName "application" -Source "IIS*" | Select timewritten, entrytype, source, eventid, message -first 20 | format-list
Get-EventLog -LogName "application" -Source "IIS*" | Where { $_.Message -like '*-Framework-for-*' } | Select timewritten, entrytype, source, eventid, message -first 20 | format-list
#
## App pool recycling
#
Get-WinEvent -LogName System | Where-Object {$_.Message -like "*recycle*"} | select timecreated, id, displayname, message | format-list | out-file app-pool-recycle.txt


**************
TIPS
**************
invoke-command computername {Test-ComputerSecureChannel}
%windir%\system32\inetsrv\InetMgr.exe
Get-NetFirewallRule
Enable-NetFirewallRule
Disable-NetFirewallRule
New-Website
New-WebAppPool
Remove-WebSite 
Start-WebAppPool
Start-WebSite
Get-WebConfiguration
Add-WebConfiguration
Get-NetIPInterface
Get-NetIpConfiguration
set-netipaddress
Add-NetworkAdapterIPAddress
new-netipaddress
Get-NetworkControllerPublicIPAddress
New-NetworkControllerPublicIPAddress
Get-NetworkControllerIpPool
invoke-item c:\sites
Grant-Permission -Identity Everyone -Permission FullControl -Path C:\Sites
Get-DNSServerResourceRecord -ZoneName "goodtocode.com"
# Copy DNS from server A to B
> Get-DnsServer -CimSession 'server01' | Set-DnsServer -ComputerName 'server02'