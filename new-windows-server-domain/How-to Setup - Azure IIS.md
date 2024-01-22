# How to setup an Azure VM IIS Server that is joined to a domain

## Initial setup - pre domain join
1. Install a VM image from the Azure marketplace
2. Login with Local Administrator
3. Rename computer
* 15 Characters max: vm-4chars-3chars-2chars
> Rename-Computer -NewName "vm-WHAT-ENV-##"
4. Restart Computer
> Restart-Computer

## Join to domain
1. start powershell as local admin
> sconfig or powershell.exe
2. Join computer to domain
>  Add-Computer -DomainName DMAIN -Credential DOMAIN\ADMIN_USER -Restart

## Setup Remote Users and Local Administrators
**At this point, only Domain Admins and LocalAdmin account can remote into the server**
**To-do: Use AzCli or Az.Powershell to add Remote Desktop Users and Administrator users**
1. Add domain user to Remote Users group
* Azure portal - Virtual Machine - Run command
> Add-LocalGroupMember -Group "Remote Desktop Users" -Member "DOMAIN\Group"
* OR Login with local administrator
> User: .\LocalAdminName
2. Login with domain user
3. Start powershell with local admin (domain users arent admins unless Global Administrators)
> sconfig or powershell.exe
4. Add Local Administrators
> Add-LocalGroupMember -Group "Administrators" -Member "DOMAIN\Group"

## Install Azure DevOps Agents per environment
1. Go to Azure DevOps
2. Create/Select Environment
3. Add Agent for environment, select Virtual Machine
4. Copy/paste powershell
5. Alter powershell to include --agent $env:COMPUTERNAME-###. Whereas ### is the acronym for Azure DevOps Project
>.\config.cmd --environment --environmentname "QA" --agent $env:COMPUTERNAME-PROJECT --runasservice --work '_work' --url 'https://dev.azure.com/ORG/' --projectname 'PROJECT' --auth PAT --token PAT

## Install Runtimes
1. For .NET Core and beyond: .NET Runtime. I.e. dotnet-hosting-7.0.5-win.exe
1. For react and node: Node.js. I.e. node-v14.17.0-x64.exe
1. For older ASP.NET MVC 5 and below: Rewrite module. I.e. rewrite_amd64_en-US.exe

## IIS
### Install IIS Feature 
1. Install IIS
> Install-WindowsFeature Web-Server

### Install IIS MMC
1. Install Web Management Console
> Install-WindowsFeature -Name Web-Mgmt-Console
1. Verify by running MMC
> c:\windows\system32\inetsrv\inetmgr.exe

### Add Anonymous authentication
1. Add anonymous authentication method
> Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter 'system.webServer/security/authentication/anonymousAuthentication' -Name 'enabled' -Value 'True'
> Restart-Service -Name 'W3SVC' -Force

1. Get anonymous authentication value for website
> Get-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name "value" -PSPath 'IIS:\Sites\YourWebsiteName' | Select-Object value

1. Set For website
> Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name 'enabled' -Value $true -PSPath 'IIS:\Sites\YourWebsiteName'
> Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/YourWebsiteName' -filter "system.webServer/security/authentication/anonymousAuthentication" -name "enabled" -value "True"

1. Set For subfolder
> Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/YourWebsiteName' -filter "system.webServer/security/authentication/anonymousAuthentication" -name "enabled" -value "True" -Location "Subfolder"

### Environment variable
1. ASPNETCORE_ENVIRONMENT
> Get-Childitem env:
> Set-Item -Path Env:ASPNETCORE_ENVIRONMENT -Value "Development"
1. Make sure changes take effect
> Restart-Computer

## SSL Cert
1. Add to LocalMachine\My
> Import-PfxCertificate -FilePath C:\mycert.pfx -Password (ConvertTo-SecureString -String 'mypassword' -AsPlainText -Force) -CertStoreLocation Cert:\LocalMachine\My

## Install .NET Hosting Bundle
1. Install .NET 7 (or preferred version)
- Winget
> winget install --id=Microsoft.dotnetHostingBundle -e --version 7.0
- Powershell
> Invoke-WebRequest -Uri "https://download.visualstudio.microsoft.com/download/pr/973c909f-7e10-4a36-b9dd-7c56e21a3663/2c6f8aa6e5a3e84f91f1e79e6e3705e1/dotnet-hosting-7.0.0-win.exe" -OutFile "dotnet-hosting-7.0.0-win.exe"

> Start-Process -FilePath ".\dotnet-hosting-7.0.0-win.exe" -ArgumentList "/quiet" -Wait
