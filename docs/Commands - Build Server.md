################
 Folder and Share
 # ACL Rights: Delete, FullControl, Modify, Read, ReadAndExecute, Write
################
# Folder and Share
$User = "dev\GoodToCodeAgents"; `
$ShareName = "Builds"; `
$Path = "c:\Builds"; `
$Access = 'FullControl'; `
md $Path; `
$Acl = Get-Acl $Path; `
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "$Access", "ContainerInherit,ObjectInherit", "None", "Allow"); `
$Acl.SetAccessRule($Ar); `
Set-Acl $Path $Acl;
New-SmbShare -Name $ShareName -Path $Path -Description $ShareName -FullAccess $User;

################
 Folder Only
 # ACL Rights: Delete, FullControl, Modify, Read, ReadAndExecute, Write
################
# Folder and Share
$User = "dev\GoodToCodeAgents"; `
$ShareName = "Builds"; `
$Path = "c:\Builds"; `
$Access = 'FullControl'; `
md $Path; `
$Acl = Get-Acl $Path; `
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "$Access", "ContainerInherit,ObjectInherit", "None", "Allow"); `
$Acl.SetAccessRule($Ar); `
Set-Acl $Path $Acl;

################
# Folder Permissions only
#  ACL Rights: Delete, FullControl, Modify, Read, ReadAndExecute, Write
#  dev\goodtocodeagents dev\domain users dev\domain admins
################
$User = "dev\domain admins"; `
$Path = "c:\Builds"; `
$Access = 'FullControl'; `
$Acl = Get-Acl $Path; `
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($User, "$Access", "ContainerInherit,ObjectInherit", "None", "Allow"); `
$Acl.SetAccessRule($Ar); `
Set-Acl $Path $Acl;

################
 Folder Share Create
 # ACL Rights: Delete, FullControl, Modify, Read, ReadAndExecute, Write
################
$User = "Dev\Domain Users"; `
$ShareName = "Builds"; `
$Path = "c:\Builds"; `
New-SmbShare -Name $ShareName -Path $Path -Description $ShareName -FullAccess $User;

################
# Install build tools (so can compile)
################
Invoke-WebRequest "https://download.visualstudio.microsoft.com/download/pr/10811663/e64d79b40219aea618ce2fe10ebd5f0d/vs_BuildTools.exe" -OutFile "vsBuildTools.exe" -UseBasicParsing
\\dev-vm-01\vault\Files\Development\Visual-Studio-Build-Tools\vs_buildtools__1198963523.1528481771.exe --all --quiet

################
# Visual Studio Install
################
# Download and run vssetup.exe - use the UI
# Visual Studio Update from command line
& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" update --passive --norestart --installpath "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise"

################
# Build Agent
################
# Download the agent
https://github.com/Microsoft/vsts-agent/releases/download
mw7ha53mtgfojm2wd7wqykfckq5dg6e35rvukr3vmoqhburanwkq

# Create the agent; `
$Path = 'c:\builds\build-01-agent-01'; `
$ZipPath ='\builds'; `
$ZipName ='vsts-agent-win-x64-2.134.2.zip'; `
mkdir $Path; `
cd $Path; `
Add-Type -AssemblyName System.IO.Compression.FileSystem; `
 [System.IO.Compression.ZipFile]::ExtractToDirectory("$ZipPath\$ZipName", "$PWD");

# Configure; `
.\config.cmd;

---
a. Url: https://goodtocode.visualstudio.com
b. PAT (PAT, Integrated, ) - Enter for PAT
c. Get PAT: goodtocode.visualstudio.com, Profile menu in upper-right, Security, Generate PAT
 - Enter PAT: 
d. Agent Pool: Default
e. Agent Name: DEV-BUILD-01-2018
f. Work folder: _work
g. Run as service? Y
h. dev\GoodToCodeBuildAgent
i. password

#
# Old agents: VGO-TFS-02-2017
# remove
.\config.cmd remove
Optionally run the agent interactively:
.\run.cmd

**************
Update windows
**************
# only v5+ has windows update
$PSVersionTable.PSVersion
Set-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2/ -InstallationPolicy Trusted
Install-Module PSWindowsUpdate; `
Get-Command -module PSWindowsUpdate; `
Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d; `
Get-WUInstall -MicrosoftUpdate -AcceptAll -AutoReboot

################
# Debugging service
################
Get-Service | select name, status
Get-EventLog -LogName "system" -Source "Service*" | Where { $_.Message -like '*VSTS Agent*' } | Select timewritten, entrytype, source, eventid, message -first 20 | format-list
Get-EventLog -LogName application | Select-Object Message | Format-Table -Wrap
Get-EventLog -LogName application -Message "*bootstrapper*" | Select-Object Message | Format-Table -Wrap

# Installing Desktop Experience
```
dism /online /get-features
dism /online /enable-feature /featurename:Server-Gui-Shell
```