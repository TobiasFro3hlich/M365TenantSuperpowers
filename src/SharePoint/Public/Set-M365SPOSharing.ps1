function Set-M365SPOSharing {
    <#
    .SYNOPSIS
        Configures SharePoint Online external sharing settings.
    .DESCRIPTION
        Sets the tenant-level sharing capability, link defaults, guest link expiration,
        domain allow/block lists, and resharing controls. This is one of the most
        critical security decisions for SharePoint.
    .PARAMETER ConfigName
        Name of the JSON config from configs/SharePoint/.
    .EXAMPLE
        Set-M365SPOSharing -ConfigName 'SPO-SharingSettings'
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

    Assert-M365Connection -Service SharePoint

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/SharePoint/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('SPO Sharing Settings', 'Update sharing configuration')) {
        Write-M365Log -Message "Applying SPO sharing settings..." -Level Info

        $params = @{}
        $props = @(
            'SharingCapability', 'DefaultSharingLinkType', 'DefaultLinkPermission',
            'RequireAcceptingAccountMatchInvitedAccount', 'PreventExternalUsersFromResharing',
            'FileAnonymousLinkType', 'FolderAnonymousLinkType',
            'RequireAnonymousLinksExpireInDays', 'ExternalUserExpirationRequired',
            'ExternalUserExpireInDays',
            'ShowPeoplePickerSuggestionsForGuestUsers', 'ShowAllUsersClaim',
            'NotifyOwnersWhenItemsReshared', 'NotifyOwnersWhenInvitationsAccepted',
            'EnableAzureADB2BIntegration'
        )

        foreach ($prop in $props) {
            if ($null -ne $desired[$prop]) {
                $params[$prop] = $desired[$prop]
            }
        }

        # Domain restriction
        if ($desired.SharingDomainRestrictionMode) {
            $params['SharingDomainRestrictionMode'] = $desired.SharingDomainRestrictionMode
            if ($desired.SharingAllowedDomainList) {
                $params['SharingAllowedDomainList'] = $desired.SharingAllowedDomainList
            }
            if ($desired.SharingBlockedDomainList) {
                $params['SharingBlockedDomainList'] = $desired.SharingBlockedDomainList
            }
        }

        # OneDrive sharing
        if ($null -ne $desired.OneDriveSharingCapability) {
            $params['OneDriveSharingCapability'] = $desired.OneDriveSharingCapability
        }

        try {
            Set-PnPTenant @params -ErrorAction Stop

            Write-M365Log -Message "SPO sharing settings updated (Capability: $($desired.SharingCapability))." -Level Info
            return [PSCustomObject]@{
                ConfigName        = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting           = 'SPO Sharing'
                SharingCapability = $desired.SharingCapability
                Action            = 'Updated'
                Changed           = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update SPO sharing settings: $_" -Level Error
            throw
        }
    }
}
