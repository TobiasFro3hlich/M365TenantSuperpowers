function Get-M365DefenderReport {
    <#
    .SYNOPSIS
        Generates a report of current Defender for Office 365 settings.
    .DESCRIPTION
        Reads all threat protection policies and returns a structured report
        covering anti-phish, anti-spam, anti-malware, Safe Links, and Safe Attachments.
    .EXAMPLE
        Get-M365DefenderReport | Export-M365Report -Format HTML -Title 'Defender Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service ExchangeOnline

    $report = [System.Collections.Generic.List[object]]::new()

    # ATP Global
    try {
        $atp = Get-AtpPolicyForO365 -ErrorAction Stop
        $report.Add([PSCustomObject]@{
            Section = 'ATP Global'
            Setting = 'Safe Attachments for SPO/ODB/Teams'
            Value   = $atp.EnableATPForSPOTeamsODB
        })
        $report.Add([PSCustomObject]@{
            Section = 'ATP Global'
            Setting = 'Safe Documents'
            Value   = $atp.EnableSafeDocs
        })
    }
    catch { Write-M365Log -Message "Could not read ATP global: $_" -Level Warning }

    # Anti-Phish Policies
    try {
        $policies = Get-AntiPhishPolicy -ErrorAction Stop
        foreach ($p in $policies) {
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Phishing'
                Setting = "$($p.Name) — Enabled"
                Value   = $p.Enabled
            })
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Phishing'
                Setting = "$($p.Name) — Phish Threshold"
                Value   = $p.PhishThresholdLevel
            })
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Phishing'
                Setting = "$($p.Name) — Mailbox Intelligence"
                Value   = $p.EnableMailboxIntelligence
            })
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Phishing'
                Setting = "$($p.Name) — Spoof Intelligence"
                Value   = $p.EnableSpoofIntelligence
            })
        }
    }
    catch { Write-M365Log -Message "Could not read anti-phish: $_" -Level Warning }

    # Safe Links
    try {
        $policies = Get-SafeLinksPolicy -ErrorAction Stop
        foreach ($p in $policies) {
            $report.Add([PSCustomObject]@{
                Section = 'Safe Links'
                Setting = "$($p.Name) — Email"
                Value   = $p.EnableSafeLinksForEmail
            })
            $report.Add([PSCustomObject]@{
                Section = 'Safe Links'
                Setting = "$($p.Name) — Teams"
                Value   = $p.EnableSafeLinksForTeams
            })
            $report.Add([PSCustomObject]@{
                Section = 'Safe Links'
                Setting = "$($p.Name) — Real-time scan"
                Value   = $p.ScanUrls
            })
        }
    }
    catch { Write-M365Log -Message "Could not read Safe Links: $_" -Level Warning }

    # Safe Attachments
    try {
        $policies = Get-SafeAttachmentPolicy -ErrorAction Stop
        foreach ($p in $policies) {
            $report.Add([PSCustomObject]@{
                Section = 'Safe Attachments'
                Setting = "$($p.Name) — Action"
                Value   = $p.Action
            })
            $report.Add([PSCustomObject]@{
                Section = 'Safe Attachments'
                Setting = "$($p.Name) — Redirect"
                Value   = $p.Redirect
            })
        }
    }
    catch { Write-M365Log -Message "Could not read Safe Attachments: $_" -Level Warning }

    # Anti-Spam
    try {
        $policies = Get-HostedContentFilterPolicy -ErrorAction Stop
        foreach ($p in $policies) {
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Spam'
                Setting = "$($p.Name) — Spam Action"
                Value   = $p.SpamAction
            })
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Spam'
                Setting = "$($p.Name) — High Confidence Spam Action"
                Value   = $p.HighConfidenceSpamAction
            })
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Spam'
                Setting = "$($p.Name) — Bulk Threshold"
                Value   = $p.BulkThreshold
            })
        }
    }
    catch { Write-M365Log -Message "Could not read anti-spam: $_" -Level Warning }

    # Anti-Malware
    try {
        $policies = Get-MalwareFilterPolicy -ErrorAction Stop
        foreach ($p in $policies) {
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Malware'
                Setting = "$($p.Name) — File Filter"
                Value   = $p.EnableFileFilter
            })
            $report.Add([PSCustomObject]@{
                Section = 'Anti-Malware'
                Setting = "$($p.Name) — ZAP"
                Value   = $p.ZapEnabled
            })
        }
    }
    catch { Write-M365Log -Message "Could not read anti-malware: $_" -Level Warning }

    return $report
}
