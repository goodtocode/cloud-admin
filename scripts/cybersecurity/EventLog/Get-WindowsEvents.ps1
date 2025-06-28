$startDate = Get-Date "2024-04-08"
$endDate = Get-Date "2024-05-09"
$logName = "Application"  # Adjust to the appropriate log name

$events = Get-WinEvent -FilterHashtable @{
    LogName = $logName
    StartTime = $startDate
    EndTime = $endDate
}

$events | Select-Object TimeCreated, Id, LevelDisplayName, Message | Export-CSV -Path "C:\temp\eventlog-$logName-$startDate-$endDate.csv" -NoTypeInformation

# Get all events
#$events = Get-WinEvent -ComputerName "myserver.myco.org" -LogName "Application"
#$events | Select-Object TimeCreated, Id, LevelDisplayName, Message | Export-CSV -Path "C:\temp\eventlog-all.csv" -NoTypeInformation


# Track file audit security events
$startDate = Get-Date "2025-06-23"
$endDate = Get-Date "2025-06-25"
$logName = "Security"

$events = Get-WinEvent -FilterHashtable @{
    LogName = $logName
    StartTime = $startDate
    EndTime = $endDate
    Id = 4663  # File access attempt
}

$events | Where-Object { $_.Message -like "*.config*" } |
    Select-Object TimeCreated, Id, LevelDisplayName, Message |
    Export-CSV -Path "C:\temp\auditlog-web-config.csv" -NoTypeInformation

