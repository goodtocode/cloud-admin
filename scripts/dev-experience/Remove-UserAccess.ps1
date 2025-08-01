param (
    [string]$user = "USERNAME",
    [String]$rootPath = "C:\Temp",
    [bool]$revert = $false
)

# Folders to exclude from write denial (Sitecore/IIS essentials)
$excludedPaths = @(
    "C:\inetpub",
    "C:\Windows\Temp"
)

# Define rights explicitly using enums
$denyRights = [System.Security.AccessControl.FileSystemRights]::Write `
            -bor [System.Security.AccessControl.FileSystemRights]::CreateFiles `
            -bor [System.Security.AccessControl.FileSystemRights]::CreateDirectories `
            -bor [System.Security.AccessControl.FileSystemRights]::Modify `
            -bor [System.Security.AccessControl.FileSystemRights]::Delete

$allowRights = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute `
             -bor [System.Security.AccessControl.FileSystemRights]::ListDirectory `
             -bor [System.Security.AccessControl.FileSystemRights]::Read

$inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                    [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
$propagationFlags = [System.Security.AccessControl.PropagationFlags]::None

$foldersToProcess = Get-ChildItem -Path $rootPath -Directory | Where-Object {
    $excludedPaths -notcontains $_.FullName
}

foreach ($folder in $foldersToProcess) {
    $acl = Get-Acl $folder.FullName

    if ($revert) {        
        $acl = Get-Acl $folder
        $acl.SetAccessRuleProtection($false, $true)  # Re-enable inheritance, remove explicit rules
        Set-Acl $folder $acl
        Write-Host "Reverted ACL changes for $user on $($folder.FullName)"
    }
    else {
        # Remove any existing rules for the user to avoid conflicts
        $existingRules = $acl.Access | Where-Object {
            $_.IdentityReference -like "*$user"
        }
        foreach ($rule in $existingRules) {
            $acl.RemoveAccessRule($rule)
        }

        # Add deny rule for write-related rights
        $denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $user,
            $denyRights,
            $inheritanceFlags,
            $propagationFlags,
            [System.Security.AccessControl.AccessControlType]::Deny
        )
        $acl.AddAccessRule($denyRule)

        # Add allow rule for read-related rights
        $allowRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $user,
            $allowRights,
            $inheritanceFlags,
            $propagationFlags,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $acl.AddAccessRule($allowRule)

        Set-Acl $folder.FullName $acl
        Write-Host "ACL updated for $user on $($folder.FullName): Deny Write, Allow Read"
    }
}
