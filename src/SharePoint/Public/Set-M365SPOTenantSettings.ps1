function Set-M365SPOTenantSettings {
    <#
    .SYNOPSIS
        Configures SharePoint Online tenant-level settings.
    .DESCRIPTION
        Sets core SPO tenant settings including legacy auth, notifications,
        site creation defaults, comments, and OneDrive defaults.
    .PARAMETER ConfigName
        Name of the JSON config from configs/SharePoint/.
    .EXAMPLE
        Set-M365SPOTenantSettings -ConfigName 'SPO-TenantSettings'
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

    if ($PSCmdlet.ShouldProcess('SPO Tenant Settings', 'Update SharePoint tenant settings')) {
        Write-M365Log -Message "Applying SPO tenant settings..." -Level Info

        $params = @{}
        $props = @(
            'LegacyAuthProtocolsEnabled', 'NotificationsInSharePointEnabled',
            'CommentsOnSitePagesDisabled', 'CommentsOnFilesDisabled',
            'SocialBarOnSitePagesDisabled', 'SearchResolveExactEmailOrUPN',
            'OfficeClientADALDisabled', 'EnableGuestSignInAcceleration',
            'EnableAutoNewsDigest', 'MarkNewFilesSensitiveByDefault',
            'DisabledWebPartIds', 'EnableAIPIntegration',
            'DisableCustomAppAuthentication', 'IsFluidEnabled',
            'DisablePersonalListCreation', 'IsLoopEnabled'
        )

        foreach ($prop in $props) {
            if ($null -ne $desired[$prop]) {
                $params[$prop] = $desired[$prop]
            }
        }

        try {
            Set-PnPTenant @params -ErrorAction Stop

            Write-M365Log -Message "SPO tenant settings updated." -Level Info
            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'SPO Tenant Settings'
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update SPO tenant settings: $_" -Level Error
            throw
        }
    }
}
