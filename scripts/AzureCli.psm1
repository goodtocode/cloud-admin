#-----------------------------------------------------------------------
# Shared helpers for scripts that use the az CLI (no az extensions required).
#
# Import: Import-Module (Join-Path $PSScriptRoot '../AzureCli.psm1') -Force
#-----------------------------------------------------------------------

function Invoke-Az {
    # Runs az, returns stdout, throws stderr on failure (keeps warnings out of parsed JSON).
    $errFile = New-TemporaryFile
    try {
        $out = & az @args 2>$errFile
        if ($LASTEXITCODE -ne 0) { throw ((Get-Content $errFile -Raw) + ($out | Out-String)) }
        $out
    } finally { Remove-Item $errFile -ErrorAction SilentlyContinue }
}

function Connect-AzCliIfNeeded {
    # Logs in only when there is no active az session. Optional tenant.
    param([string] $TenantId)
    $null = & az account show 2>$null
    if ($LASTEXITCODE -eq 0) { return }
    if ($TenantId) { Invoke-Az login --tenant $TenantId --only-show-errors | Out-Null }
    else { Invoke-Az login --only-show-errors | Out-Null }
}

function Get-AzCliSubscription {
    # Enabled subscriptions the signed-in user can see. Optional filter by id or name.
    param([string[]] $Subscription)
    $subs = @(Invoke-Az account list --query "[?state=='Enabled']" -o json | ConvertFrom-Json)
    if ($Subscription) { $subs = @($subs | Where-Object { $_.id -in $Subscription -or $_.name -in $Subscription }) }
    $subs
}

function Invoke-AzResourceGraph {
    # Runs an Azure Resource Graph (KQL) query across subscriptions through az rest, following paging.
    param(
        [Parameter(Mandatory)][string] $Query,
        [string[]] $SubscriptionId
    )
    if (-not $SubscriptionId) { $SubscriptionId = @(Get-AzCliSubscription).id }
    $results = @()
    $skipToken = $null
    do {
        $body = @{ query = $Query; subscriptions = @($SubscriptionId); options = @{ '$top' = 1000; resultFormat = 'objectArray' } }
        if ($skipToken) { $body.options['$skipToken'] = $skipToken }
        $tmp = New-TemporaryFile
        try {
            $body | ConvertTo-Json -Depth 6 | Set-Content -Path $tmp -Encoding utf8
            $resp = Invoke-Az rest --method post --url 'https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2022-10-01' --body "@$($tmp.FullName)" -o json | ConvertFrom-Json
        } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
        if ($resp.data) { $results += @($resp.data) }
        $skipToken = $resp.'$skipToken'
    } while ($skipToken)
    $results
}

Export-ModuleMember -Function Invoke-Az, Connect-AzCliIfNeeded, Get-AzCliSubscription, Invoke-AzResourceGraph
