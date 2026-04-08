function Get-M365SecurityReport {
    <#
    .SYNOPSIS
        Generates a report of current security and compliance settings.
    .EXAMPLE
        Get-M365SecurityReport | Export-M365Report -Format HTML -Title 'Security Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service ExchangeOnline

    $report = [System.Collections.Generic.List[object]]::new()

    # Audit logging
    try {
        $audit = Get-AdminAuditLogConfig -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Audit'; Setting = 'Unified Audit Log'; Value = $audit.UnifiedAuditLogIngestionEnabled })
    }
    catch { Write-M365Log -Message "Could not read audit config: $_" -Level Warning }

    # DLP Policies
    try {
        $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'DLP'; Setting = 'Total DLP Policies'; Value = $dlp.Count })
        foreach ($p in $dlp) {
            $report.Add([PSCustomObject]@{ Section = 'DLP'; Setting = "Policy: $($p.Name)"; Value = "Mode=$($p.Mode), Enabled=$($p.Enabled)" })
        }
    }
    catch { Write-M365Log -Message "Could not read DLP policies: $_" -Level Warning }

    # Sensitivity Labels
    try {
        $labels = Get-Label -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Labels'; Setting = 'Total Sensitivity Labels'; Value = $labels.Count })
        foreach ($l in $labels) {
            $report.Add([PSCustomObject]@{ Section = 'Labels'; Setting = "Label: $($l.DisplayName)"; Value = "Priority=$($l.Priority), Encryption=$($l.EncryptionEnabled)" })
        }
    }
    catch { Write-M365Log -Message "Could not read labels: $_" -Level Warning }

    # Label Policies
    try {
        $policies = Get-LabelPolicy -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Label Policies'; Setting = 'Total Label Policies'; Value = $policies.Count })
        foreach ($p in $policies) {
            $report.Add([PSCustomObject]@{ Section = 'Label Policies'; Setting = "Policy: $($p.Name)"; Value = "Labels=$($p.Labels -join ', ')" })
        }
    }
    catch { Write-M365Log -Message "Could not read label policies: $_" -Level Warning }

    # Retention Policies
    try {
        $retention = Get-RetentionCompliancePolicy -ErrorAction Stop
        $report.Add([PSCustomObject]@{ Section = 'Retention'; Setting = 'Total Retention Policies'; Value = $retention.Count })
        foreach ($r in $retention) {
            $report.Add([PSCustomObject]@{ Section = 'Retention'; Setting = "Policy: $($r.Name)"; Value = "Enabled=$($r.Enabled)" })
        }
    }
    catch { Write-M365Log -Message "Could not read retention policies: $_" -Level Warning }

    # Alert Policies (key ones)
    try {
        $alerts = Get-ProtectionAlert -ErrorAction Stop | Where-Object { $_.IsSystemRule -eq $true }
        $report.Add([PSCustomObject]@{ Section = 'Alerts'; Setting = 'System Alert Policies'; Value = $alerts.Count })
        $disabledAlerts = $alerts | Where-Object { $_.IsEnabled -eq $false }
        $report.Add([PSCustomObject]@{ Section = 'Alerts'; Setting = 'Disabled System Alerts'; Value = $disabledAlerts.Count })
    }
    catch { Write-M365Log -Message "Could not read alerts: $_" -Level Warning }

    return $report
}
