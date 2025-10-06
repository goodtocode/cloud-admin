#-----------------------------------------------------------------------
# Get-DnsRecord [FQDN [<String>]]
#
# Example: .\Compare-Folders.ps1 -Path "\\dev\mysite\App_Config" -ComparePath "\\sandbox\mysite\App_Config"
#-----------------------------------------------------------------------
# ---
# --- Parameters
# ---
param (
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [string]$ComparePath
)

# ---
# --- Initialize
# ---
if ($IsWindows) { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
$VerbosePreference = 'SilentlyContinue' #'Continue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
[DateTime]$Now = Get-Date
Set-Location $ThisDir # Ensure our location is correct, so we can use relative paths
Write-Host "---------------------------"
Write-Host "--- Starting: $ThisScript on $Now"
Write-Host "---------------------------"


# Get all files recursively from both paths
$sourceFiles = Get-ChildItem -Path $Path -Recurse -File
$compareFiles = Get-ChildItem -Path $ComparePath -Recurse -File

# Normalize paths relative to root
$sourceRelative = $sourceFiles | ForEach-Object {
    $_ | Add-Member -NotePropertyName RelativePath -NotePropertyValue ($_.FullName -replace [regex]::Escape($Path), "") -PassThru
}
$compareRelative = $compareFiles | ForEach-Object {
    $_ | Add-Member -NotePropertyName RelativePath -NotePropertyValue ($_.FullName -replace [regex]::Escape($ComparePath), "") -PassThru
}

# Compare file lists
$sourceSet = $sourceRelative.RelativePath
$compareSet = $compareRelative.RelativePath

$onlyInSource = $sourceSet | Where-Object { $_ -notin $compareSet }
$onlyInCompare = $compareSet | Where-Object { $_ -notin $sourceSet }
$inBoth = $sourceSet | Where-Object { $_ -in $compareSet }

# Optionally compare file content (hash)
$diffContent = @()
foreach ($file in $inBoth) {
    $sourceFile = $sourceRelative | Where-Object { $_.RelativePath -eq $file }
    $compareFile = $compareRelative | Where-Object { $_.RelativePath -eq $file }

    $sourceHash = Get-FileHash -Path $sourceFile.FullName -Algorithm SHA256
    $compareHash = Get-FileHash -Path $compareFile.FullName -Algorithm SHA256

    if ($sourceHash.Hash -ne $compareHash.Hash) {
        $diffContent += $file
    }
}

# Output results
Write-Host "---------------------------"
Write-Host "Files only in $Path"
Write-Host "---------------------------"
$onlyInSource | ForEach-Object { Write-Host $_ }

Write-Host "---------------------------"
Write-Host "Files only in $ComparePath"
Write-Host "---------------------------"
$onlyInCompare | ForEach-Object { Write-Host $_ }

Write-Host "---------------------------"
Write-Host "Files with different content"
Write-Host "---------------------------"
$diffContent | ForEach-Object { Write-Host $_ }