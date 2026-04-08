function Set-M365TeamsClientConfig {
    <#
    .SYNOPSIS
        Configures Teams client-wide settings.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Teams/.
    .EXAMPLE
        Set-M365TeamsClientConfig -ConfigName 'TEAMS-ClientConfig'
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

    Assert-M365Connection -Service Teams

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/Teams/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Teams Client Configuration', 'Update client settings')) {
        Write-M365Log -Message "Applying Teams client configuration..." -Level Info

        $params = @{}
        $props = @(
            'AllowEmailIntoChannel', 'AllowOrgTab', 'AllowSkypeBusinessInterop',
            'AllowDropBox', 'AllowBox', 'AllowGoogleDrive', 'AllowEgnyte',
            'AllowShareFile', 'AllowRoleBasedChatPermissions',
            'RestrictedSenderList', 'ContentPin'
        )
        foreach ($prop in $props) {
            if ($null -ne $desired[$prop]) { $params[$prop] = $desired[$prop] }
        }

        try {
            Set-CsTeamsClientConfiguration @params -ErrorAction Stop
            Write-M365Log -Message "Teams client configuration updated." -Level Info
            return [PSCustomObject]@{ ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }; Setting = 'Client Configuration'; Action = 'Updated'; Changed = $true }
        }
        catch { Write-M365Log -Message "Failed to update client config: $_" -Level Error; throw }
    }
}
