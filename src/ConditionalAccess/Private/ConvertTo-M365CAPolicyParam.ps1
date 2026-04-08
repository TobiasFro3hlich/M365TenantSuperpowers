function ConvertTo-M365CAPolicyParam {
    <#
    .SYNOPSIS
        Converts a CA policy config hashtable to Graph API-compatible parameters.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    # The 'policy' section maps directly to the Graph API body
    $policyBody = $Config.policy

    # Ensure required fields are present
    if (-not $policyBody.displayName) {
        throw "Policy config is missing 'displayName' in the policy section."
    }

    # Convert to the format expected by New-MgIdentityConditionalAccessPolicy
    $bodyParam = @{
        displayName = $policyBody.displayName
        state       = if ($policyBody.state) { $policyBody.state } else { 'enabledForReportingButNotEnforced' }
    }

    # Conditions
    if ($policyBody.conditions) {
        $bodyParam['conditions'] = @{}

        if ($policyBody.conditions.clientAppTypes) {
            $bodyParam.conditions['clientAppTypes'] = [string[]]$policyBody.conditions.clientAppTypes
        }

        if ($policyBody.conditions.applications) {
            $bodyParam.conditions['applications'] = @{}
            if ($policyBody.conditions.applications.includeApplications) {
                $bodyParam.conditions.applications['includeApplications'] = [string[]]$policyBody.conditions.applications.includeApplications
            }
            if ($policyBody.conditions.applications.excludeApplications) {
                $bodyParam.conditions.applications['excludeApplications'] = [string[]]$policyBody.conditions.applications.excludeApplications
            }
        }

        if ($policyBody.conditions.users) {
            $bodyParam.conditions['users'] = @{}
            $userProps = @('includeUsers', 'excludeUsers', 'includeGroups', 'excludeGroups', 'includeRoles', 'excludeRoles')
            foreach ($prop in $userProps) {
                if ($policyBody.conditions.users.$prop) {
                    $bodyParam.conditions.users[$prop] = [string[]]$policyBody.conditions.users.$prop
                }
            }
        }

        if ($policyBody.conditions.platforms) {
            $bodyParam.conditions['platforms'] = @{}
            if ($policyBody.conditions.platforms.includePlatforms) {
                $bodyParam.conditions.platforms['includePlatforms'] = [string[]]$policyBody.conditions.platforms.includePlatforms
            }
            if ($policyBody.conditions.platforms.excludePlatforms) {
                $bodyParam.conditions.platforms['excludePlatforms'] = [string[]]$policyBody.conditions.platforms.excludePlatforms
            }
        }

        if ($policyBody.conditions.locations) {
            $bodyParam.conditions['locations'] = @{}
            if ($policyBody.conditions.locations.includeLocations) {
                $bodyParam.conditions.locations['includeLocations'] = [string[]]$policyBody.conditions.locations.includeLocations
            }
            if ($policyBody.conditions.locations.excludeLocations) {
                $bodyParam.conditions.locations['excludeLocations'] = [string[]]$policyBody.conditions.locations.excludeLocations
            }
        }

        if ($policyBody.conditions.signInRiskLevels) {
            $bodyParam.conditions['signInRiskLevels'] = [string[]]$policyBody.conditions.signInRiskLevels
        }

        if ($policyBody.conditions.userRiskLevels) {
            $bodyParam.conditions['userRiskLevels'] = [string[]]$policyBody.conditions.userRiskLevels
        }

        if ($policyBody.conditions.deviceStates) {
            $bodyParam.conditions['devices'] = $policyBody.conditions.deviceStates
        }
    }

    # Grant Controls
    if ($policyBody.grantControls) {
        $bodyParam['grantControls'] = @{
            operator = if ($policyBody.grantControls.operator) { $policyBody.grantControls.operator } else { 'OR' }
        }
        if ($policyBody.grantControls.builtInControls) {
            $bodyParam.grantControls['builtInControls'] = [string[]]$policyBody.grantControls.builtInControls
        }
        if ($policyBody.grantControls.customAuthenticationFactors) {
            $bodyParam.grantControls['customAuthenticationFactors'] = [string[]]$policyBody.grantControls.customAuthenticationFactors
        }
        if ($policyBody.grantControls.termsOfUse) {
            $bodyParam.grantControls['termsOfUse'] = [string[]]$policyBody.grantControls.termsOfUse
        }
    }

    # Session Controls
    if ($policyBody.sessionControls) {
        $bodyParam['sessionControls'] = @{}
        if ($policyBody.sessionControls.signInFrequency) {
            $bodyParam.sessionControls['signInFrequency'] = $policyBody.sessionControls.signInFrequency
        }
        if ($policyBody.sessionControls.persistentBrowser) {
            $bodyParam.sessionControls['persistentBrowser'] = $policyBody.sessionControls.persistentBrowser
        }
        if ($policyBody.sessionControls.applicationEnforcedRestrictions) {
            $bodyParam.sessionControls['applicationEnforcedRestrictions'] = $policyBody.sessionControls.applicationEnforcedRestrictions
        }
        if ($policyBody.sessionControls.cloudAppSecurity) {
            $bodyParam.sessionControls['cloudAppSecurity'] = $policyBody.sessionControls.cloudAppSecurity
        }
    }

    return $bodyParam
}
