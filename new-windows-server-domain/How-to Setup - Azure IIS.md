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