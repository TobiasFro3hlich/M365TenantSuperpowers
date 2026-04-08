function Set-M365DefenderSafeLinks {
    <#
    .SYNOPSIS
        Configures Safe Links policy (URL rewriting, real-time scanning, click tracking).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Defender/.
    .EXAMPLE
        Set-M365DefenderSafeLinks -ConfigName 'DEF-SafeLinks'
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
        'EnableSafeLinksForEmail', 'EnableSafeLinksForTeams', 'EnableSafeLinksForOffice',
        'ScanUrls', 'DeliverMessageAfterScan', 'EnableForInternalSenders',
        'TrackClicks', 'AllowClickThrough',
        'EnableOrganizationBranding', 'DisableUrlRewrite',
        'CustomNotificationText'
    )

    foreach ($prop in $policyProps) {
        if ($null -ne $config.settings.policy.$prop) {
            $policySettings[$prop] = $config.settings.policy.$prop
        }
    }

    if ($config.settings.policy.DoNotRewriteUrls) {
        $policySettings['DoNotRewriteUrls'] = $config.settings.policy.DoNotRewriteUrls
    }

    if ($config.settings.rule) {
        foreach ($key in $config.settings.rule.Keys) {
            $ruleSettings[$key] = $config.settings.rule[$key]
        }
    }

    if ($PSCmdlet.ShouldProcess($policyName, "Apply Safe Links policy")) {
        return Invoke-M365DefenderPolicy -PolicyType 'SafeLinks' -PolicySettings $policySettings -RuleSettings $ruleSettings -PolicyName $policyName
    }
}
