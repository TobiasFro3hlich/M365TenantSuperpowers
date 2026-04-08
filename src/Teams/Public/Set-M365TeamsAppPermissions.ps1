function Set-M365TeamsAppPermissions {
    <#
    .SYNOPSIS
        Configures Teams app permission policy (which apps are allowed/blocked).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Teams/.
    .EXAMPLE
        Set-M365TeamsAppPermissions -ConfigName 'TEAMS-AppPermissions'
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
    $policyIdentity = $config.settings.identity
    $desired = $config.settings.policy

    if ($PSCmdlet.ShouldProcess("App Permission Policy: $policyIdentity", "Update Teams app permissions")) {
        Write-M365Log -Message "Applying Teams app permission policy: $policyIdentity" -Level Info

        $params = @{}
        foreach ($key in $desired.Keys) { $params[$key] = $desired[$key] }

        try {
            Set-CsTeamsAppPermissionPolicy -Identity $policyIdentity @params -ErrorAction Stop
            Write-M365Log -Message "Teams app permission policy '$policyIdentity' updated." -Level Info
            return [PSCustomObject]@{ ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }; Setting = "App Permission Policy: $policyIdentity"; Action = 'Updated'; Changed = $true }
        }
        catch { Write-M365Log -Message "Failed to update app permission policy: $_" -Level Error; throw }
    }
}
