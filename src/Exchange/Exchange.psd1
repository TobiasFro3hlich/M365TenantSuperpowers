@{
    RootModule    = 'Exchange.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'f6a7b8c9-d0e1-2345-f012-456789012345'
    Author        = 'Tobias Froehlich'
    Description   = 'Exchange Online configuration management for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'Set-M365EXOOrganizationConfig'
        'Set-M365EXODkim'
        'Set-M365EXOTransportRules'
        'Set-M365EXOExternalTag'
        'Set-M365EXOOwaPolicy'
        'Set-M365EXOMobilePolicy'
        'Set-M365EXOSharingPolicy'
        'Set-M365EXORemoteDomain'
        'Get-M365EXOReport'
        'Import-M365EXOConfigSet'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes   = @()
            RequiredServices = @('ExchangeOnline')
        }
    }
}
