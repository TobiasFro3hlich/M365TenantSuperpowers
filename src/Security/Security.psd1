@{
    RootModule    = 'Security.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'c9d0e1f2-a3b4-5678-2345-789012345678'
    Author        = 'Tobias Froehlich'
    Description   = 'Microsoft Purview security and compliance management for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'New-M365DLPPolicy'
        'New-M365SensitivityLabel'
        'Set-M365LabelPolicy'
        'New-M365RetentionPolicy'
        'Set-M365AuditRetention'
        'Set-M365AlertPolicy'
        'Get-M365SecurityReport'
        'Import-M365SecurityConfigSet'
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
