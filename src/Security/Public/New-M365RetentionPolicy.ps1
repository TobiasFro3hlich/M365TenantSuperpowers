function New-M365RetentionPolicy {
    <#
    .SYNOPSIS
        Creates or updates a retention policy.
    .DESCRIPTION
        Deploys retention policies to retain or delete content across Exchange,
        SharePoint, OneDrive, Teams, and other workloads.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Security/.
    .EXAMPLE
        New-M365RetentionPolicy -ConfigName 'SEC-RetentionDefault'
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
    $policyName = $desired.policyName

    if ($PSCmdlet.ShouldProcess($policyName, "Create/Update retention policy")) {
        Write-M365Log -Message "Applying retention policy: $policyName" -Level Info

        $existing = Get-RetentionCompliancePolicy -Identity $policyName -ErrorAction SilentlyContinue

        $policyParams = @{}
        if ($desired.exchangeLocation) { $policyParams['ExchangeLocation'] = $desired.exchangeLocation }
        if ($desired.sharePointLocation) { $policyParams['SharePointLocation'] = $desired.sharePointLocation }
        if ($desired.oneDriveLocation) { $policyParams['OneDriveLocation'] = $desired.oneDriveLocation }
        if ($desired.teamsChannelLocation) { $policyParams['TeamsChannelLocation'] = $desired.teamsChannelLocation }
        if ($desired.teamsChatLocation) { $policyParams['TeamsChatLocation'] = $desired.teamsChatLocation }
        if ($null -ne $desired.enabled) { $policyParams['Enabled'] = $desired.enabled }

        $results = [System.Collections.Generic.List[object]]::new()

        try {
            if ($existing) {
                Set-RetentionCompliancePolicy -Identity $policyName @policyParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{ Component = 'Retention Policy'; Name = $policyName; Action = 'Updated'; Changed = $true })
            }
            else {
                New-RetentionCompliancePolicy -Name $policyName @policyParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{ Component = 'Retention Policy'; Name = $policyName; Action = 'Created'; Changed = $true })
            }

            # Apply retention rules
            if ($desired.rules) {
                foreach ($rule in $desired.rules) {
                    $ruleName = $rule.name
                    $existingRule = Get-RetentionComplianceRule -Policy $policyName -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $ruleName }

                    $ruleParams = @{}
                    if ($rule.retentionDuration) { $ruleParams['RetentionDuration'] = $rule.retentionDuration }
                    if ($rule.retentionDurationDisplayHint) { $ruleParams['RetentionDurationDisplayHint'] = $rule.retentionDurationDisplayHint }
                    if ($rule.retentionComplianceAction) { $ruleParams['RetentionComplianceAction'] = $rule.retentionComplianceAction }
                    if ($rule.expirationDateOption) { $ruleParams['ExpirationDateOption'] = $rule.expirationDateOption }

                    try {
                        if ($existingRule) {
                            Set-RetentionComplianceRule -Identity $ruleName @ruleParams -ErrorAction Stop
                            $results.Add([PSCustomObject]@{ Component = 'Retention Rule'; Name = $ruleName; Action = 'Updated'; Changed = $true })
                        }
                        else {
                            New-RetentionComplianceRule -Name $ruleName -Policy $policyName @ruleParams -ErrorAction Stop
                            $results.Add([PSCustomObject]@{ Component = 'Retention Rule'; Name = $ruleName; Action = 'Created'; Changed = $true })
                        }
                    }
                    catch {
                        Write-M365Log -Message "Failed to apply retention rule '$ruleName': $_" -Level Error
                        $results.Add([PSCustomObject]@{ Component = 'Retention Rule'; Name = $ruleName; Action = 'Failed'; Changed = $false })
                    }
                }
            }

            Write-M365Log -Message "Retention policy '$policyName' applied." -Level Info
        }
        catch {
            Write-M365Log -Message "Failed to apply retention policy: $_" -Level Error
            $results.Add([PSCustomObject]@{ Component = 'Retention Policy'; Name = $policyName; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
        }

        return $results
    }
}
