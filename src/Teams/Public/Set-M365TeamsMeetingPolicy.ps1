function Set-M365TeamsMeetingPolicy {
    <#
    .SYNOPSIS
        Configures Teams meeting policy (Global or named).
    .DESCRIPTION
        Sets meeting controls: recording, transcription, lobby, screen sharing,
        anonymous access, chat, video, and presenter defaults.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Teams/.
    .EXAMPLE
        Set-M365TeamsMeetingPolicy -ConfigName 'TEAMS-MeetingPolicy'
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

    if ($PSCmdlet.ShouldProcess("Meeting Policy: $policyIdentity", "Update Teams meeting policy")) {
        Write-M365Log -Message "Applying Teams meeting policy: $policyIdentity" -Level Info

        $params = @{}
        foreach ($key in $desired.Keys) {
            $params[$key] = $desired[$key]
        }

        try {
            Set-CsTeamsMeetingPolicy -Identity $policyIdentity @params -ErrorAction Stop

            Write-M365Log -Message "Teams meeting policy '$policyIdentity' updated." -Level Info
            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = "Meeting Policy: $policyIdentity"
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update meeting policy: $_" -Level Error
            throw
        }
    }
}
