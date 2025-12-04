<#!
.SYNOPSIS
Removes Azure Front Door resources for a given product and environment.
.DESCRIPTION
Removes the Azure Front Door endpoint, origin group, origin, and route for the specified product and environment. Does not delete the AFD profile.
.PARAMETER ResourceGroup
Name of the Azure resource group (required).
.PARAMETER ProductName
Short name for the product or application (required).
.PARAMETER TenantId
Azure AD Tenant ID (required for login context).
.PARAMETER Environment
Environment name (e.g., dev, test, prod). Default is 'dev'.
.EXAMPLE
PS> .\Remove-AfdAppService.ps1 -ResourceGroup "my-rg" -ProductName "myproduct" -TenantId "00000000-0000-0000-0000-000000000000" -Environment "dev"
Removes the Azure Front Door resources for the specified parameters.
.NOTES
Author: GoodToCode
#>
param(
    [string]$ResourceGroup,
    [string]$ProductName,
    [guid]$TenantId,
    [string]$ExternalDns,
    [string]$Environment = "dev",
    [bool]$RemoveSharedResources = $false
)

# Convention-driven variable names
$ExternalDnsAlpha = $ExternalDns -replace "[^a-zA-Z]", ""
$ProfileName     = "afd-platform-hub-westus2-001"
$EndpointName    = "afdend-$ExternalDnsAlpha-$Environment"
$OriginGroupName = "afdpool-$ExternalDnsAlpha-$ProductName-$Environment"
$OriginName      = "afdorigin-$ProductName-$Environment-001"
# Set default RouteName if not provided
if ([string]::IsNullOrWhiteSpace($RouteName)) {
    $RouteName = "afdroute-$ProductName-$Environment"
}

###############################################################
# Initialize
###############################################################
if ($IsWindows) { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
$VerbosePreference = 'SilentlyContinue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
[DateTime]$Now = Get-Date
Set-Location $ThisDir
Write-Host "---------------------------"
Write-Host "--- Starting: $ThisScript on $Now"
Write-Host "---------------------------"

###############################################################
# Execute
###############################################################
$requiredModules = @('Az.Accounts', 'Az.Cdn', 'Az.FrontDoor', 'Az.Resources')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Module $module not found. Installing..."
        try {
            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
        } catch {
            Write-Error "Failed to install module $module. Please install manually."
            exit 1
        }
    }
}

Connect-AzAccount -Tenant $TenantId -ErrorAction Stop
$azContext = Get-AzContext 2>$null
if (-not $azContext -or -not $azContext.Account) {
    Write-Error "No valid Azure login found. Please run Connect-AzAccount and try again."
    exit 1
}

# Validate resource group
if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Error "Resource group '$ResourceGroup' does not exist."
    exit 1
}

###############################################################
# Delete Route
###############################################################
$route = Get-AzFrontDoorCdnRoute -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
    -EndpointName $EndpointName -Name $RouteName -ErrorAction SilentlyContinue
if ($route) {
    Write-Host "Removing Route: $RouteName"
    Remove-AzFrontDoorCdnRoute -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -EndpointName $EndpointName -Name $RouteName
} else {
    Write-Host "Route not found: $RouteName"
}

###############################################################
# Delete Origin
###############################################################
$origin = Get-AzFrontDoorCdnOrigin -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
    -OriginGroupName $OriginGroupName -OriginName $OriginName -ErrorAction SilentlyContinue
if ($origin) {
    Write-Host "Removing Origin: $OriginName"
    Remove-AzFrontDoorCdnOrigin -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -OriginGroupName $OriginGroupName -OriginName $OriginName
} else {
    Write-Host "Origin not found: $OriginName"
}

###############################################################
# Delete Origin Group
###############################################################
$originGroup = Get-AzFrontDoorCdnOriginGroup -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
    -OriginGroupName $OriginGroupName -ErrorAction SilentlyContinue
if ($originGroup) {
    Write-Host "Removing Origin Group: $OriginGroupName"
    Remove-AzFrontDoorCdnOriginGroup -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -OriginGroupName $OriginGroupName
} else {
    Write-Host "Origin Group not found: $OriginGroupName"
}

###############################################################
# Delete Endpoint
###############################################################
$endpoint = Get-AzFrontDoorCdnEndpoint -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
    -EndpointName $EndpointName -ErrorAction SilentlyContinue
if ($endpoint -and $RemoveSharedResources) {
    Write-Host "Removing Endpoint: $EndpointName"
    Remove-AzFrontDoorCdnEndpoint -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -EndpointName $EndpointName
} else {
    Write-Host "Endpoint not found: $EndpointName"
}

###############################################################
# Delete Rule from Ruleset
###############################################################
$rulesetName = "${ExternalDnsAlpha}RewriteToOriginPath"
$ruleName = "${ProductName}RewriteEndpointPathToOriginPath"
$rule = Get-AzFrontDoorCdnRule -ResourceGroupName $ResourceGroup -ProfileName $ProfileName -RuleSetName $rulesetName -Name $ruleName -ErrorAction SilentlyContinue
if ($rule) {
    Write-Host "Removing Rule: $ruleName from Ruleset: $rulesetName"
    Remove-AzFrontDoorCdnRule -ResourceGroupName $ResourceGroup -ProfileName $ProfileName -RuleSetName $rulesetName -Name $ruleName
} else {
    Write-Host "Rule not found: $ruleName in Ruleset: $rulesetName"
}

###############################################################
# Delete Ruleset if no rules remain
###############################################################
$rules = Get-AzFrontDoorCdnRule -ResourceGroupName $ResourceGroup -ProfileName $ProfileName -RuleSetName $rulesetName -ErrorAction SilentlyContinue
if ($null -eq $rules -or $rules.Count -eq 0) {
    $ruleset = Get-AzFrontDoorCdnRuleSet -ResourceGroupName $ResourceGroup -ProfileName $ProfileName -Name $rulesetName -ErrorAction SilentlyContinue
    if ($ruleset) {
        Write-Host "Removing Ruleset: $rulesetName (no rules remain)"
        Remove-AzFrontDoorCdnRuleSet -ResourceGroupName $ResourceGroup -ProfileName $ProfileName -Name $rulesetName
    } else {
        Write-Host "Ruleset not found: $rulesetName"
    }
} else {
    Write-Host "Ruleset $rulesetName not removed (other rules remain)"
}

Write-Host "✅ Removal complete for $ProductName ($Environment)."