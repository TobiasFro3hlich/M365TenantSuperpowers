function Invoke-M365ComplianceAudit {
    <#
    .SYNOPSIS
        Runs a comprehensive compliance audit against CISA SCuBA, CIS v6, and Microsoft baselines.
    .DESCRIPTION
        Checks all operational/manual items that cannot be deployed via config-as-code
        but CAN be audited programmatically. Produces a pass/fail report with
        baseline references and remediation guidance.

        Checks include: Global Admin count, cloud-only admins, auth migration status,
        diagnostic settings, preset security policies, shared mailbox sign-in,
        DNS records (SPF/DKIM/DMARC), MFA registration, audit bypass, transport
        rule whitelisting, and more.
    .PARAMETER Services
        Which service areas to audit. Default: All connected services.
    .PARAMETER Domains
        Domains to check DNS records for. If omitted, reads from accepted domains.
    .PARAMETER OutputFormat
        Export format. Default: Console. Options: Console, HTML, CSV, JSON.
    .PARAMETER OutputPath
        Directory for file output. Default: ./output/audit.
    .EXAMPLE
        Invoke-M365ComplianceAudit
    .EXAMPLE
        Invoke-M365ComplianceAudit -Services EntraID, Exchange -OutputFormat HTML
    .EXAMPLE
        Invoke-M365ComplianceAudit -Domains 'contoso.com','fabrikam.com' -OutputFormat HTML, CSV
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('All', 'EntraID', 'Exchange', 'Defender', 'SharePoint', 'Teams')]
        [string[]]$Services = @('All'),

        [Parameter()]
        [string[]]$Domains,

        [Parameter()]
        [ValidateSet('Console', 'HTML', 'CSV', 'JSON')]
        [string[]]$OutputFormat = @('Console'),

        [Parameter()]
        [string]$OutputPath = './output/audit'
    )

    Write-M365Log -Message "Starting M365 Compliance Audit..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()
    $timestamp = Get-Date

    $allServices = if ('All' -in $Services) {
        @('EntraID', 'Exchange', 'Defender', 'SharePoint', 'Teams')
    } else { $Services }

    # ============================================================
    # ENTRA ID CHECKS
    # ============================================================
    if ('EntraID' -in $allServices) {
        Write-M365Log -Message "Auditing Entra ID..." -Level Info

        # CHECK: Global Admin count (CISA MS.AAD.7.1v1 — 2 to 8)
        try {
            $gaRole = Invoke-MgGraphRequest -Method GET `
                -Uri "https://graph.microsoft.com/v1.0/directoryRoles?`$filter=roleTemplateId eq '62e90394-69f5-4237-9190-012177145e10'" `
                -ErrorAction Stop

            if ($gaRole.value.Count -gt 0) {
                $gaMembers = Invoke-MgGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($gaRole.value[0].id)/members" `
                    -ErrorAction Stop
                $gaCount = $gaMembers.value.Count

                $results.Add([PSCustomObject]@{
                    Section    = 'Entra ID'
                    Check      = 'Global Admin count (2-8)'
                    Baseline   = 'CISA MS.AAD.7.1v1 | CIS 1.1.3'
                    Expected   = '2-8'
                    Actual     = $gaCount
                    Status     = if ($gaCount -ge 2 -and $gaCount -le 8) { 'PASS' } else { 'FAIL' }
                    Severity   = 'Critical'
                    Remediation = if ($gaCount -lt 2) { 'Add at least one more Global Admin' } elseif ($gaCount -gt 8) { 'Reduce Global Admins, use fine-grained roles instead' } else { '' }
                })
            }
        }
        catch { Write-M365Log -Message "GA count check failed: $_" -Level Warning }

        # CHECK: Cloud-only admin accounts (CISA MS.AAD.7.3v1)
        try {
            $privilegedRoleIds = @(
                '62e90394-69f5-4237-9190-012177145e10', # GA
                'e8611ab8-c189-46e8-94e1-60213ab1f814', # Privileged Role Admin
                '194ae4cb-b126-40b2-bd5b-6091b380977d'  # Security Admin
            )

            $syncedAdmins = 0
            $totalAdmins = 0
            foreach ($roleId in $privilegedRoleIds) {
                $role = Invoke-MgGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/directoryRoles?`$filter=roleTemplateId eq '$roleId'" -ErrorAction SilentlyContinue
                if ($role.value.Count -gt 0) {
                    $members = Invoke-MgGraphRequest -Method GET `
                        -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($role.value[0].id)/members" -ErrorAction SilentlyContinue
                    foreach ($m in $members.value) {
                        $totalAdmins++
                        if ($m.onPremisesSyncEnabled -eq $true) { $syncedAdmins++ }
                    }
                }
            }

            $results.Add([PSCustomObject]@{
                Section    = 'Entra ID'
                Check      = 'Cloud-only privileged accounts'
                Baseline   = 'CISA MS.AAD.7.3v1 | CIS 1.1.1'
                Expected   = '0 synced admin accounts'
                Actual     = "$syncedAdmins synced of $totalAdmins total"
                Status     = if ($syncedAdmins -eq 0) { 'PASS' } else { 'FAIL' }
                Severity   = 'Critical'
                Remediation = if ($syncedAdmins -gt 0) { 'Create cloud-only accounts for all privileged roles' } else { '' }
            })
        }
        catch { Write-M365Log -Message "Cloud-only admin check failed: $_" -Level Warning }

        # CHECK: Auth methods migration status (CISA MS.AAD.3.4v1)
        try {
            $authPolicy = Invoke-MgGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy' -ErrorAction Stop

            $migrationState = $authPolicy.policyMigrationState

            $results.Add([PSCustomObject]@{
                Section    = 'Entra ID'
                Check      = 'Auth methods migration complete'
                Baseline   = 'CISA MS.AAD.3.4v1'
                Expected   = 'migrationComplete'
                Actual     = $migrationState
                Status     = if ($migrationState -eq 'migrationComplete') { 'PASS' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if ($migrationState -ne 'migrationComplete') { 'Set Manage Migration to "Migration Complete" in Entra admin center > Authentication methods' } else { '' }
            })
        }
        catch { Write-M365Log -Message "Auth migration check failed: $_" -Level Warning }

        # CHECK: Diagnostic settings / SIEM (CISA MS.AAD.4.1v1)
        try {
            $diagSettings = Invoke-MgGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/v1.0/auditLogs/directoryAudits?$top=1' -ErrorAction Stop

            # Check if diagnostic settings are configured (at least audit logs are accessible)
            $hasDiag = ($null -ne $diagSettings.value)

            $results.Add([PSCustomObject]@{
                Section    = 'Entra ID'
                Check      = 'Audit logs accessible (SIEM prerequisite)'
                Baseline   = 'CISA MS.AAD.4.1v1'
                Expected   = 'Logs accessible and flowing'
                Actual     = if ($hasDiag) { 'Accessible' } else { 'Not accessible' }
                Status     = if ($hasDiag) { 'PASS' } else { 'WARN' }
                Severity   = 'High'
                Remediation = 'Verify diagnostic settings export to SIEM (Log Analytics, Sentinel, or third-party)'
            })
        }
        catch { Write-M365Log -Message "Diagnostic settings check failed: $_" -Level Warning }

        # CHECK: Self-service trials and purchases (CIS 1.3.4)
        try {
            $appsServices = Invoke-MgGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/beta/admin/appsAndServices' -ErrorAction Stop

            $storeOff = ($appsServices.isOfficeStoreEnabled -eq $false)
            $trialsOff = ($appsServices.isAppAndServicesTrialEnabled -eq $false)

            $results.Add([PSCustomObject]@{
                Section    = 'Entra ID'
                Check      = 'Office Store disabled for users'
                Baseline   = 'CIS 1.3.4'
                Expected   = 'false'
                Actual     = $appsServices.isOfficeStoreEnabled
                Status     = if ($storeOff) { 'PASS' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if (-not $storeOff) { 'Run Set-M365EntraSelfServiceControls or disable in Admin Center > Org Settings > User owned apps' } else { '' }
            })

            $results.Add([PSCustomObject]@{
                Section    = 'Entra ID'
                Check      = 'User-initiated trials disabled'
                Baseline   = 'CIS 1.3.4'
                Expected   = 'false'
                Actual     = $appsServices.isAppAndServicesTrialEnabled
                Status     = if ($trialsOff) { 'PASS' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if (-not $trialsOff) { 'Run Set-M365EntraSelfServiceControls or disable in Admin Center > Org Settings > User owned apps' } else { '' }
            })
        }
        catch { Write-M365Log -Message "Self-service controls check failed: $_" -Level Warning }

        # CHECK: MFA registration coverage (CIS 5.2.3.4)
        try {
            $authMethods = Invoke-MgGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails?$top=999' -ErrorAction Stop

            $totalUsers = $authMethods.value.Count
            $mfaCapable = ($authMethods.value | Where-Object { $_.isMfaCapable -eq $true }).Count
            $pct = if ($totalUsers -gt 0) { [math]::Round(($mfaCapable / $totalUsers) * 100, 1) } else { 0 }

            $results.Add([PSCustomObject]@{
                Section    = 'Entra ID'
                Check      = 'Users MFA capable'
                Baseline   = 'CIS 5.2.3.4'
                Expected   = '100%'
                Actual     = "$mfaCapable of $totalUsers ($pct%)"
                Status     = if ($pct -ge 95) { 'PASS' } elseif ($pct -ge 80) { 'WARN' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if ($pct -lt 95) { "Register MFA for remaining $($totalUsers - $mfaCapable) users" } else { '' }
            })
        }
        catch { Write-M365Log -Message "MFA registration check failed: $_" -Level Warning }

        # CHECK: Permanent active PIM assignments (CISA MS.AAD.7.4v1)
        try {
            $activeAssignments = Invoke-MgGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances' -ErrorAction Stop

            $permanent = $activeAssignments.value | Where-Object {
                $_.assignmentType -eq 'Assigned' -and ($null -eq $_.endDateTime -or $_.endDateTime -eq '')
            }

            $results.Add([PSCustomObject]@{
                Section    = 'Entra ID'
                Check      = 'No permanent active privileged assignments'
                Baseline   = 'CISA MS.AAD.7.4v1 | CIS 5.3.1'
                Expected   = '0 (except break-glass)'
                Actual     = "$($permanent.Count) permanent assignments"
                Status     = if ($permanent.Count -le 2) { 'PASS' } else { 'FAIL' }
                Severity   = 'Critical'
                Remediation = if ($permanent.Count -gt 2) { 'Convert permanent assignments to PIM eligible' } else { '' }
            })
        }
        catch { Write-M365Log -Message "PIM assignment check failed: $_" -Level Warning }
    }

    # ============================================================
    # EXCHANGE ONLINE CHECKS
    # ============================================================
    if ('Exchange' -in $allServices) {
        Write-M365Log -Message "Auditing Exchange Online..." -Level Info

        # CHECK: Shared mailbox sign-in blocked (CIS 1.2.2)
        try {
            $sharedMBs = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -ErrorAction Stop
            $unblocked = 0
            foreach ($mb in $sharedMBs) {
                $user = Get-MgUser -UserId $mb.ExternalDirectoryObjectId -Property 'accountEnabled' -ErrorAction SilentlyContinue
                if ($user.AccountEnabled) { $unblocked++ }
            }

            $results.Add([PSCustomObject]@{
                Section    = 'Exchange'
                Check      = 'Shared mailbox sign-in blocked'
                Baseline   = 'CIS 1.2.2'
                Expected   = '0 with sign-in enabled'
                Actual     = "$unblocked of $($sharedMBs.Count) have sign-in enabled"
                Status     = if ($unblocked -eq 0) { 'PASS' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if ($unblocked -gt 0) { "Run Set-M365EXOSharedMailboxBlock to disable sign-in for $unblocked shared mailboxes" } else { '' }
            })
        }
        catch { Write-M365Log -Message "Shared mailbox check failed: $_" -Level Warning }

        # CHECK: Audit bypass not enabled (CIS 6.1.3)
        try {
            $bypassMBs = Get-MailboxAuditBypassAssociation -ResultSize Unlimited -ErrorAction Stop |
                Where-Object { $_.AuditBypassEnabled -eq $true }

            $results.Add([PSCustomObject]@{
                Section    = 'Exchange'
                Check      = 'No mailboxes bypass auditing'
                Baseline   = 'CIS 6.1.3'
                Expected   = '0'
                Actual     = "$($bypassMBs.Count) mailboxes bypass audit"
                Status     = if ($bypassMBs.Count -eq 0) { 'PASS' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if ($bypassMBs.Count -gt 0) { 'Disable AuditBypassEnabled on: ' + ($bypassMBs.Name -join ', ') } else { '' }
            })
        }
        catch { Write-M365Log -Message "Audit bypass check failed: $_" -Level Warning }

        # CHECK: No transport rules whitelisting domains (CIS 6.2.2)
        try {
            $rules = Get-TransportRule -ErrorAction Stop
            $whitelistRules = $rules | Where-Object {
                $_.SetSCL -eq -1 -or
                $_.SetHeaderName -eq 'X-MS-Exchange-Organization-SkipSafeLinksProcessing'
            }

            $results.Add([PSCustomObject]@{
                Section    = 'Exchange'
                Check      = 'No transport rules bypass spam filtering'
                Baseline   = 'CIS 6.2.2'
                Expected   = '0 rules setting SCL=-1 or bypassing Safe Links'
                Actual     = "$($whitelistRules.Count) rules found"
                Status     = if ($whitelistRules.Count -eq 0) { 'PASS' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if ($whitelistRules.Count -gt 0) { 'Review and remove: ' + ($whitelistRules.Name -join ', ') } else { '' }
            })
        }
        catch { Write-M365Log -Message "Transport rule check failed: $_" -Level Warning }

        # CHECK: DNS Records (SPF, DKIM, DMARC)
        if (-not $Domains) {
            try {
                $acceptedDomains = Get-AcceptedDomain -ErrorAction Stop
                $Domains = $acceptedDomains | Where-Object { $_.Default -eq $true -or $_.DomainType -eq 'Authoritative' } | Select-Object -ExpandProperty DomainName
            }
            catch { Write-M365Log -Message "Could not get accepted domains: $_" -Level Warning }
        }

        foreach ($domain in $Domains) {
            # SPF check (CISA MS.EXO.2.2v3, CIS 2.1.8)
            try {
                $spf = Resolve-DnsName -Name $domain -Type TXT -ErrorAction Stop |
                    Where-Object { $_.Strings -like 'v=spf1*' }

                $spfRecord = if ($spf) { $spf.Strings -join '' } else { 'MISSING' }
                $spfHardfail = $spfRecord -match '-all$'

                $results.Add([PSCustomObject]@{
                    Section    = 'DNS'
                    Check      = "SPF record for $domain"
                    Baseline   = 'CISA MS.EXO.2.2v3 | CIS 2.1.8'
                    Expected   = 'v=spf1 ... -all'
                    Actual     = if ($spfRecord.Length -gt 80) { $spfRecord.Substring(0,80) + '...' } else { $spfRecord }
                    Status     = if ($spfHardfail) { 'PASS' } elseif ($spf) { 'WARN' } else { 'FAIL' }
                    Severity   = 'Critical'
                    Remediation = if (-not $spf) { "Add SPF TXT record for $domain" } elseif (-not $spfHardfail) { "Change ~all to -all in SPF for $domain" } else { '' }
                })
            }
            catch { $results.Add([PSCustomObject]@{ Section = 'DNS'; Check = "SPF for $domain"; Status = 'ERROR'; Actual = $_.ToString() }) }

            # DMARC check (CISA MS.EXO.4.1v1, CIS 2.1.10)
            try {
                $dmarc = Resolve-DnsName -Name "_dmarc.$domain" -Type TXT -ErrorAction Stop |
                    Where-Object { $_.Strings -like 'v=DMARC1*' }

                $dmarcRecord = if ($dmarc) { $dmarc.Strings -join '' } else { 'MISSING' }
                $dmarcReject = $dmarcRecord -match 'p=reject'

                $results.Add([PSCustomObject]@{
                    Section    = 'DNS'
                    Check      = "DMARC record for $domain"
                    Baseline   = 'CISA MS.EXO.4.1v1/4.2v1 | CIS 2.1.10'
                    Expected   = 'v=DMARC1; p=reject'
                    Actual     = if ($dmarcRecord.Length -gt 80) { $dmarcRecord.Substring(0,80) + '...' } else { $dmarcRecord }
                    Status     = if ($dmarcReject) { 'PASS' } elseif ($dmarc) { 'WARN' } else { 'FAIL' }
                    Severity   = 'Critical'
                    Remediation = if (-not $dmarc) { "Add DMARC TXT record at _dmarc.$domain" } elseif (-not $dmarcReject) { "Upgrade DMARC policy to p=reject for $domain" } else { '' }
                })
            }
            catch { $results.Add([PSCustomObject]@{ Section = 'DNS'; Check = "DMARC for $domain"; Status = 'ERROR'; Actual = $_.ToString() }) }

            # DKIM CNAME check
            try {
                $selector1 = Resolve-DnsName -Name "selector1._domainkey.$domain" -Type CNAME -ErrorAction SilentlyContinue
                $selector2 = Resolve-DnsName -Name "selector2._domainkey.$domain" -Type CNAME -ErrorAction SilentlyContinue

                $dkimOk = ($null -ne $selector1 -and $null -ne $selector2)

                $results.Add([PSCustomObject]@{
                    Section    = 'DNS'
                    Check      = "DKIM CNAME records for $domain"
                    Baseline   = 'CISA MS.EXO.3.1v1 | CIS 2.1.9'
                    Expected   = 'selector1 + selector2 CNAME records'
                    Actual     = "selector1: $(if($selector1){'OK'}else{'MISSING'}), selector2: $(if($selector2){'OK'}else{'MISSING'})"
                    Status     = if ($dkimOk) { 'PASS' } else { 'FAIL' }
                    Severity   = 'High'
                    Remediation = if (-not $dkimOk) { "Add DKIM CNAME records for $domain at your DNS provider" } else { '' }
                })
            }
            catch { $results.Add([PSCustomObject]@{ Section = 'DNS'; Check = "DKIM for $domain"; Status = 'ERROR'; Actual = $_.ToString() }) }
        }
    }

    # ============================================================
    # DEFENDER CHECKS
    # ============================================================
    if ('Defender' -in $allServices) {
        Write-M365Log -Message "Auditing Defender..." -Level Info

        # CHECK: Preset security policies assigned (CISA MS.DEFENDER.1.2-1.5)
        try {
            $standardRule = Get-EOPProtectionPolicyRule -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like '*Standard*' }
            $strictRule = Get-EOPProtectionPolicyRule -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like '*Strict*' }

            $results.Add([PSCustomObject]@{
                Section    = 'Defender'
                Check      = 'Standard preset security policy assigned'
                Baseline   = 'CISA MS.DEFENDER.1.2v1'
                Expected   = 'Assigned to all users'
                Actual     = if ($standardRule) { "Active, Priority=$($standardRule.Priority)" } else { 'Not assigned' }
                Status     = if ($standardRule) { 'PASS' } else { 'FAIL' }
                Severity   = 'Critical'
                Remediation = if (-not $standardRule) { 'Enable Standard preset security policy in Defender portal > Preset security policies' } else { '' }
            })

            $results.Add([PSCustomObject]@{
                Section    = 'Defender'
                Check      = 'Strict preset for sensitive accounts'
                Baseline   = 'CISA MS.DEFENDER.1.4v1'
                Expected   = 'Assigned to sensitive accounts'
                Actual     = if ($strictRule) { "Active, Priority=$($strictRule.Priority)" } else { 'Not assigned' }
                Status     = if ($strictRule) { 'PASS' } else { 'WARN' }
                Severity   = 'High'
                Remediation = if (-not $strictRule) { 'Enable Strict preset for priority/sensitive accounts' } else { '' }
            })
        }
        catch { Write-M365Log -Message "Preset policy check failed: $_" -Level Warning }

        # CHECK: Anti-spam no allowed sender domains (CIS 2.1.14)
        try {
            $spamPolicies = Get-HostedContentFilterPolicy -ErrorAction Stop
            $hasAllowedDomains = $spamPolicies | Where-Object { $_.AllowedSenderDomains.Count -gt 0 }

            $results.Add([PSCustomObject]@{
                Section    = 'Defender'
                Check      = 'No allowed sender domains in anti-spam'
                Baseline   = 'CIS 2.1.14'
                Expected   = '0 policies with allowed domains'
                Actual     = "$($hasAllowedDomains.Count) policies have allowed domains"
                Status     = if ($hasAllowedDomains.Count -eq 0) { 'PASS' } else { 'FAIL' }
                Severity   = 'High'
                Remediation = if ($hasAllowedDomains.Count -gt 0) { 'Remove AllowedSenderDomains from: ' + ($hasAllowedDomains.Name -join ', ') } else { '' }
            })
        }
        catch { Write-M365Log -Message "Allowed domains check failed: $_" -Level Warning }
    }

    # ============================================================
    # SUMMARY
    # ============================================================
    $passed = ($results | Where-Object Status -eq 'PASS').Count
    $failed = ($results | Where-Object Status -eq 'FAIL').Count
    $warned = ($results | Where-Object Status -eq 'WARN').Count
    $errors = ($results | Where-Object Status -eq 'ERROR').Count
    $total  = $results.Count

    Write-M365Log -Message "Audit complete: $passed PASS, $failed FAIL, $warned WARN, $errors ERROR (of $total checks)" -Level Info

    # Add summary row
    $results.Insert(0, [PSCustomObject]@{
        Section    = 'SUMMARY'
        Check      = "Audit completed at $($timestamp.ToString('yyyy-MM-dd HH:mm:ss'))"
        Baseline   = ''
        Expected   = ''
        Actual     = "$passed PASS | $failed FAIL | $warned WARN | $errors ERROR"
        Status     = if ($failed -eq 0) { 'PASS' } else { 'FAIL' }
        Severity   = ''
        Remediation = ''
    })

    # Export
    foreach ($fmt in $OutputFormat) {
        switch ($fmt) {
            'Console' {
                Write-Host "`n=== M365 COMPLIANCE AUDIT ===" -ForegroundColor White
                Write-Host "Date: $($timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
                Write-Host "Result: $passed PASS | $failed FAIL | $warned WARN | $errors ERROR`n" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })

                foreach ($r in ($results | Where-Object Section -ne 'SUMMARY')) {
                    $color = switch ($r.Status) {
                        'PASS'  { 'Green' }
                        'FAIL'  { 'Red' }
                        'WARN'  { 'Yellow' }
                        'ERROR' { 'DarkRed' }
                        default { 'Gray' }
                    }
                    Write-Host "[$($r.Status.PadRight(5))] " -ForegroundColor $color -NoNewline
                    Write-Host "$($r.Section) > $($r.Check)" -NoNewline
                    if ($r.Status -ne 'PASS' -and $r.Remediation) {
                        Write-Host " -> $($r.Remediation)" -ForegroundColor DarkYellow
                    } else {
                        Write-Host ""
                    }
                }
                Write-Host ""
            }
            default {
                $results | Export-M365Report -Format $fmt -OutputPath $OutputPath -Title "M365 Compliance Audit $($timestamp.ToString('yyyy-MM-dd'))"
            }
        }
    }

    return $results
}
