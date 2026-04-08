function Disconnect-M365Tenant {
    <#
    .SYNOPSIS
        Disconnects from all connected Microsoft 365 services.
    .DESCRIPTION
        Cleanly disconnects from Graph, Exchange Online, SharePoint, and Teams.
    .PARAMETER Services
        Specific services to disconnect. If omitted, disconnects all.
    .EXAMPLE
        Disconnect-M365Tenant
    .EXAMPLE
        Disconnect-M365Tenant -Services ExchangeOnline
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Graph', 'ExchangeOnline', 'SharePoint', 'Teams')]
        [string[]]$Services
    )

    $rootModule = Get-Module 'M365TenantSuperpowers'
    if (-not $rootModule) { return }

    $connected = & $rootModule { $script:M365Connection.ConnectedServices }
    if (-not $Services) {
        $Services = [string[]]$connected
    }

    foreach ($service in $Services) {
        if ($service -notin $connected) { continue }

        Write-M365Log -Message "Disconnecting from $service..." -Level Info

        try {
            switch ($service) {
                'Graph'          { Disconnect-MgGraph -ErrorAction SilentlyContinue }
                'ExchangeOnline' { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue }
                'SharePoint'     { Disconnect-PnPOnline -ErrorAction SilentlyContinue }
                'Teams'          { Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue }
            }
            & $rootModule { $script:M365Connection.ConnectedServices.Remove($args[0]) } $service
            Write-M365Log -Message "Disconnected from $service" -Level Info
        }
        catch {
            Write-M365Log -Message "Error disconnecting from $service`: $_" -Level Warning
        }
    }

    # Reset connection state if nothing left
    $remaining = & $rootModule { $script:M365Connection.ConnectedServices }
    if ($remaining.Count -eq 0) {
        & $rootModule {
            $script:M365Connection.TenantId = $null
            $script:M365Connection.GraphContext = $null
            $script:M365Connection.Timestamp = $null
        }
        Write-M365Log -Message "All services disconnected. Connection state cleared." -Level Info
    }
}
