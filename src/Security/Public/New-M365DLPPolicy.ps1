function New-M365DLPPolicy {
    <#
    .SYNOPSIS
        Creates or updates a Data Loss Prevention policy from a JSON config.
    .DESCRIPTION
        Deploys DLP policies to protect sensitive information (PII, financial data, etc.)
        across Exchange, SharePoint, OneDrive, Teams, and endpoints. Required by
        CISA SCuBA MS.DEFENDER.4.1v2 and CIS 3.2.1.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Security/.
    .EXAMPLE
        New-M365DLPPolicy -ConfigName 'SEC-DLP-PII'
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

    # Check if policy exists
    $existing = Get-DlpCompliancePolicy -Identity $policyName -ErrorAction SilentlyContinue

    if ($PSCmdlet.ShouldProcess($policyName, "Create/Update DLP policy")) {
        Write-M365Log -Message "Applying DLP policy: $policyName" -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        try {
            $policyParams = @{}

            # Locations
            if ($desired.exchangeLocation) { $policyParams['ExchangeLocation'] = $desired.exchangeLocation }
            if ($desired.sharePointLocation) { $policyParams['SharePointLocation'] = $desired.sharePointLocation }
            if ($desired.oneDriveLocation) { $policyParams['OneDriveLocation'] = $desired.oneDriveLocation }
            if ($desired.teamsLocation) { $policyParams['TeamsLocation'] = $desired.teamsLocation }
            if ($null -ne $desired.mode) { $policyParams['Mode'] = $desired.mode }

            if ($existing) {
                Set-DlpCompliancePolicy -Identity $policyName @policyParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{ Component = 'DLP Policy'; Name = $policyName; Action = 'Updated'; Changed = $true })
            }
            else {
                New-DlpCompliancePolicy -Name $policyName @policyParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{ Component = 'DLP Policy'; Name = $policyName; Action = 'Created'; Changed = $true })
            }

            Write-M365Log -Message "DLP policy '$policyName' applied." -Level Info

            # Create/update rules
            if ($desired.rules) {
                foreach ($rule in $desired.rules) {
                    $ruleName = $rule.name
                    $existingRule = Get-DlpComplianceRule -Identity $ruleName -ErrorAction SilentlyContinue

                    $ruleParams = @{
                        Policy = $policyName
                    }
                    if ($rule.contentContainsSensitiveInformation) {
                        $ruleParams['ContentContainsSensitiveInformation'] = $rule.contentContainsSensitiveInformation
                    }
                    if ($rule.blockAccess) { $ruleParams['BlockAccess'] = $rule.blockAccess }
                    if ($rule.blockAccessScope) { $ruleParams['BlockAccessScope'] = $rule.blockAccessScope }
                    if ($null -ne $rule.notifyUser) { $ruleParams['NotifyUser'] = $rule.notifyUser }
                    if ($null -ne $rule.notifyPolicyTipCustomText) { $ruleParams['NotifyPolicyTipCustomText'] = $rule.notifyPolicyTipCustomText }
                    if ($null -ne $rule.generateIncidentReport) { $ruleParams['GenerateIncidentReport'] = $rule.generateIncidentReport }

                    try {
                        if ($existingRule) {
                            $ruleParams.Remove('Policy')
                            Set-DlpComplianceRule -Identity $ruleName @ruleParams -ErrorAction Stop
                            $results.Add([PSCustomObject]@{ Component = 'DLP Rule'; Name = $ruleName; Action = 'Updated'; Changed = $true })
                        }
                        else {
                            New-DlpComplianceRule -Name $ruleName @ruleParams -ErrorAction Stop
                            $results.Add([PSCustomObject]@{ Component = 'DLP Rule'; Name = $ruleName; Action = 'Created'; Changed = $true })
                        }
                        Write-M365Log -Message "DLP rule '$ruleName' applied." -Level Info
                    }
                    catch {
                        Write-M365Log -Message "Failed to apply DLP rule '$ruleName': $_" -Level Error
                        $results.Add([PSCustomObject]@{ Component = 'DLP Rule'; Name = $ruleName; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
                    }
                }
            }
        }
        catch {
            Write-M365Log -Message "Failed to apply DLP policy '$policyName': $_" -Level Error
            $results.Add([PSCustomObject]@{ Component = 'DLP Policy'; Name = $policyName; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
        }

        return $results
    }
}
