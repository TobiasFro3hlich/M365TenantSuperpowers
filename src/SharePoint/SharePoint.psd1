@{
    RootModule    = 'SharePoint.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'a7b8c9d0-e1f2-3456-0123-567890123456'
    Author        = 'Tobias Froehlich'
    Description   = 'SharePoint Online configuration management for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'Set-M365SPOTenantSettings'
        'Set-M365SPOSharing'
        'Set-M365SPOAccessControl'
        'Get-M365SPOReport'
        'Import-M365SPOConfigSet'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes   = @('SharePointTenantSettings.ReadWrite.All')
            RequiredServices = @('SharePoint')
        }
    }
}
