function Get-M365TeamsReport {
    <#
    .SYNOPSIS
        Generates a report of current Teams configuration.
    .EXAMPLE
        Get-M365TeamsReport | Export-M365Report -Format HTML -Title 'Teams Config Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service Teams

    $report = [System.Collections.Generic.List[object]]::new()

    # Meeting Policy (Global)
    try {
        $p = Get-CsTeamsMeetingPolicy -Identity 'Global' -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Meeting Policy'; Setting = 'Allow Cloud Recording'; Value = $p.AllowCloudRecording })
        $report.Add([PSCustomObject]@{ Section = 'Meeting Policy'; Setting = 'Allow Transcription'; Value = $p.AllowTranscription })
        $report.Add([PSCustomObject]@{ Section = 'Meeting Policy'; Setting = 'Auto Admitted Users'; Value = $p.AutoAdmittedUsers })
        $report.Add([PSCustomObject]@{ Section = 'Meeting Policy'; Setting = 'Allow Anonymous Join'; Value = $p.AllowAnonymousUsersToJoinMeeting })
        $report.Add([PSCustomObject]@{ Section = 'Meeting Policy'; Setting = 'Screen Sharing Mode'; Value = $p.ScreenSharingMode })
        $report.Add([PSCustomObject]@{ Section = 'Meeting Policy'; Setting = 'Allow IP Video'; Value = $p.AllowIPVideo })
    }
    catch { Write-M365Log -Message "Could not read meeting policy: $_" -Level Warning }

    # Messaging Policy (Global)
    try {
        $p = Get-CsTeamsMessagingPolicy -Identity 'Global' -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Messaging Policy'; Setting = 'Allow User Edit'; Value = $p.AllowUserEditMessage })
        $report.Add([PSCustomObject]@{ Section = 'Messaging Policy'; Setting = 'Allow User Delete'; Value = $p.AllowUserDeleteMessage })
        $report.Add([PSCustomObject]@{ Section = 'Messaging Policy'; Setting = 'Allow Giphy'; Value = $p.AllowGiphy })
        $report.Add([PSCustomObject]@{ Section = 'Messaging Policy'; Setting = 'Giphy Rating'; Value = $p.GiphyRatingType })
        $report.Add([PSCustomObject]@{ Section = 'Messaging Policy'; Setting = 'Read Receipts'; Value = $p.ReadReceiptsEnabledType })
    }
    catch { Write-M365Log -Message "Could not read messaging policy: $_" -Level Warning }

    # Federation
    try {
        $f = Get-CsTenantFederationConfiguration -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Federation'; Setting = 'Allow Federated Users'; Value = $f.AllowFederatedUsers })
        $report.Add([PSCustomObject]@{ Section = 'Federation'; Setting = 'Allow Teams Consumer'; Value = $f.AllowTeamsConsumer })
        $report.Add([PSCustomObject]@{ Section = 'Federation'; Setting = 'Allow Teams Consumer Inbound'; Value = $f.AllowTeamsConsumerInbound })
        $report.Add([PSCustomObject]@{ Section = 'Federation'; Setting = 'Allow Public Users (Skype)'; Value = $f.AllowPublicUsers })
    }
    catch { Write-M365Log -Message "Could not read federation: $_" -Level Warning }

    # Guest
    try {
        $gc = Get-CsTeamsGuestCallingConfiguration -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Guest Access'; Setting = 'Allow Private Calling'; Value = $gc.AllowPrivateCalling })
        $gm = Get-CsTeamsGuestMeetingConfiguration -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Guest Access'; Setting = 'Allow IP Video (Guest)'; Value = $gm.AllowIPVideo })
        $report.Add([PSCustomObject]@{ Section = 'Guest Access'; Setting = 'Screen Sharing (Guest)'; Value = $gm.ScreenSharingMode })
        $gmsg = Get-CsTeamsGuestMessagingConfiguration -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Guest Access'; Setting = 'Allow Chat (Guest)'; Value = $gmsg.AllowUserChat })
        $report.Add([PSCustomObject]@{ Section = 'Guest Access'; Setting = 'Allow Giphy (Guest)'; Value = $gmsg.AllowGiphy })
    }
    catch { Write-M365Log -Message "Could not read guest config: $_" -Level Warning }

    # Client Config
    try {
        $cc = Get-CsTeamsClientConfiguration -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Client Config'; Setting = 'Allow DropBox'; Value = $cc.AllowDropBox })
        $report.Add([PSCustomObject]@{ Section = 'Client Config'; Setting = 'Allow Google Drive'; Value = $cc.AllowGoogleDrive })
        $report.Add([PSCustomObject]@{ Section = 'Client Config'; Setting = 'Allow Box'; Value = $cc.AllowBox })
        $report.Add([PSCustomObject]@{ Section = 'Client Config'; Setting = 'Allow Email Into Channel'; Value = $cc.AllowEmailIntoChannel })
    }
    catch { Write-M365Log -Message "Could not read client config: $_" -Level Warning }

    return $report
}
