# List of FQDNs to test
$fqdns = @(
    "sub.myco.com"
)



# Arrays to hold unreachable and reachable hosts
$unreachable = @()
$reachable = @()

# Test each FQDN
foreach ($fqdn in $fqdns) {
    Write-Host "Testing $fqdn..."
    $result = Test-Connection -ComputerName $fqdn -Count 2 -Quiet
    if ($result) {
        $reachable += $fqdn
    } else {
        $unreachable += $fqdn
    }
}

# Report reachable hosts
if ($reachable.Count -gt 0) {
    Write-Host "`nReachable FQDNs:"
    $reachable | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "`nNo FQDNs are reachable."
}

# Report unreachable hosts
if ($unreachable.Count -gt 0) {
    Write-Host "`nUnreachable FQDNs:"
    $unreachable | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "`nAll FQDNs are reachable."
}
