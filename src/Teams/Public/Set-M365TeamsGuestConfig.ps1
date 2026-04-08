function Set-M365TeamsGuestConfig {
    <#
    .SYNOPSIS
        Configures Teams guest access settings (calling, meeting, messaging).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Teams/.
    .EXAMPLE
        Set-M365TeamsGuestConfig -ConfigName 'TEAMS-GuestConfig'
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

    if ($PSCmdlet.ShouldProcess('Teams Guest Config', 'Update guest access settings')) {
        Write-M365Log -Message "Applying Teams guest configuration..." -Level Info
        $results = [System.Collections.Generic.List[object]]::new()

        # Guest Calling
        if ($desired.guestCalling) {
            try {
                Set-CsTeamsGuestCallingConfiguration -AllowPrivateCalling $desired.guestCalling.AllowPrivateCalling -ErrorAction Stop
                $results.Add([PSCustomObject]@{ Setting = 'Guest Calling'; Action = 'Updated'; Changed = $true })
                Write-M365Log -Message "Guest calling: AllowPrivateCalling=$($desired.guestCalling.AllowPrivateCalling)" -Level Info
            }
            catch { Write-M365Log -Message "Failed guest calling config: $_" -Level Error; $results.Add([PSCustomObject]@{ Setting = 'Guest Calling'; Action = 'Failed'; Changed = $false }) }
        }

        # Guest Meeting
        if ($desired.guestMeeting) {
            try {
                $meetParams = @{}
                if ($null -ne $desired.guestMeeting.AllowIPVideo) { $meetParams['AllowIPVideo'] = $desired.guestMeeting.AllowIPVideo }
                if ($desired.guestMeeting.ScreenSharingMode) { $meetParams['ScreenSharingMode'] = $desired.guestMeeting.ScreenSharingMode }
                Set-CsTeamsGuestMeetingConfiguration @meetParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{ Setting = 'Guest Meeting'; Action = 'Updated'; Changed = $true })
                Write-M365Log -Message "Guest meeting config updated." -Level Info
            }
            catch { Write-M365Log -Message "Failed guest meeting config: $_" -Level Error; $results.Add([PSCustomObject]@{ Setting = 'Guest Meeting'; Action = 'Failed'; Changed = $false }) }
        }

        # Guest Messaging
        if ($desired.guestMessaging) {
            try {
                $msgParams = @{}
                $msgProps = @('AllowUserEditMessage', 'AllowUserDeleteMessage', 'AllowUserChat', 'AllowGiphy', 'GiphyRatingType', 'AllowMemes', 'AllowStickers', 'AllowImmersiveReader')
                foreach ($prop in $msgProps) {
                    if ($null -ne $desired.guestMessaging[$prop]) { $msgParams[$prop] = $desired.guestMessaging[$prop] }
                }
                Set-CsTeamsGuestMessagingConfiguration @msgParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{ Setting = 'Guest Messaging'; Action = 'Updated'; Changed = $true })
                Write-M365Log -Message "Guest messaging config updated." -Level Info
            }
            catch { Write-M365Log -Message "Failed guest messaging config: $_" -Level Error; $results.Add([PSCustomObject]@{ Setting = 'Guest Messaging'; Action = 'Failed'; Changed = $false }) }
        }

        return $results
    }
}
