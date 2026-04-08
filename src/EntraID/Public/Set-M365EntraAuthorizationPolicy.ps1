function Set-M365EntraAuthorizationPolicy {
    <#
    .SYNOPSIS
        Configures the Entra ID authorization policy (default user permissions, guest settings).
    .DESCRIPTION
        Sets tenant-wide authorization settings including whether users can register apps,
        create security groups, read other users, invite guests, and more. This is one of
        the most critical tenant baseline settings.
    .PARAMETER ConfigName
        Name of the JSON config (without .json) from configs/EntraID/.
    .PARAMETER ConfigPath
        Full path to a custom JSON config file.
    .PARAMETER Parameters
        Runtime parameters hashtable.
    .EXAMPLE
        Set-M365EntraAuthorizationPolicy -ConfigName 'ENTRA-AuthorizationPolicy'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$ConfigName,

        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [string]$ConfigPath,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/EntraID/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    # Read current state
    $current = Invoke-M365EntraGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/policies/authorizationPolicy' -Description 'Get authorization policy'

    if ($PSCmdlet.ShouldProcess('Authorization Policy', 'Update Entra ID authorization settings')) {
        Write-M365Log -Message "Applying authorization policy settings..." -Level Info

        $body = @{}

        # Map config settings to Graph API properties
        $settingsMap = @{
            'allowedToSignUpEmailBasedSubscriptions'      = 'allowedToSignUpEmailBasedSubscriptions'
            'allowedToUseSSPR'                            = 'allowedToUseSSPR'
            'allowEmailVerifiedUsersToJoinOrganization'   = 'allowEmailVerifiedUsersToJoinOrganization'
            'blockMsolPowerShell'                         = 'blockMsolPowerShell'
            'allowInvitesFrom'                            = 'allowInvitesFrom'
            'guestUserRoleId'                             = 'guestUserRoleId'
        }

        foreach ($key in $settingsMap.Keys) {
            if ($null -ne $desired[$key]) {
                $body[$settingsMap[$key]] = $desired[$key]
            }
        }

        # Handle nested defaultUserRolePermissions
        if ($desired.defaultUserRolePermissions) {
            $body['defaultUserRolePermissions'] = @{}
            $rolePerms = @(
                'allowedToCreateApps'
                'allowedToCreateSecurityGroups'
                'allowedToCreateTenants'
                'allowedToReadBitlockerKeysForOwnedDevice'
                'allowedToReadOtherUsers'
            )
            foreach ($perm in $rolePerms) {
                if ($null -ne $desired.defaultUserRolePermissions[$perm]) {
                    $body.defaultUserRolePermissions[$perm] = $desired.defaultUserRolePermissions[$perm]
                }
            }
        }

        try {
            Invoke-M365EntraGraphRequest -Method PATCH `
                -Uri 'https://graph.microsoft.com/v1.0/policies/authorizationPolicy' `
                -Body $body `
                -Description 'Update authorization policy'

            Write-M365Log -Message "Authorization policy updated successfully." -Level Info

            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update authorization policy: $_" -Level Error
            throw
        }
    }
}
