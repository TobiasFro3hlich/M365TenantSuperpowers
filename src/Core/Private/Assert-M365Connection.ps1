function Assert-M365Connection {
    <#
    .SYNOPSIS
        Validates that a required service is connected. Throws if not.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Graph', 'ExchangeOnline', 'SharePoint', 'Teams')]
        [string]$Service
    )

    # Access the root module's connection state
    $rootModule = Get-Module 'M365TenantSuperpowers'
    if (-not $rootModule) {
        throw "M365TenantSuperpowers module is not loaded. Run: Import-Module M365TenantSuperpowers"
    }

    $connection = & $rootModule { $script:M365Connection }

    if (-not $connection.ConnectedServices -or $Service -notin $connection.ConnectedServices) {
        throw "Service '$Service' is not connected. Run: Connect-M365Tenant -Services '$Service'"
    }
}
