@{
    RootModule    = 'ConditionalAccess.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'c3d4e5f6-a7b8-9012-cdef-123456789012'
    Author        = 'Tobias Froehlich'
    Description   = 'Conditional Access policy management for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'New-M365CAPolicy'
        'Get-M365CAPolicy'
        'Set-M365CAPolicy'
        'Remove-M365CAPolicy'
        'Test-M365CAPolicy'
        'Import-M365CAPolicySet'
        'Export-M365CAPolicySet'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes   = @(
                'Policy.Read.All'
                'Policy.ReadWrite.ConditionalAccess'
                'Application.Read.All'
                'Directory.Read.All'
            )
            RequiredServices = @('Graph')
        }
    }
}
