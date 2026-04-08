function Set-M365DefenderAntiSpam {
    <#
    .SYNOPSIS
        Configures inbound anti-spam (hosted content filter) policy.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Defender/.
    .EXAMPLE
        Set-M365DefenderAntiSpam -ConfigName 'DEF-AntiSpam'
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

    $policyProps = @(
        'SpamAction', 'HighConfidenceSpamAction', 'PhishSpamAction',
        'HighConfidencePhishAction', 'BulkSpamAction',
        'BulkThreshold', 'QuarantineRetentionPeriod',
        'InlineSafetyTipsEnabled', 'SpamZapEnabled', 'PhishZapEnabled',
        'MarkAsSpamBulkMail', 'IncreaseScoreWithImageLinks',
        'IncreaseScoreWithNumericIps', 'IncreaseScoreWithRedirectToOtherPort',
        'IncreaseScoreWithBizOrInfoUrls',
        'MarkAsSpamEmptyMessages', 'MarkAsSpamJavaScriptInHtml',
        'MarkAsSpamFramesInHtml', 'MarkAsSpamObjectTagsInHtml',
        'MarkAsSpamEmbedTagsInHtml', 'MarkAsSpamFormTagsInHtml',
        'MarkAsSpamWebBugsInHtml', 'MarkAsSpamSensitiveWordList',
        'MarkAsSpamSpfRecordHardFail', 'MarkAsSpamFromAddressAuthFail',
        'MarkAsSpamNdrBackscatter',
        'SpamQuarantineTag', 'HighConfidenceSpamQuarantineTag',
        'PhishQuarantineTag', 'HighConfidencePhishQuarantineTag',
        'BulkQuarantineTag'
    )

    foreach ($prop in $policyProps) {
        if ($null -ne $config.settings.policy.$prop) {
            $policySettings[$prop] = $config.settings.policy.$prop
        }
    }

    if ($config.settings.rule) {
        foreach ($key in $config.settings.rule.Keys) {
            $ruleSettings[$key] = $config.settings.rule[$key]
        }
    }

    if ($PSCmdlet.ShouldProcess($policyName, "Apply anti-spam policy")) {
        return Invoke-M365DefenderPolicy -PolicyType 'AntiSpam' -PolicySettings $policySettings -RuleSettings $ruleSettings -PolicyName $policyName
    }
}
