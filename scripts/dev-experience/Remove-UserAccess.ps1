param (
    [string]$user = "USERNAME",
    [bool]$breakInheritance = $false,
    [bool]$removeExistingRules = $true,
    [bool]$revert = $false

)

[bool]$revert = $false
[bool]$removeExistingRules = $true

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "⚠️ You must run this script as Administrator!"
    break
}

$drive = "C:\"
$includedPaths = @("\azagent",
    "\Packages",
    "\PerfLogs",
    "\Program Files",
    "\Program Files (x86)",
    "\ProgramData",
    "\Sites",
    "\Temp",
    "\Users",
    "\Windows")
$excludedPaths = @(
    "\inetpub\temp\IIS Temporary Compressed Files",
    "\inetpub\logs\LogFiles",
    "\Windows\Temp",
    "\Windows\Microsoft.NET\Framework\v4.0.30319\Temporary ASP.NET Files",
    "\Windows\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files"
)
#-bor [System.Security.AccessControl.FileSystemRights]::Modify `

$denyRights = [System.Security.AccessControl.FileSystemRights]::Write `
    -bor [System.Security.AccessControl.FileSystemRights]::CreateFiles `
    -bor [System.Security.AccessControl.FileSystemRights]::CreateDirectories `
    -bor [System.Security.AccessControl.FileSystemRights]::Delete

$allowRights = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute `
    -bor [System.Security.AccessControl.FileSystemRights]::ListDirectory `
    -bor [System.Security.AccessControl.FileSystemRights]::Read

$inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
    [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
$propagationFlags = [System.Security.AccessControl.PropagationFlags]::None

Start-Transcript -Path "$drive\Temp\ACL_Changes_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" -Append

$foldersToProcess = Get-ChildItem -Path $drive -Directory | Where-Object {
    $includedPaths -contains $_.FullName.Substring($drive.Length - 1)
}

$foldersToProcess = $foldersToProcess | Where-Object {
    $excludedPaths -notcontains $_.FullName
}

foreach ($folder in $foldersToProcess) {
    try {
        $acl = Get-Acl $folder.FullName

        if ($revert) {
            $acl.SetAccessRuleProtection($false, $true)
            Set-Acl -Path $folder.FullName -AclObject $acl
            Write-Host "Inheritance enabled and Reverted ACL changes for $($folder.FullName)"
        }
        else {
            if ($removeExistingRules) {
                $existingRules = $acl.Access | Where-Object {
                    $_.IdentityReference.Value -eq $user
                }
                foreach ($rule in $existingRules) {
                    $acl.RemoveAccessRule($rule)
                }
                Write-Host "Removed $($existingRules.Count) existing ACL rules for $user on $($folder.FullName)"
            }
            
            $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $user,
                $denyRights,
                $inheritanceFlags,
                $propagationFlags,
                [System.Security.AccessControl.AccessControlType]::Deny
            )
            $acl.AddAccessRule($denyRule)

            $allowRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $user,
                $allowRights,
                $inheritanceFlags,
                $propagationFlags,
                [System.Security.AccessControl.AccessControlType]::Allow
            )
            $acl.AddAccessRule($allowRule)

            Set-Acl -Path $folder.FullName -AclObject $acl
            Write-Host "✅ Updated ACL for $user on $($folder.FullName): Deny Write, Allow Read"
        }
    }
    catch {
        Write-Error "❌ Failed to set ACL on $($folder.FullName)"
        Write-Host "📂 Folder: $($folder.FullName)"
        Write-Host "🔍 ACL Object: $($acl | Out-String)"
        Write-Host "🧾 Error: $($_.Exception.Message)"
    }        
}
Stop-Transcript