function Set-M365TeamsMessagingPolicy {
    <#
    .SYNOPSIS
        Configures Teams messaging policy.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Teams/.
    .EXAMPLE
        Set-M365TeamsMessagingPolicy -ConfigName 'TEAMS-MessagingPolicy'
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

    if ($PSCmdlet.ShouldProcess("Messaging Policy: $policyIdentity", "Update Teams messaging policy")) {
        Write-M365Log -Message "Applying Teams messaging policy: $policyIdentity" -Level Info

        $params = @{}
        foreach ($key in $desired.Keys) { $params[$key] = $desired[$key] }

        try {
            Set-CsTeamsMessagingPolicy -Identity $policyIdentity @params -ErrorAction Stop
            Write-M365Log -Message "Teams messaging policy '$policyIdentity' updated." -Level Info
            return [PSCustomObject]@{ ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }; Setting = "Messaging Policy: $policyIdentity"; Action = 'Updated'; Changed = $true }
        }
        catch { Write-M365Log -Message "Failed to update messaging policy: $_" -Level Error; throw }
    }
}
