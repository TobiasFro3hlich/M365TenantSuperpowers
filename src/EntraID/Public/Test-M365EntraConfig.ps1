function Test-M365EntraConfig {
    <#
    .SYNOPSIS
        Tests an Entra ID config against the current tenant state (drift detection).
    .DESCRIPTION
        Reads the current tenant settings for the specified config type and compares
        them against the desired JSON config. Returns a compliance report.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .PARAMETER Parameters
        Runtime parameters.
    .EXAMPLE
        Test-M365EntraConfig -ConfigName 'ENTRA-AuthorizationPolicy'
    .EXAMPLE
        Test-M365EntraConfig -ConfigName 'ENTRA-SecurityDefaults'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigName,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
    $configPath = Join-Path $moduleRoot "configs/EntraID/$ConfigName.json"
    $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters

    $differences = [System.Collections.Generic.List[object]]::new()
    $configType = $config.metadata.category

    Write-M365Log -Message "Testing Entra ID config: $ConfigName ($configType)" -Level Info

    try {
        switch ($configType) {
            'AuthorizationPolicy' {
                $current = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri 'https://graph.microsoft.com/v1.0/policies/authorizationPolicy' `
                    -Description 'Get authorization policy'

                $desired = $config.settings

                # Compare flat settings
                $flatProps = @('allowedToSignUpEmailBasedSubscriptions', 'allowedToUseSSPR',
                               'allowEmailVerifiedUsersToJoinOrganization', 'blockMsolPowerShell',
                               'allowInvitesFrom', 'guestUserRoleId')

                foreach ($prop in $flatProps) {
                    if ($null -ne $desired[$prop] -and "$($desired[$prop])" -ne "$($current.$prop)") {
                        $differences.Add([PSCustomObject]@{
                            Property     = $prop
                            CurrentValue = $current.$prop
                            DesiredValue = $desired[$prop]
                        })
                    }
                }

                # Compare nested defaultUserRolePermissions
                if ($desired.defaultUserRolePermissions) {
                    foreach ($perm in $desired.defaultUserRolePermissions.Keys) {
                        $currentVal = $current.defaultUserRolePermissions.$perm
                        $desiredVal = $desired.defaultUserRolePermissions[$perm]
                        if ("$desiredVal" -ne "$currentVal") {
                            $differences.Add([PSCustomObject]@{
                                Property     = "defaultUserRolePermissions.$perm"
                                CurrentValue = $currentVal
                                DesiredValue = $desiredVal
                            })
                        }
                    }
                }
            }
            'SecurityDefaults' {
                $current = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy' `
                    -Description 'Get security defaults'

                if ("$($config.settings.isEnabled)" -ne "$($current.isEnabled)") {
                    $differences.Add([PSCustomObject]@{
                        Property     = 'isEnabled'
                        CurrentValue = $current.isEnabled
                        DesiredValue = $config.settings.isEnabled
                    })
                }
            }
            'CrossTenantAccess' {
                $current = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri 'https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/default' `
                    -Description 'Get cross-tenant access defaults'

                $desired = $config.settings
                if ($desired.inboundTrust) {
                    foreach ($key in $desired.inboundTrust.Keys) {
                        if ("$($desired.inboundTrust[$key])" -ne "$($current.inboundTrust.$key)") {
                            $differences.Add([PSCustomObject]@{
                                Property     = "inboundTrust.$key"
                                CurrentValue = $current.inboundTrust.$key
                                DesiredValue = $desired.inboundTrust[$key]
                            })
                        }
                    }
                }
            }
            default {
                Write-M365Log -Message "Drift detection not yet implemented for category: $configType" -Level Warning
            }
        }
    }
    catch {
        Write-M365Log -Message "Failed to test config '$ConfigName': $_" -Level Error
        throw
    }

    $inDesiredState = ($differences.Count -eq 0)

    [PSCustomObject]@{
        ConfigName     = $ConfigName
        Category       = $configType
        InDesiredState = $inDesiredState
        Status         = if ($inDesiredState) { 'Compliant' } else { 'Drift' }
        Differences    = $differences
    }
}
