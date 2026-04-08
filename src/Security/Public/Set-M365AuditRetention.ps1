function Set-M365AuditRetention {
    <#
    .SYNOPSIS
        Configures unified audit log retention policies.
    .DESCRIPTION
        Creates audit log retention policies to retain specific audit activities
        for extended periods. Required by CISA SCuBA MS.DEFENDER.6.1v1/6.3v1
        and CIS 3.1.1.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Security/.
    .EXAMPLE
        Set-M365AuditRetention -ConfigName 'SEC-AuditRetention'
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

    Assert-M365Connection -Service ExchangeOnline

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/Security/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Audit Retention', 'Configure audit log retention')) {
        Write-M365Log -Message "Applying audit retention policies..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # Ensure audit is enabled
        try {
            $adminAudit = Get-AdminAuditLogConfig -ErrorAction Stop
            if (-not $adminAudit.UnifiedAuditLogIngestionEnabled) {
                Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -ErrorAction Stop
                Write-M365Log -Message "Unified audit logging enabled." -Level Info
                $results.Add([PSCustomObject]@{ Component = 'Audit Logging'; Action = 'Enabled'; Changed = $true })
            }
            else {
                $results.Add([PSCustomObject]@{ Component = 'Audit Logging'; Action = 'AlreadyEnabled'; Changed = $false })
            }
        }
        catch {
            Write-M365Log -Message "Failed to check/enable audit logging: $_" -Level Error
            $results.Add([PSCustomObject]@{ Component = 'Audit Logging'; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
        }

        # Create retention policies
        if ($desired.retentionPolicies) {
            foreach ($policy in $desired.retentionPolicies) {
                $policyName = $policy.name
                try {
                    $existing = Get-UnifiedAuditLogRetentionPolicy -Identity $policyName -ErrorAction SilentlyContinue

                    $policyParams = @{
                        RetentionDuration = $policy.retentionDuration
                        Priority          = $policy.priority
                    }
                    if ($policy.operations) { $policyParams['Operations'] = $policy.operations }
                    if ($policy.recordTypes) { $policyParams['RecordType'] = $policy.recordTypes }

                    if ($existing) {
                        Set-UnifiedAuditLogRetentionPolicy -Identity $policyName @policyParams -ErrorAction Stop
                        $results.Add([PSCustomObject]@{ Component = 'Audit Retention Policy'; Name = $policyName; Action = 'Updated'; Changed = $true })
                    }
                    else {
                        New-UnifiedAuditLogRetentionPolicy -Name $policyName @policyParams -ErrorAction Stop
                        $results.Add([PSCustomObject]@{ Component = 'Audit Retention Policy'; Name = $policyName; Action = 'Created'; Changed = $true })
                    }
                    Write-M365Log -Message "Audit retention policy '$policyName' applied." -Level Info
                }
                catch {
                    Write-M365Log -Message "Failed to apply audit retention '$policyName': $_" -Level Error
                    $results.Add([PSCustomObject]@{ Component = 'Audit Retention Policy'; Name = $policyName; Action = 'Failed'; Changed = $false })
                }
            }
        }

        return $results
    }
}
