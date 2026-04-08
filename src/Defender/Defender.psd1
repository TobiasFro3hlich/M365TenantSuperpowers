@{
    RootModule    = 'Defender.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'e5f6a7b8-c9d0-1234-ef01-345678901234'
    Author        = 'Tobias Froehlich'
    Description   = 'Microsoft Defender for Office 365 management for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'Set-M365DefenderAntiPhish'
        'Set-M365DefenderAntiSpam'
        'Set-M365DefenderAntiMalware'
        'Set-M365DefenderSafeLinks'
        'Set-M365DefenderSafeAttachments'
        'Set-M365DefenderGlobal'
        'Get-M365DefenderReport'
        'Import-M365DefenderConfigSet'
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
