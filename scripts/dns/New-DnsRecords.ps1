[CmdletBinding()]
param (
    [string]$TenantId = "",
    [string]$SubscriptionId = ""
)

$resourceGroupName = "rg-platform-connectivity-westus2-001"
$dnsZoneName = "myco.com"
$dnsRecords = @{
    "dev.myco.com" = "0.0.0.0"
    "qa.myco.com" = "0.0.0.0"
    "stg.myco.com" = "0.0.0.0"
    "www.myco.com" = "*"
    
}


Install-Module Az.PrivateDns -Force -AllowClobber -Scope CurrentUser
Import-Module Az.PrivateDns -Force

Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId

foreach ($fqdn in $dnsRecords.Keys) {
    $ip = $dnsRecords[$fqdn]

    if ($ip -eq "*") {
        Write-Host "Skipping wildcard entry: $fqdn"
        continue
    }    
    if ($ip -notlike "10.*") {
        $ip = "0.0.0.0"
    }


    $relativeRecordName = $fqdn -replace "\.aacn\.org$", ""
    Write-Host "Creating/updating PRIVATE A record for $fqdn with IP $ip..."

    New-AzPrivateDnsRecordSet `
        -Name $relativeRecordName `
        -RecordType A `
        -ZoneName $dnsZoneName `
        -ResourceGroupName $resourceGroupName `
        -Ttl 3600 `
        -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $ip)
        
    Write-Host "Record for $fqdn created/updated successfully."
}
