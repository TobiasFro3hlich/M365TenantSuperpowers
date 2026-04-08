function Set-M365TeamsCallingPolicy {
    <#
    .SYNOPSIS
        Configures Teams calling policy.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Teams/.
    .EXAMPLE
        Set-M365TeamsCallingPolicy -ConfigName 'TEAMS-CallingPolicy'
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

    if ($PSCmdlet.ShouldProcess("Calling Policy: $policyIdentity", "Update Teams calling policy")) {
        Write-M365Log -Message "Applying Teams calling policy: $policyIdentity" -Level Info

        $params = @{}
        foreach ($key in $desired.Keys) { $params[$key] = $desired[$key] }

        try {
            Set-CsTeamsCallingPolicy -Identity $policyIdentity @params -ErrorAction Stop
            Write-M365Log -Message "Teams calling policy '$policyIdentity' updated." -Level Info
            return [PSCustomObject]@{ ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }; Setting = "Calling Policy: $policyIdentity"; Action = 'Updated'; Changed = $true }
        }
        catch { Write-M365Log -Message "Failed to update calling policy: $_" -Level Error; throw }
    }
}
