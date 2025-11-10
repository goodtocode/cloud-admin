# =======================================================================
# New-AfdAppService.ps1
#
# Example:
#   .\New-AfdAppService.ps1 -ResourceGroup "my-rg" -ProductName "myproduct" -AppServiceHost "myapp.azurewebsites.net" -TenantId "00000000-0000-0000-0000-000000000000" -Environment "dev"
#
# Parameters:
#   -ResourceGroup   : Name of the Azure resource group (required)
#   -ProductName     : Short name for the product or application (required)
#   -AppServiceHost  : Hostname of the Azure App Service (required)
#   -TenantId        : Azure AD Tenant ID (required for login context)
#   -Environment     : Environment name (e.g., dev, test, prod). Default is 'dev'.
#
# Description:
#   This script automates the creation and configuration of an Azure Front Door (AFD) Standard profile, endpoint, origin group, origin, and route for an Azure App Service.
#   Resource names are convention-driven based on ProductName and Environment. All resources are created if they do not exist. The script outputs the default FQDN for the endpoint.
# =======================================================================

param(
    [string]$ResourceGroup,
    [string]$ProductName,    
    [string]$AppServiceHost,
    [guid]$TenantId,
    [string]$Environment = "dev"
)

# Convention-driven variable names
$ProfileName     = "afd-platform-hub-westus2-001"
$EndpointName    = "afdend-$ProductName-$Environment"
$OriginGroupName = "afdpool-$ProductName-$Environment"
$OriginName      = "afdorigin-$ProductName-$Environment"
$RouteName       = "afdroute-$ProductName-$Environment"

###############################################################
# Initialize
###############################################################
if ($IsWindows) { Set-ExecutionPolicy Unrestricted -Scope Process -Force }
$VerbosePreference = 'SilentlyContinue' # Set to 'Continue' for verbose output
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
[DateTime]$Now = Get-Date
Set-Location $ThisDir # Ensure script runs from its own directory
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
# Check for valid Azure login
$azContext = Get-AzContext 2>$null
if (-not $azContext -or -not $azContext.Account) {
    Write-Error "No valid Azure login found. Please run Connect-AzAccount and try again."
    exit 1
}
# Check for valid resource group
if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    Write-Error "Resource group '$ResourceGroup' does not exist in the current subscription."
    exit 1
}

# Front Door Profile
$profile = Get-AzFrontDoorCdnProfile -ResourceGroupName $ResourceGroup -Name $ProfileName -ErrorAction SilentlyContinue
if (-not $profile) {
    Write-Host "Creating AFD Profile: $ProfileName"
    $profile = New-AzFrontDoorCdnProfile -ResourceGroupName $ResourceGroup -Name $ProfileName `
        -SkuName "Standard_AzureFrontDoor" -Location "Global"
} else {
    Write-Host "Profile exists: $ProfileName"
}


# Endpoint
$endpoint = Get-AzFrontDoorCdnEndpoint -ResourceGroupName $ResourceGroup -ProfileName $ProfileName -EndpointName $EndpointName -ErrorAction SilentlyContinue
if (-not $endpoint) {
    Write-Host "Creating Endpoint: $EndpointName"
    $endpoint = New-AzFrontDoorCdnEndpoint -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -EndpointName $EndpointName -Location "Global" -EnabledState "Enabled"
} else {
    Write-Host "Endpoint exists: $EndpointName"
}


# Origin Group
$originGroup = Get-AzFrontDoorCdnOriginGroup -ResourceGroupName $ResourceGroup -ProfileName $ProfileName -OriginGroupName $OriginGroupName -ErrorAction SilentlyContinue
if (-not $originGroup) {
    Write-Host "Creating Origin Group: $OriginGroupName"
    $healthProbeSetting = New-AzFrontDoorCdnOriginGroupHealthProbeSettingObject -ProbeIntervalInSecond 100 -ProbePath "/" -ProbeProtocol "Https" -ProbeRequestType "HEAD"
    $loadBalancingSetting = New-AzFrontDoorCdnOriginGroupLoadBalancingSettingObject -AdditionalLatencyInMillisecond 50 -SampleSize 4 -SuccessfulSamplesRequired 3
    $originGroup = New-AzFrontDoorCdnOriginGroup -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -OriginGroupName $OriginGroupName -HealthProbeSetting $healthProbeSetting -LoadBalancingSetting $loadBalancingSetting
} else {
    Write-Host "Origin Group exists: $OriginGroupName"
}


# Origin
$origin = Get-AzFrontDoorCdnOrigin -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
    -OriginGroupName $OriginGroupName -OriginName $OriginName -ErrorAction SilentlyContinue
if (-not $origin) {
    Write-Host "Creating Origin: $OriginName"
    $origin = New-AzFrontDoorCdnOrigin -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -OriginGroupName $OriginGroupName -OriginName $OriginName -HostName $AppServiceHost `
        -OriginHostHeader $AppServiceHost -HttpPort 80 -HttpsPort 443 -EnabledState "Enabled"
} else {
    Write-Host "Origin exists: $OriginName"
}


# Route
$route = Get-AzFrontDoorCdnRoute -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
    -EndpointName $EndpointName -Name $RouteName -ErrorAction SilentlyContinue
if (-not $route) {
    Write-Host "Creating Route: $RouteName"
    $route = New-AzFrontDoorCdnRoute -ResourceGroupName $ResourceGroup -ProfileName $ProfileName `
        -EndpointName $EndpointName -Name $RouteName -OriginGroupId $originGroup.Id `
        -PatternsToMatch "/*" -SupportedProtocol @("Http","Https") `
        -ForwardingProtocol "MatchRequest" -HttpsRedirect "Enabled" -EnabledState "Enabled" `
        -LinkToDefaultDomain "Enabled"
} else {
    Write-Host "Route exists: $RouteName"
}


Write-Host "Setup complete. Default FQDN: https://$EndpointName.$ProfileName.azurefd.net"