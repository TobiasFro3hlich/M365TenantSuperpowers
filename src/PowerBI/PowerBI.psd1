@{
    RootModule    = 'PowerBI.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'e1f2a3b4-c5d6-7890-4567-901234567890'
    Author        = 'Tobias Froehlich'
    Description   = 'Power BI / Microsoft Fabric tenant settings for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'Set-M365PowerBITenantSettings'
        'Get-M365PowerBIReport'
        'Import-M365PowerBIConfigSet'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes   = @('Tenant.Read.All', 'Tenant.ReadWrite.All')
            RequiredServices = @('Graph')
        }
    }
}
