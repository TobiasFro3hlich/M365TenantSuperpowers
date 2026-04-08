function Invoke-M365EntraGraphRequest {
    <#
    .SYNOPSIS
        Wrapper for Graph API requests with consistent error handling and logging.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'PATCH', 'POST', 'PUT', 'DELETE')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [hashtable]$Body,

        [Parameter()]
        [string]$Description = 'Graph API request'
    )

    try {
        $params = @{
            Method      = $Method
            Uri         = $Uri
            ErrorAction = 'Stop'
        }

        if ($Body -and $Method -ne 'GET') {
            $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
            $params['ContentType'] = 'application/json'
        }

        $response = Invoke-MgGraphRequest @params
        return $response
    }
    catch {
        Write-M365Log -Message "Graph API $Method $Uri failed: $_" -Level Error
        throw
    }
}
