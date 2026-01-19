# PowerShell script to test for email enumeration via JavaScript exposure

# Function to check for exposed email addresses in JavaScript files
function Invoke-EmailEnumerationCheck {
    param (
        [string]$url,
        [string]$emailPattern
    )

    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        if ($response -match $emailPattern) {
            Write-Output "Email addresses found in JavaScript file. Vulnerability exists."
        } else {
            Write-Output "No email addresses found in JavaScript file. Vulnerability does not exist."
        }
    } catch {
        Write-Output "Failed to check for email enumeration. Error: $_"
    }
}

# Example usage
$url = "https://example.com/scripts/app.js"
$emailPattern = "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"

Invoke-EmailEnumerationCheck -url $url -emailPattern $emailPattern