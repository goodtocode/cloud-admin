####################################################################################
# To execute
#   1. Run Powershell as ADMINistrator
#   2. In powershell, set security polilcy for this script: 
#      Set-ExecutionPolicy Unrestricted -Scope Process -Force
#   3. Change directory to the script folder:
#      CD C:\Scripts (wherever your script is)
#   4. In powershell, run script: 
#      .\Get-AccessToken-OnBehalfOf.ps1 -TenantId "00000000-85ea-42d2-b7b3-30ef2666c7ab" -ClientId "00000000-9f24-40c0-87b8-69bdd5ae60a3" -ClientSecret "SECRET HERE" -Scope "api://00000000-4ae8-43f7-8c1f-71b3a340d4fd/.default" or "Editor, Viewer"
# To execute
#   1. Obtain a user access token (e.g., via device code or interactive login)
#   2. Run this script with the user token as -UserAccessToken
####################################################################################

param (
    [string]$TenantId = $(throw '-TenantId is a required parameter.'),
    [string]$ClientId = $(throw '-ClientId is a required parameter.'),
    [string]$Scope = $(throw '-Scope is a required parameter.'), # API scope for OBO
    [string]$FrontendRedirectUri = "http://localhost", # Must match app registration
    [string]$FrontendScope = "openid profile email",   # Scopes for user token
    [switch]$Interactive
)

####################################################################################
Set-ExecutionPolicy Unrestricted -Scope Process -Force
$VerbosePreference = 'SilentlyContinue'
[String]$ThisScript = $MyInvocation.MyCommand.Path
[String]$ThisDir = Split-Path $ThisScript
Set-Location $ThisDir
Write-Host "*****************************"
Write-Host "*** Starting: $ThisScript On: $(Get-Date)"
Write-Host "*****************************"
####################################################################################

function Get-PkceCodes {
    $verifier = [System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]]) -replace '[+/=]', ''
    $challenge = [System.Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::ASCII.GetBytes($verifier))) -replace '[+/=]', ''
    return @{verifier=$verifier; challenge=$challenge}
}

if ($Interactive) {
    # Step 1: Get user access token via Auth Code + PKCE
    $pkce = Get-PkceCodes
    $authUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize?client_id=$ClientId&response_type=code&redirect_uri=$FrontendRedirectUri&response_mode=query&scope=$FrontendScope&code_challenge=$($pkce.challenge)&code_challenge_method=S256"
    Write-Host "Open the following URL in your browser and sign in:"
    Write-Host $authUrl
    Start-Process $authUrl
    $authCode = Read-Host "Paste the 'code' parameter from the redirected URL"

    # Step 2: Exchange code for user access token
    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
        -Method Post `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            client_id     = $ClientId
            grant_type    = "authorization_code"
            code          = $authCode
            redirect_uri  = $FrontendRedirectUri
            code_verifier = $pkce.verifier
            scope         = $FrontendScope
        }
    $UserAccessToken = $tokenResponse.access_token
    Write-Host "User access token acquired."
}

# Step 3: OBO flow to get API access token
if (-not $UserAccessToken) {
    $UserAccessToken = Read-Host "Paste a user access token (JWT)"
}

$oboResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -Method Post `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id            = $ClientId
        grant_type           = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        assertion            = $UserAccessToken
        requested_token_use  = "on_behalf_of"
        scope                = $Scope
    }

Write-Output $oboResponse.access_token