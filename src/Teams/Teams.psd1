@{
    RootModule    = 'Teams.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'b8c9d0e1-f2a3-4567-1234-678901234567'
    Author        = 'Tobias Froehlich'
    Description   = 'Microsoft Teams policy management for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'Set-M365TeamsMeetingPolicy'
        'Set-M365TeamsMessagingPolicy'
        'Set-M365TeamsCallingPolicy'
        'Set-M365TeamsAppPermissions'
        'Set-M365TeamsFederation'
        'Set-M365TeamsGuestConfig'
        'Set-M365TeamsChannelsPolicy'
        'Set-M365TeamsClientConfig'
        'Get-M365TeamsReport'
        'Import-M365TeamsConfigSet'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes   = @()
            RequiredServices = @('Teams')
        }
    }
}
