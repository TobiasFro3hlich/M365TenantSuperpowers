function Set-M365DefenderAntiPhish {
    <#
    .SYNOPSIS
        Configures anti-phishing policy with impersonation protection and spoof intelligence.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Defender/.
    .EXAMPLE
        Set-M365DefenderAntiPhish -ConfigName 'DEF-AntiPhish'
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
        $ConfigPath = Join-Path $moduleRoot "configs/Defender/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $policyName = $config.settings.policyName
    $policySettings = @{}
    $ruleSettings = @{}

    # Map policy settings
    $policyProps = @(
        'Enabled', 'PhishThresholdLevel',
        'EnableMailboxIntelligence', 'EnableMailboxIntelligenceProtection',
        'MailboxIntelligenceProtectionAction', 'MailboxIntelligenceQuarantineTag',
        'EnableSpoofIntelligence', 'SpoofQuarantineTag',
        'EnableFirstContactSafetyTips', 'EnableSimilarUsersSafetyTips',
        'EnableSimilarDomainsSafetyTips', 'EnableUnusualCharactersSafetyTips',
        'EnableUnauthenticatedSender', 'EnableViaTag',
        'AuthenticationFailAction', 'HonorDmarcPolicy',
        'EnableTargetedUserProtection', 'EnableTargetedDomainsProtection',
        'EnableOrganizationDomainsProtection',
        'TargetedUserProtectionAction', 'TargetedDomainProtectionAction',
        'TargetedUserQuarantineTag', 'TargetedDomainQuarantineTag',
        'ImpersonationProtectionState'
    )

    foreach ($prop in $policyProps) {
        if ($null -ne $config.settings.policy.$prop) {
            $policySettings[$prop] = $config.settings.policy.$prop
        }
    }

    if ($config.settings.policy.TargetedUsersToProtect) {
        $policySettings['TargetedUsersToProtect'] = $config.settings.policy.TargetedUsersToProtect
    }
    if ($config.settings.policy.TargetedDomainsToProtect) {
        $policySettings['TargetedDomainsToProtect'] = $config.settings.policy.TargetedDomainsToProtect
    }

    # Map rule settings
    if ($config.settings.rule) {
        foreach ($key in $config.settings.rule.Keys) {
            $ruleSettings[$key] = $config.settings.rule[$key]
        }
    }

    if ($PSCmdlet.ShouldProcess($policyName, "Apply anti-phishing policy")) {
        return Invoke-M365DefenderPolicy -PolicyType 'AntiPhish' -PolicySettings $policySettings -RuleSettings $ruleSettings -PolicyName $policyName
    }
}
