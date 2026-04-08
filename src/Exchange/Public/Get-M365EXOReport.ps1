function Get-M365EXOReport {
    <#
    .SYNOPSIS
        Generates a report of current Exchange Online configuration.
    .EXAMPLE
        Get-M365EXOReport | Export-M365Report -Format HTML -Title 'EXO Config Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service ExchangeOnline

    $report = [System.Collections.Generic.List[object]]::new()

    # Organization Config
    try {
        $org = Get-OrganizationConfig -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Organization'; Setting = 'Audit Disabled'; Value = $org.AuditDisabled })
        $report.Add([PSCustomObject]@{ Section = 'Organization'; Setting = 'OAuth2 Client Profile'; Value = $org.OAuth2ClientProfileEnabled })
        $report.Add([PSCustomObject]@{ Section = 'Organization'; Setting = 'MailTips All Tips'; Value = $org.MailTipsAllTipsEnabled })
        $report.Add([PSCustomObject]@{ Section = 'Organization'; Setting = 'MailTips External Recipients'; Value = $org.MailTipsExternalRecipientsTipsEnabled })
        $report.Add([PSCustomObject]@{ Section = 'Organization'; Setting = 'Send From Alias'; Value = $org.SendFromAliasEnabled })
        $report.Add([PSCustomObject]@{ Section = 'Organization'; Setting = 'Focused Inbox'; Value = $org.FocusedInboxOn })
    }
    catch { Write-M365Log -Message "Could not read org config: $_" -Level Warning }

    # DKIM
    try {
        $dkim = Get-DkimSigningConfig -ErrorAction Stop
        foreach ($d in $dkim) {
            $report.Add([PSCustomObject]@{ Section = 'DKIM'; Setting = $d.Domain; Value = $d.Enabled })
        }
    }
    catch { Write-M365Log -Message "Could not read DKIM: $_" -Level Warning }

    # Accepted Domains
    try {
        $domains = Get-AcceptedDomain -ErrorAction Stop
        foreach ($d in $domains) {
            $report.Add([PSCustomObject]@{ Section = 'Accepted Domains'; Setting = $d.DomainName; Value = "$($d.DomainType) (Default: $($d.Default))" })
        }
    }
    catch { Write-M365Log -Message "Could not read accepted domains: $_" -Level Warning }

    # External tag
    try {
        $ext = Get-ExternalInOutlook -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'External Tag'; Setting = 'Enabled'; Value = $ext.Enabled })
    }
    catch { Write-M365Log -Message "Could not read external tag: $_" -Level Warning }

    # Remote Domain
    try {
        $rd = Get-RemoteDomain -Identity 'Default' -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Remote Domain'; Setting = 'Auto Forward Enabled'; Value = $rd.AutoForwardEnabled })
        $report.Add([PSCustomObject]@{ Section = 'Remote Domain'; Setting = 'Allowed OOF Type'; Value = $rd.AllowedOOFType })
    }
    catch { Write-M365Log -Message "Could not read remote domain: $_" -Level Warning }

    return $report
}
