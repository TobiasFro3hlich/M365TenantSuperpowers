@{
    RootModule        = 'M365TenantSuperpowers.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Tobias Froehlich'
    CompanyName       = 'M365TenantSuperpowers'
    Copyright         = '(c) 2026 Tobias Froehlich. All rights reserved.'
    Description       = 'Modular toolkit for Microsoft 365 tenant setup, configuration, and governance.'

    PowerShellVersion = '7.2'

    RequiredModules   = @(
        @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }
        @{ ModuleName = 'Microsoft.Graph.Identity.SignIns'; ModuleVersion = '2.0.0' }
    )

    NestedModules     = @(
        'src/Core/Core.psm1'
        'src/ConditionalAccess/ConditionalAccess.psm1'
        'src/EntraID/EntraID.psm1'
        'src/Defender/Defender.psm1'
        'src/Exchange/Exchange.psm1'
        'src/SharePoint/SharePoint.psm1'
        'src/Teams/Teams.psm1'
        'src/Security/Security.psm1'
        'src/Intune/Intune.psm1'
        'src/PowerBI/PowerBI.psm1'
    )

    FunctionsToExport = @(
        # Core
        'Connect-M365Tenant'
        'Disconnect-M365Tenant'
        'Get-M365TenantConnection'
        'Test-M365Prerequisites'
        'Export-M365Report'
        'Write-M365Log'
        'Invoke-M365ComplianceAudit'

        # Conditional Access
        'New-M365CAPolicy'
        'Get-M365CAPolicy'
        'Set-M365CAPolicy'
        'Remove-M365CAPolicy'
        'Test-M365CAPolicy'
        'Import-M365CAPolicySet'
        'Export-M365CAPolicySet'

        # Entra ID
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
        'Set-M365EntraPIMRoleSettings'
        'Get-M365EntraPIMReport'
        'New-M365EntraDynamicGuestGroup'
        'New-M365EntraAccessReview'
        'Get-M365EntraReport'
        'Test-M365EntraConfig'
        'Import-M365EntraConfigSet'

        # Defender for Office 365
        'Set-M365DefenderAntiPhish'
        'Set-M365DefenderAntiSpam'
        'Set-M365DefenderAntiMalware'
        'Set-M365DefenderSafeLinks'
        'Set-M365DefenderSafeAttachments'
        'Set-M365DefenderGlobal'
        'Get-M365DefenderReport'
        'Import-M365DefenderConfigSet'

        # Exchange Online
        'Set-M365EXOOrganizationConfig'
        'Set-M365EXODkim'
        'Set-M365EXOTransportRules'
        'Set-M365EXOExternalTag'
        'Set-M365EXOOwaPolicy'
        'Set-M365EXOMobilePolicy'
        'Set-M365EXOSharingPolicy'
        'Set-M365EXORemoteDomain'
        'Set-M365EXOSharedMailboxBlock'
        'Set-M365EXOMailboxAuditActions'
        'Get-M365EXOReport'
        'Import-M365EXOConfigSet'

        # SharePoint Online
        'Set-M365SPOTenantSettings'
        'Set-M365SPOSharing'
        'Set-M365SPOAccessControl'
        'Get-M365SPOReport'
        'Import-M365SPOConfigSet'

        # Microsoft Teams
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

        # Security & Compliance (Purview)
        'New-M365DLPPolicy'
        'New-M365SensitivityLabel'
        'Set-M365LabelPolicy'
        'New-M365RetentionPolicy'
        'Set-M365AuditRetention'
        'Set-M365AlertPolicy'
        'Get-M365SecurityReport'
        'Import-M365SecurityConfigSet'

        # Intune / Endpoint Manager
        'Set-M365IntuneComplianceSettings'
        'New-M365IntuneCompliancePolicy'
        'Set-M365IntuneEnrollmentRestriction'
        'New-M365IntuneAppProtection'
        'Get-M365IntuneReport'
        'Import-M365IntuneConfigSet'

        # Power BI / Microsoft Fabric
        'Set-M365PowerBITenantSettings'
        'Get-M365PowerBIReport'
        'Import-M365PowerBIConfigSet'

        # Root
        'Invoke-M365Profile'
    )

    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('Microsoft365', 'M365', 'Tenant', 'ConditionalAccess', 'EntraID', 'Defender', 'Exchange', 'SharePoint', 'Teams', 'Identity', 'Governance', 'Security')
            LicenseUri = ''
            ProjectUri = ''
        }
    }
}
