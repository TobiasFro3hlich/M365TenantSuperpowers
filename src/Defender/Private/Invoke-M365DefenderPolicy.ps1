function Invoke-M365DefenderPolicy {
    <#
    .SYNOPSIS
        Generic helper to apply a Defender/EOP policy+rule pair from a config.
    .DESCRIPTION
        Handles the common pattern: check if policy exists, create or update it,
        then create or update the associated rule.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PolicyType,

        [Parameter(Mandatory)]
        [hashtable]$PolicySettings,

        [Parameter()]
        [hashtable]$RuleSettings,

        [Parameter(Mandatory)]
        [string]$PolicyName
    )

    $results = [System.Collections.Generic.List[object]]::new()

    # Map policy type to cmdlets
    $cmdletMap = @{
        'AntiPhish' = @{
            Get    = 'Get-AntiPhishPolicy'
            New    = 'New-AntiPhishPolicy'
            Set    = 'Set-AntiPhishPolicy'
            GetRule = 'Get-AntiPhishRule'
            NewRule = 'New-AntiPhishRule'
            SetRule = 'Set-AntiPhishRule'
        }
        'AntiSpam' = @{
            Get    = 'Get-HostedContentFilterPolicy'
            New    = 'New-HostedContentFilterPolicy'
            Set    = 'Set-HostedContentFilterPolicy'
            GetRule = 'Get-HostedContentFilterRule'
            NewRule = 'New-HostedContentFilterRule'
            SetRule = 'Set-HostedContentFilterRule'
        }
        'AntiMalware' = @{
            Get    = 'Get-MalwareFilterPolicy'
            New    = 'New-MalwareFilterPolicy'
            Set    = 'Set-MalwareFilterPolicy'
            GetRule = 'Get-MalwareFilterRule'
            NewRule = 'New-MalwareFilterRule'
            SetRule = 'Set-MalwareFilterRule'
        }
        'SafeLinks' = @{
            Get    = 'Get-SafeLinksPolicy'
            New    = 'New-SafeLinksPolicy'
            Set    = 'Set-SafeLinksPolicy'
            GetRule = 'Get-SafeLinksRule'
            NewRule = 'New-SafeLinksRule'
            SetRule = 'Set-SafeLinksRule'
        }
        'SafeAttachments' = @{
            Get    = 'Get-SafeAttachmentPolicy'
            New    = 'New-SafeAttachmentPolicy'
            Set    = 'Set-SafeAttachmentPolicy'
            GetRule = 'Get-SafeAttachmentRule'
            NewRule = 'New-SafeAttachmentRule'
            SetRule = 'Set-SafeAttachmentRule'
        }
    }

    $cmdlets = $cmdletMap[$PolicyType]
    if (-not $cmdlets) {
        throw "Unknown policy type: $PolicyType"
    }

    # Check if policy exists
    $existing = & $cmdlets.Get -Identity $PolicyName -ErrorAction SilentlyContinue

    try {
        if ($existing) {
            Write-M365Log -Message "Updating $PolicyType policy: $PolicyName" -Level Info
            & $cmdlets.Set -Identity $PolicyName @PolicySettings -ErrorAction Stop
            $results.Add([PSCustomObject]@{
                Component = "$PolicyType Policy"
                Name      = $PolicyName
                Action    = 'Updated'
                Changed   = $true
            })
        }
        else {
            Write-M365Log -Message "Creating $PolicyType policy: $PolicyName" -Level Info
            & $cmdlets.New -Name $PolicyName @PolicySettings -ErrorAction Stop
            $results.Add([PSCustomObject]@{
                Component = "$PolicyType Policy"
                Name      = $PolicyName
                Action    = 'Created'
                Changed   = $true
            })
        }
    }
    catch {
        Write-M365Log -Message "Failed to apply $PolicyType policy '$PolicyName': $_" -Level Error
        $results.Add([PSCustomObject]@{
            Component = "$PolicyType Policy"
            Name      = $PolicyName
            Action    = 'Failed'
            Changed   = $false
            Error     = $_.ToString()
        })
        return $results
    }

    # Apply rule if settings provided
    if ($RuleSettings -and $RuleSettings.Count -gt 0) {
        $ruleName = "$PolicyName Rule"
        $existingRule = & $cmdlets.GetRule -Identity $ruleName -ErrorAction SilentlyContinue

        try {
            $ruleParams = $RuleSettings.Clone()
            if ($existingRule) {
                Write-M365Log -Message "Updating $PolicyType rule: $ruleName" -Level Info
                & $cmdlets.SetRule -Identity $ruleName @ruleParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{
                    Component = "$PolicyType Rule"
                    Name      = $ruleName
                    Action    = 'Updated'
                    Changed   = $true
                })
            }
            else {
                Write-M365Log -Message "Creating $PolicyType rule: $ruleName" -Level Info
                $ruleParams["${PolicyType}Policy"] = $PolicyName
                if (-not $ruleParams.ContainsKey("${PolicyType}Policy")) {
                    # Use the mapped policy parameter name
                    switch ($PolicyType) {
                        'AntiPhish'       { $ruleParams['AntiPhishPolicy'] = $PolicyName }
                        'AntiSpam'        { $ruleParams['HostedContentFilterPolicy'] = $PolicyName }
                        'AntiMalware'     { $ruleParams['MalwareFilterPolicy'] = $PolicyName }
                        'SafeLinks'       { $ruleParams['SafeLinksPolicy'] = $PolicyName }
                        'SafeAttachments' { $ruleParams['SafeAttachmentPolicy'] = $PolicyName }
                    }
                }
                & $cmdlets.NewRule -Name $ruleName @ruleParams -ErrorAction Stop
                $results.Add([PSCustomObject]@{
                    Component = "$PolicyType Rule"
                    Name      = $ruleName
                    Action    = 'Created'
                    Changed   = $true
                })
            }
        }
        catch {
            Write-M365Log -Message "Failed to apply $PolicyType rule: $_" -Level Error
            $results.Add([PSCustomObject]@{
                Component = "$PolicyType Rule"
                Name      = $ruleName
                Action    = 'Failed'
                Changed   = $false
                Error     = $_.ToString()
            })
        }
    }

    return $results
}
