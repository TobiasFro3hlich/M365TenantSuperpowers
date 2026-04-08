@{
    RootModule    = 'Core.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'b2c3d4e5-f6a7-8901-bcde-f12345678901'
    Author        = 'Tobias Froehlich'
    Description   = 'Core module for M365TenantSuperpowers: authentication, logging, reporting, prerequisites.'

    FunctionsToExport = @(
        'Connect-M365Tenant'
        'Disconnect-M365Tenant'
        'Get-M365TenantConnection'
        'Test-M365Prerequisites'
        'Export-M365Report'
        'Write-M365Log'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes   = @('User.Read.All', 'Organization.Read.All')
            RequiredServices = @('Graph')
        }
    }
}
