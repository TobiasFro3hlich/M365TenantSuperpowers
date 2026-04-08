function Set-M365DefenderSafeAttachments {
    <#
    .SYNOPSIS
        Configures Safe Attachments policy (detonation, dynamic delivery, redirect).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Defender/.
    .EXAMPLE
        Set-M365DefenderSafeAttachments -ConfigName 'DEF-SafeAttachments'
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
        'Enable', 'Action', 'ActionOnError',
        'Redirect', 'RedirectAddress',
        'QuarantineTag'
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

    if ($PSCmdlet.ShouldProcess($policyName, "Apply Safe Attachments policy")) {
        return Invoke-M365DefenderPolicy -PolicyType 'SafeAttachments' -PolicySettings $policySettings -RuleSettings $ruleSettings -PolicyName $policyName
    }
}
