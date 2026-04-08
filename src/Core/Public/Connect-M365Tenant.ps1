function Connect-M365Tenant {
    <#
    .SYNOPSIS
        Connects to Microsoft 365 services for tenant management.
    .DESCRIPTION
        Single entry point for authenticating to Microsoft Graph, Exchange Online,
        SharePoint Online, and Teams. Aggregates required scopes from all loaded
        sub-modules automatically.
    .PARAMETER TenantId
        The tenant ID (GUID or domain) to connect to.
    .PARAMETER Services
        Which services to connect. Default: Graph.
        Valid values: Graph, ExchangeOnline, SharePoint, Teams
    .PARAMETER GraphScopes
        Additional Graph scopes beyond those required by loaded sub-modules.
    .PARAMETER SharePointAdminUrl
        Required when connecting to SharePoint. Example: https://contoso-admin.sharepoint.com
    .EXAMPLE
        Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services Graph, ExchangeOnline
    .EXAMPLE
        Connect-M365Tenant -TenantId '12345678-...' -Services Graph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId,

        [Parameter()]
        [ValidateSet('Graph', 'ExchangeOnline', 'SharePoint', 'Teams')]
        [string[]]$Services = @('Graph'),

        [Parameter()]
        [string[]]$GraphScopes = @(),

        [Parameter()]
        [string]$SharePointAdminUrl
    )

    # Access root module state
    $rootModule = Get-Module 'M365TenantSuperpowers'
    if (-not $rootModule) {
        throw "M365TenantSuperpowers module is not loaded. Run: Import-Module M365TenantSuperpowers"
    }

    # Connect to each requested service
    foreach ($service in $Services) {
        Write-M365Log -Message "Connecting to $service..." -Level Info

        switch ($service) {
            'Graph' {
                $scopes = Resolve-M365Scope -AdditionalScopes $GraphScopes
                Write-M365Log -Message "Requesting Graph scopes: $($scopes -join ', ')" -Level Debug

                try {
                    Connect-MgGraph -TenantId $TenantId -Scopes $scopes -NoWelcome -ErrorAction Stop
                    $context = Get-MgContext
                    & $rootModule {
                        $script:M365Connection.GraphContext = $args[0]
                        $script:M365Connection.TenantId = $args[1]
                    } $context $TenantId

                    Write-M365Log -Message "Connected to Graph as: $($context.Account)" -Level Info
                }
                catch {
                    Write-M365Log -Message "Failed to connect to Graph: $_" -Level Error
                    throw
                }
            }
            'ExchangeOnline' {
                try {
                    $exoParams = @{ ShowBanner = $false }
                    if ($TenantId -match '^[0-9a-f]{8}-') {
                        # GUID format — need to use Organization parameter
                        $exoParams['Organization'] = $TenantId
                    }
                    else {
                        $exoParams['Organization'] = $TenantId
                    }
                    Connect-ExchangeOnline @exoParams -ErrorAction Stop
                    Write-M365Log -Message "Connected to Exchange Online" -Level Info
                }
                catch {
                    Write-M365Log -Message "Failed to connect to Exchange Online: $_" -Level Error
                    throw
                }
            }
            'SharePoint' {
                if (-not $SharePointAdminUrl) {
                    throw "SharePointAdminUrl is required when connecting to SharePoint. Example: https://contoso-admin.sharepoint.com"
                }
                try {
                    Connect-PnPOnline -Url $SharePointAdminUrl -Interactive -ErrorAction Stop
                    Write-M365Log -Message "Connected to SharePoint: $SharePointAdminUrl" -Level Info
                }
                catch {
                    Write-M365Log -Message "Failed to connect to SharePoint: $_" -Level Error
                    throw
                }
            }
            'Teams' {
                try {
                    Connect-MicrosoftTeams -TenantId $TenantId -ErrorAction Stop
                    Write-M365Log -Message "Connected to Teams" -Level Info
                }
                catch {
                    Write-M365Log -Message "Failed to connect to Teams: $_" -Level Error
                    throw
                }
            }
        }

        # Track connected service
        & $rootModule {
            if ($args[0] -notin $script:M365Connection.ConnectedServices) {
                $script:M365Connection.ConnectedServices.Add($args[0])
            }
        } $service
    }

    # Update timestamp
    & $rootModule { $script:M365Connection.Timestamp = Get-Date }

    Write-M365Log -Message "Connected services: $((& $rootModule { $script:M365Connection.ConnectedServices }) -join ', ')" -Level Info
}
