#!/bin/bash

# Set variables
TENANT_ID="your-tenant-id"
CLIENT_ID="your-client-id"
CLIENT_SECRET="your-client-secret"
CLIENT_ID_SCOPE="downstream-scope-client-id"

curl --location --request GET "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
--header "Content-Type: application/x-www-form-urlencoded" \
--header "Cookie: stsservicecookie=estsfd; x-ms-gateway-slice=estsfd" \
--data-urlencode "grant_type=client_credentials" \
--data-urlencode "client_id=${CLIENT_ID}" \
--data-urlencode "client_secret=${CLIENT_SECRET}" \
--data-urlencode "scope=api://${CLIENT_ID_SCOPE}/.default"
