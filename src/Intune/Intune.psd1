@{
    RootModule    = 'Intune.psm1'
    ModuleVersion = '0.1.0'
    GUID          = 'd0e1f2a3-b4c5-6789-3456-890123456789'
    Author        = 'Tobias Froehlich'
    Description   = 'Microsoft Intune / Endpoint Manager configuration for M365TenantSuperpowers.'

    FunctionsToExport = @(
        'Set-M365IntuneComplianceSettings'
        'New-M365IntuneCompliancePolicy'
        'Set-M365IntuneEnrollmentRestriction'
        'New-M365IntuneAppProtection'
        'Get-M365IntuneReport'
        'Import-M365IntuneConfigSet'
    )

    CmdletsToExport  = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        M365TenantSuperpowers = @{
            RequiredScopes = @(
                'DeviceManagementConfiguration.ReadWrite.All'
                'DeviceManagementApps.ReadWrite.All'
                'DeviceManagementManagedDevices.ReadWrite.All'
                'DeviceManagementServiceConfig.ReadWrite.All'
            )
            RequiredServices = @('Graph')
        }
    }
}
