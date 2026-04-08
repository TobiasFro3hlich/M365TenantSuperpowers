function Get-M365TenantConnection {
    <#
    .SYNOPSIS
        Returns the current M365 connection state.
    .DESCRIPTION
        Shows which services are connected, the tenant ID, and connection timestamp.
    .EXAMPLE
        Get-M365TenantConnection
    #>
    [CmdletBinding()]
    param()

    $rootModule = Get-Module 'M365TenantSuperpowers'
    if (-not $rootModule) {
        Write-Warning "M365TenantSuperpowers module is not loaded."
        return
    }

    $connection = & $rootModule { $script:M365Connection }

    [PSCustomObject]@{
        TenantId          = $connection.TenantId
        ConnectedServices = [string[]]$connection.ConnectedServices
        Account           = if ($connection.GraphContext) { $connection.GraphContext.Account } else { $null }
        Timestamp         = $connection.Timestamp
        IsConnected       = ($connection.ConnectedServices.Count -gt 0)
    }
}
