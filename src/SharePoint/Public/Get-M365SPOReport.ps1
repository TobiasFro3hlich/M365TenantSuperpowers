function Get-M365SPOReport {
    <#
    .SYNOPSIS
        Generates a report of current SharePoint Online tenant settings.
    .EXAMPLE
        Get-M365SPOReport | Export-M365Report -Format HTML -Title 'SPO Config Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service SharePoint

    $report = [System.Collections.Generic.List[object]]::new()

    try {
        $tenant = Get-PnPTenant -ErrorAction Stop

        # Sharing
        $report.Add([PSCustomObject]@{ Section = 'Sharing'; Setting = 'Sharing Capability'; Value = $tenant.SharingCapability })
        $report.Add([PSCustomObject]@{ Section = 'Sharing'; Setting = 'Default Link Type'; Value = $tenant.DefaultSharingLinkType })
        $report.Add([PSCustomObject]@{ Section = 'Sharing'; Setting = 'Default Link Permission'; Value = $tenant.DefaultLinkPermission })
        $report.Add([PSCustomObject]@{ Section = 'Sharing'; Setting = 'Require Account Match'; Value = $tenant.RequireAcceptingAccountMatchInvitedAccount })
        $report.Add([PSCustomObject]@{ Section = 'Sharing'; Setting = 'Prevent Resharing'; Value = $tenant.PreventExternalUsersFromResharing })
        $report.Add([PSCustomObject]@{ Section = 'Sharing'; Setting = 'Anon Links Expiry (days)'; Value = $tenant.RequireAnonymousLinksExpireInDays })
        $report.Add([PSCustomObject]@{ Section = 'Sharing'; Setting = 'OneDrive Sharing'; Value = $tenant.OneDriveSharingCapability })

        # Security
        $report.Add([PSCustomObject]@{ Section = 'Security'; Setting = 'Legacy Auth Protocols'; Value = $tenant.LegacyAuthProtocolsEnabled })
        $report.Add([PSCustomObject]@{ Section = 'Security'; Setting = 'Conditional Access Policy'; Value = $tenant.ConditionalAccessPolicy })
        $report.Add([PSCustomObject]@{ Section = 'Security'; Setting = 'Block Infected Downloads'; Value = $tenant.DisallowInfectedFileDownload })
        $report.Add([PSCustomObject]@{ Section = 'Security'; Setting = 'IP Address Enforcement'; Value = $tenant.IPAddressEnforcement })

        # General
        $report.Add([PSCustomObject]@{ Section = 'General'; Setting = 'Comments on Site Pages'; Value = -not $tenant.CommentsOnSitePagesDisabled })
        $report.Add([PSCustomObject]@{ Section = 'General'; Setting = 'Notifications'; Value = $tenant.NotificationsInSharePointEnabled })
    }
    catch {
        Write-M365Log -Message "Failed to read SPO tenant settings: $_" -Level Warning
        $report.Add([PSCustomObject]@{ Section = 'Error'; Setting = 'Get-PnPTenant'; Value = $_.ToString() })
    }

    # Browser idle signout
    try {
        $idle = Get-PnPBrowserIdleSignout -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Session'; Setting = 'Browser Idle Signout'; Value = $idle.Enabled })
        if ($idle.Enabled) {
            $report.Add([PSCustomObject]@{ Section = 'Session'; Setting = 'Warn After'; Value = $idle.WarnAfter })
            $report.Add([PSCustomObject]@{ Section = 'Session'; Setting = 'Sign Out After'; Value = $idle.SignOutAfter })
        }
    }
    catch { Write-M365Log -Message "Could not read browser idle signout: $_" -Level Warning }

    return $report
}
