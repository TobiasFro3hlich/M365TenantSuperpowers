function Export-M365CAPolicySet {
    <#
    .SYNOPSIS
        Exports all CA policies from the tenant to JSON config files.
    .DESCRIPTION
        Reads all Conditional Access policies from the connected tenant and saves
        them as JSON files compatible with the M365TenantSuperpowers config format.
        Useful for snapshotting a tenant's CA configuration or migration.
    .PARAMETER OutputPath
        Directory to save exported JSON files. Default: ./export/ConditionalAccess
    .PARAMETER Prefix
        Prefix for exported file names. Default: 'CA-Export'
    .EXAMPLE
        Export-M365CAPolicySet
    .EXAMPLE
        Export-M365CAPolicySet -OutputPath './backup/ca-policies' -Prefix 'PROD'
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$OutputPath = './export/ConditionalAccess',

        [Parameter()]
        [string]$Prefix = 'CA-Export'
    )

    Assert-M365Connection -Service Graph

    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    $policies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop

    if (-not $policies) {
        Write-M365Log -Message "No CA policies found in tenant." -Level Warning
        return
    }

    Write-M365Log -Message "Exporting $($policies.Count) CA policies..." -Level Info

    $exported = [System.Collections.Generic.List[object]]::new()

    foreach ($policy in $policies) {
        $safeName = $policy.DisplayName -replace '[^\w\-\s]', '' -replace '\s+', '-'
        $fileName = "$Prefix-$safeName.json"
        $filePath = Join-Path $OutputPath $fileName

        # Build config structure
        $config = @{
            metadata = @{
                id          = $policy.Id
                name        = $policy.DisplayName
                description = "Exported from tenant on $(Get-Date -Format 'yyyy-MM-dd')"
                severity    = 'Unknown'
                category    = 'Exported'
                tags        = @('export')
            }
            policy = @{
                displayName    = $policy.DisplayName
                state          = $policy.State
                conditions     = @{
                    clientAppTypes = $policy.Conditions.ClientAppTypes
                    applications   = @{
                        includeApplications = $policy.Conditions.Applications.IncludeApplications
                        excludeApplications = $policy.Conditions.Applications.ExcludeApplications
                    }
                    users = @{
                        includeUsers  = $policy.Conditions.Users.IncludeUsers
                        excludeUsers  = $policy.Conditions.Users.ExcludeUsers
                        includeGroups = $policy.Conditions.Users.IncludeGroups
                        excludeGroups = $policy.Conditions.Users.ExcludeGroups
                        includeRoles  = $policy.Conditions.Users.IncludeRoles
                        excludeRoles  = $policy.Conditions.Users.ExcludeRoles
                    }
                }
            }
            parameters = @{}
        }

        # Add grant controls if present
        if ($policy.GrantControls) {
            $config.policy['grantControls'] = @{
                operator        = $policy.GrantControls.Operator
                builtInControls = $policy.GrantControls.BuiltInControls
            }
        }

        # Add session controls if present
        if ($policy.SessionControls) {
            $config.policy['sessionControls'] = @{}
            if ($policy.SessionControls.SignInFrequency) {
                $config.policy.sessionControls['signInFrequency'] = @{
                    isEnabled = $policy.SessionControls.SignInFrequency.IsEnabled
                    type      = $policy.SessionControls.SignInFrequency.Type
                    value     = $policy.SessionControls.SignInFrequency.Value
                }
            }
            if ($policy.SessionControls.PersistentBrowser) {
                $config.policy.sessionControls['persistentBrowser'] = @{
                    isEnabled = $policy.SessionControls.PersistentBrowser.IsEnabled
                    mode      = $policy.SessionControls.PersistentBrowser.Mode
                }
            }
        }

        # Add locations if present
        if ($policy.Conditions.Locations) {
            $config.policy.conditions['locations'] = @{
                includeLocations = $policy.Conditions.Locations.IncludeLocations
                excludeLocations = $policy.Conditions.Locations.ExcludeLocations
            }
        }

        # Add risk levels if present
        if ($policy.Conditions.SignInRiskLevels) {
            $config.policy.conditions['signInRiskLevels'] = $policy.Conditions.SignInRiskLevels
        }
        if ($policy.Conditions.UserRiskLevels) {
            $config.policy.conditions['userRiskLevels'] = $policy.Conditions.UserRiskLevels
        }

        # Add platforms if present
        if ($policy.Conditions.Platforms) {
            $config.policy.conditions['platforms'] = @{
                includePlatforms = $policy.Conditions.Platforms.IncludePlatforms
                excludePlatforms = $policy.Conditions.Platforms.ExcludePlatforms
            }
        }

        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Encoding UTF8

        $exported.Add([PSCustomObject]@{
            PolicyName = $policy.DisplayName
            PolicyId   = $policy.Id
            FilePath   = $filePath
            State      = $policy.State
        })

        Write-M365Log -Message "Exported: $($policy.DisplayName) -> $fileName" -Level Info
    }

    Write-M365Log -Message "Exported $($exported.Count) CA policies to: $OutputPath" -Level Info

    return $exported
}
