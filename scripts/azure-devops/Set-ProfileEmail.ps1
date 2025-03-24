# Prerequisites: Azure DevOps PAT Token and Azure AD Application Credentials
$devOpsPAT = "your_azure_devops_pat" # Replace with your Azure DevOps Personal Access Token
$tenantId = "your_tenant_id" # Replace with your Azure AD Tenant ID
$clientId = "your_client_id" # Replace with your Azure AD Application (Client) ID
$clientSecret = "your_client_secret" # Replace with your Azure AD Application Client Secret
$organization = "your_organization_name" # Replace with your Azure DevOps organization name

# Get an Azure AD OAuth Token
Write-Output "Retrieving Azure AD token..."
$authBody = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = "https://graph.microsoft.com/"
}
$aadTokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $authBody
$aadToken = $aadTokenResponse.access_token

# Get a list of Azure DevOps users
Write-Output "Retrieving Azure DevOps profiles..."
$headers = @{ Authorization = "Bearer $devOpsPAT" }
$uri = "https://vssps.dev.azure.com/$organization/_apis/graph/users?api-version=7.1-preview.1"
$profilesResponse = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
$profiles = $profilesResponse.value

foreach ($profile in $profiles) {
    $email = $profile.mailAddress
    $userId = $profile.id

    # Check if email ends with "@aacn.org"
    if ($email -like "*@aacn.org") {
        Write-Output "Processing user with email: $email"

        # Retrieve the Azure AD user by email
        $aadUserUri = "https://graph.microsoft.com/v1.0/users/$email"
        $aadHeaders = @{ Authorization = "Bearer $aadToken" }
        $aadUser = Invoke-RestMethod -Method Get -Uri $aadUserUri -Headers $aadHeaders -ErrorAction SilentlyContinue

        if ($aadUser -ne $null) {
            $aadEmail = $aadUser.mail
            $userPrincipalName = $aadUser.userPrincipalName

            # Check if Azure AD email is available and different from the current email
            if ($email -eq $userPrincipalName -and $aadEmail -ne $null -and $aadEmail -ne $email) {
                Write-Output "Updating email for user $userId to $aadEmail"

                # Update the Azure DevOps profile email
                $updateUri = "https://vssps.dev.azure.com/$organization/_apis/profile/profiles/$userId?api-version=7.1-preview.3"
                $updateBody = @{
                    emailAddress = $aadEmail
                } | ConvertTo-Json -Depth 10
                Invoke-RestMethod -Method Patch -Uri $updateUri -Headers $headers -Body $updateBody

                Write-Output "Email updated successfully for user $userId."
            }
        } else {
            Write-Output "Azure AD user not found for email: $email"
        }
    }
}

Write-Output "Script completed."
