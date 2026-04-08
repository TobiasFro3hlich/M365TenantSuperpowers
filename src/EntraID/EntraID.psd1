@{
    RootModule    = 'EntraID.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'd4e5f6a7-b8c9-0123-def0-234567890123'
    Author        = 'Tobias Froehlich'
    Description   = 'Entra ID identity and access management for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'Set-M365EntraAuthorizationPolicy'
        'Set-M365EntraAuthMethodPolicy'
        'Set-M365EntraSecurityDefaults'
        'Set-M365EntraNamedLocations'
        'Set-M365EntraAdminConsent'
        'Set-M365EntraCrossTenantDefault'
        'Set-M365EntraPasswordProtection'
        'Set-M365EntraGroupSettings'
        'Set-M365EntraGroupLifecycle'
        'Set-M365EntraDeviceRegistration'
        'Get-M365EntraReport'
        'Test-M365EntraConfig'
        'Import-M365EntraConfigSet'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes = @(
                'Policy.Read.All'
                'Policy.ReadWrite.Authorization'
                'Policy.ReadWrite.AuthenticationMethod'
                'Policy.ReadWrite.AuthenticationFlows'
                'Policy.ReadWrite.CrossTenantAccess'
                'Directory.Read.All'
                'Directory.ReadWrite.All'
                'UserAuthenticationMethod.Read.All'
                'Organization.ReadWrite.All'
            )
            RequiredServices = @('Graph')
        }
    }
}
