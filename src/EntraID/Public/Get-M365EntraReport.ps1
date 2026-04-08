function Get-M365EntraReport {
    <#
    .SYNOPSIS
        Generates a report of current Entra ID tenant settings.
    .DESCRIPTION
        Reads key Entra ID configuration settings and returns them as a structured
        report. Covers authorization policy, auth methods, security defaults,
        named locations, cross-tenant access, group settings, and device registration.
    .PARAMETER Section
        Which section(s) to report on. Default: All.
    .EXAMPLE
        Get-M365EntraReport
    .EXAMPLE
        Get-M365EntraReport -Section AuthorizationPolicy, AuthMethods | Export-M365Report -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('All', 'AuthorizationPolicy', 'AuthMethods', 'SecurityDefaults',
                     'NamedLocations', 'CrossTenantAccess', 'GroupSettings', 'DeviceRegistration')]
        [string[]]$Section = @('All')
    )

    Assert-M365Connection -Service Graph

    $report = [System.Collections.Generic.List[object]]::new()

    $sections = if ('All' -in $Section) {
        @('AuthorizationPolicy', 'AuthMethods', 'SecurityDefaults', 'NamedLocations',
          'CrossTenantAccess', 'GroupSettings', 'DeviceRegistration')
    } else { $Section }

    foreach ($sec in $sections) {
        Write-M365Log -Message "Reading Entra ID settings: $sec" -Level Info

        try {
            switch ($sec) {
                'AuthorizationPolicy' {
                    $data = Invoke-M365EntraGraphRequest -Method GET `
                        -Uri 'https://graph.microsoft.com/v1.0/policies/authorizationPolicy' `
                        -Description 'Get authorization policy'

                    $report.Add([PSCustomObject]@{
                        Section  = 'Authorization Policy'
                        Setting  = 'Allow users to register apps'
                        Value    = $data.defaultUserRolePermissions.allowedToCreateApps
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Authorization Policy'
                        Setting  = 'Allow users to create security groups'
                        Value    = $data.defaultUserRolePermissions.allowedToCreateSecurityGroups
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Authorization Policy'
                        Setting  = 'Block MSOL PowerShell'
                        Value    = $data.blockMsolPowerShell
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Authorization Policy'
                        Setting  = 'Guest invite restrictions'
                        Value    = $data.allowInvitesFrom
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Authorization Policy'
                        Setting  = 'SSPR enabled'
                        Value    = $data.allowedToUseSSPR
                    })
                }
                'AuthMethods' {
                    $data = Invoke-M365EntraGraphRequest -Method GET `
                        -Uri 'https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy' `
                        -Description 'Get auth methods policy'

                    foreach ($method in $data.authenticationMethodConfigurations) {
                        $report.Add([PSCustomObject]@{
                            Section  = 'Authentication Methods'
                            Setting  = $method.id
                            Value    = $method.state
                        })
                    }
                }
                'SecurityDefaults' {
                    $data = Invoke-M365EntraGraphRequest -Method GET `
                        -Uri 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy' `
                        -Description 'Get security defaults'

                    $report.Add([PSCustomObject]@{
                        Section  = 'Security Defaults'
                        Setting  = 'Enabled'
                        Value    = $data.isEnabled
                    })
                }
                'NamedLocations' {
                    $data = Invoke-M365EntraGraphRequest -Method GET `
                        -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' `
                        -Description 'Get named locations'

                    foreach ($loc in $data.value) {
                        $type = if ($loc.'@odata.type' -like '*ip*') { 'IP-based' } else { 'Country-based' }
                        $report.Add([PSCustomObject]@{
                            Section  = 'Named Locations'
                            Setting  = "$($loc.displayName) ($type)"
                            Value    = if ($loc.isTrusted) { 'Trusted' } else { 'Not Trusted' }
                        })
                    }
                }
                'CrossTenantAccess' {
                    $data = Invoke-M365EntraGraphRequest -Method GET `
                        -Uri 'https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/default' `
                        -Description 'Get cross-tenant access defaults'

                    $report.Add([PSCustomObject]@{
                        Section  = 'Cross-Tenant Access'
                        Setting  = 'Inbound trust - MFA'
                        Value    = $data.inboundTrust.isMfaAccepted
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Cross-Tenant Access'
                        Setting  = 'Inbound trust - Compliant devices'
                        Value    = $data.inboundTrust.isCompliantDeviceAccepted
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Cross-Tenant Access'
                        Setting  = 'Inbound trust - Hybrid joined'
                        Value    = $data.inboundTrust.isHybridAzureADJoinedDeviceAccepted
                    })
                }
                'GroupSettings' {
                    $data = Invoke-M365EntraGraphRequest -Method GET `
                        -Uri 'https://graph.microsoft.com/v1.0/settings' `
                        -Description 'Get directory settings'

                    $groupSettings = $data.value | Where-Object { $_.displayName -eq 'Group.Unified' }
                    if ($groupSettings) {
                        foreach ($val in $groupSettings.values) {
                            $report.Add([PSCustomObject]@{
                                Section  = 'Group Settings'
                                Setting  = $val.name
                                Value    = $val.value
                            })
                        }
                    }
                    else {
                        $report.Add([PSCustomObject]@{
                            Section  = 'Group Settings'
                            Setting  = 'Status'
                            Value    = 'Not configured (using defaults)'
                        })
                    }
                }
                'DeviceRegistration' {
                    $data = Invoke-M365EntraGraphRequest -Method GET `
                        -Uri 'https://graph.microsoft.com/v1.0/policies/deviceRegistrationPolicy' `
                        -Description 'Get device registration policy'

                    $report.Add([PSCustomObject]@{
                        Section  = 'Device Registration'
                        Setting  = 'Azure AD Join - allowed'
                        Value    = $data.azureADJoin.isAdminConfigurable
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Device Registration'
                        Setting  = 'MFA for device join'
                        Value    = $data.multiFactorAuthConfiguration
                    })
                    $report.Add([PSCustomObject]@{
                        Section  = 'Device Registration'
                        Setting  = 'User device quota'
                        Value    = $data.userDeviceQuota
                    })
                }
            }
        }
        catch {
            Write-M365Log -Message "Failed to read $sec`: $_" -Level Warning
            $report.Add([PSCustomObject]@{
                Section  = $sec
                Setting  = 'Error'
                Value    = $_.ToString()
            })
        }
    }

    return $report
}
