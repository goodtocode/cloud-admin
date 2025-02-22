#-----------------------------------------------------------------------
# Connect-IfNotAuthenticated [-TenantId [<String>]] [-SubscriptionId [<String>]]
#
# Example: .\Connect-IfNotAuthenticated -TenantId "00000000-85ea-42d2-b7b3-30ef2666c7ab" -SubscriptionId "00000000-9f24-40c0-87b8-69bdd5ae60a3"
#	Result: Already authenticated to subscription
#-----------------------------------------------------------------------
function Connect-IfNotAuthenticated {
    param (
        [string]$TenantId,
        [string]$SubscriptionId
    )

    $context = Get-AzContext
    if ($context -and $context.Subscription.Id -eq $SubscriptionId) {
        Write-Host "Already authenticated to subscription $SubscriptionId"
    } else {
        Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId
    }
}