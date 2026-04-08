function Invoke-M365IntuneGraphRequest {
    <#
    .SYNOPSIS
        Wrapper for Intune Graph API requests with consistent error handling.
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
        [string]$Description = 'Intune Graph API request'
    )

    try {
        $params = @{
            Method      = $Method
            Uri         = $Uri
            ErrorAction = 'Stop'
        }

        if ($Body -and $Method -ne 'GET') {
            $params['Body'] = ($Body | ConvertTo-Json -Depth 20)
            $params['ContentType'] = 'application/json'
        }

        $response = Invoke-MgGraphRequest @params
        return $response
    }
    catch {
        Write-M365Log -Message "Intune API $Method $Uri failed: $_" -Level Error
        throw
    }
}
