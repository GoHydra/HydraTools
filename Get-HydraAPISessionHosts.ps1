#Requires -Version 5.1

# This sample script gets all session host information, including host pool name, host pool ID, and session host IDs and names. This can especially be handy for feeding into other scripts and actions.
# The 00000000-0000-0000-0000-000000000000 represents a wildcard for the host pool so we query all session hosts. 
# The * represents a wildcard for all users, so we get both assigned, pooled, and unassigned hosts.

# For ApiKey variable, populate as needed. The example here pulls the string from a .env file sitting in the same path as script. 

$BaseUrl = 'https://yourhydraURL.azurewebsites.net'
$ApiKey = (Get-Content -LiteralPath (Join-Path $PSScriptRoot '.env') -Raw -ErrorAction Stop).Trim()
$Method = 'GET'  # GET or POST
$Endpoint = '/rest/hostpools/00000000-0000-0000-0000-000000000000/users/*/sessionhosts'

# For a JSON POST, set $Body = @{ VmSize = 'Standard_D8as_v5' } | ConvertTo-Json
# For a plain-text POST, set $Body to the text and $ContentType to 'text/plain'.
$Body = $null
$ContentType = 'application/json'

$request = @{
    Uri = $BaseUrl.TrimEnd('/') + '/' + $Endpoint.TrimStart('/')
    Method = $Method
    Headers = @{ Authorization = "SharedKey $ApiKey" }
    UseBasicParsing = $true
    MaximumRedirection = 0
    TimeoutSec = 30
    ErrorAction = 'Stop'
}

if ($Method -eq 'POST' -and $null -ne $Body) {
    $request.Body = $Body
    $request.ContentType = $ContentType
}

Invoke-RestMethod @request
