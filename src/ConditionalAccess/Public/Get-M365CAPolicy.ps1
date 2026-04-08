function Get-M365CAPolicy {
    <#
    .SYNOPSIS
        Retrieves Conditional Access policies from the tenant.
    .DESCRIPTION
        Gets all or specific CA policies with detailed information including
        conditions, grant controls, and session controls.
    .PARAMETER PolicyId
        Specific policy ID to retrieve.
    .PARAMETER DisplayName
        Filter by display name (supports wildcards via local filtering).
    .PARAMETER State
        Filter by policy state.
    .EXAMPLE
        Get-M365CAPolicy
    .EXAMPLE
        Get-M365CAPolicy -DisplayName 'CA001*'
    .EXAMPLE
        Get-M365CAPolicy -State enabledForReportingButNotEnforced
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PolicyId,

        [Parameter()]
        [string]$DisplayName,

        [Parameter()]
        [ValidateSet('enabled', 'disabled', 'enabledForReportingButNotEnforced')]
        [string]$State
    )

    Assert-M365Connection -Service Graph

    try {
        if ($PolicyId) {
            $policies = @(Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $PolicyId -ErrorAction Stop)
        }
        else {
            $policies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
        }
    }
    catch {
        Write-M365Log -Message "Failed to retrieve CA policies: $_" -Level Error
        throw
    }

    # Apply filters
    if ($DisplayName) {
        $policies = $policies | Where-Object { $_.DisplayName -like $DisplayName }
    }
    if ($State) {
        $policies = $policies | Where-Object { $_.State -eq $State }
    }

    # Build report objects
    foreach ($policy in $policies) {
        $includeUsers = if ($policy.Conditions.Users.IncludeUsers) { $policy.Conditions.Users.IncludeUsers -join ', ' } else { '-' }
        $includeRoles = if ($policy.Conditions.Users.IncludeRoles) { $policy.Conditions.Users.IncludeRoles -join ', ' } else { '-' }
        $grantControls = if ($policy.GrantControls.BuiltInControls) { $policy.GrantControls.BuiltInControls -join ', ' } else { '-' }

        [PSCustomObject]@{
            Id             = $policy.Id
            DisplayName    = $policy.DisplayName
            State          = $policy.State
            IncludeUsers   = $includeUsers
            IncludeRoles   = $includeRoles
            IncludeApps    = ($policy.Conditions.Applications.IncludeApplications -join ', ')
            GrantControls  = $grantControls
            ClientAppTypes = ($policy.Conditions.ClientAppTypes -join ', ')
            CreatedDateTime = $policy.CreatedDateTime
            ModifiedDateTime = $policy.ModifiedDateTime
        }
    }
}
