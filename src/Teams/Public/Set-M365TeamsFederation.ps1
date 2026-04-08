function Set-M365TeamsFederation {
    <#
    .SYNOPSIS
        Configures Teams external access / federation settings.
    .DESCRIPTION
        Controls whether users can communicate with people in other organizations,
        Skype consumers, and Teams consumer accounts.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Teams/.
    .EXAMPLE
        Set-M365TeamsFederation -ConfigName 'TEAMS-Federation'
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

    if ($PSCmdlet.ShouldProcess('Teams Federation', 'Update external access settings')) {
        Write-M365Log -Message "Applying Teams federation settings..." -Level Info

        $params = @{}
        $props = @(
            'AllowFederatedUsers', 'AllowTeamsConsumer', 'AllowTeamsConsumerInbound',
            'AllowPublicUsers', 'AllowedDomains', 'BlockedDomains'
        )
        foreach ($prop in $props) {
            if ($null -ne $desired[$prop]) { $params[$prop] = $desired[$prop] }
        }

        try {
            Set-CsTenantFederationConfiguration @params -ErrorAction Stop
            Write-M365Log -Message "Teams federation settings updated." -Level Info
            return [PSCustomObject]@{ ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }; Setting = 'Federation'; Action = 'Updated'; Changed = $true }
        }
        catch { Write-M365Log -Message "Failed to update federation: $_" -Level Error; throw }
    }
}
