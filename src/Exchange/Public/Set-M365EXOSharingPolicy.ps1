function Set-M365EXOSharingPolicy {
    <#
    .SYNOPSIS
        Configures the default Exchange Online sharing policy (calendar/contact sharing).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXOSharingPolicy -ConfigName 'EXO-SharingPolicy'
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
        $ConfigPath = Join-Path $moduleRoot "configs/Exchange/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $policyName = $config.settings.policyName
    $desired = $config.settings.policy

    if ($PSCmdlet.ShouldProcess($policyName, "Update sharing policy")) {
        Write-M365Log -Message "Applying sharing policy: $policyName" -Level Info

        $params = @{}
        if ($desired.Domains) { $params['Domains'] = $desired.Domains }
        if ($null -ne $desired.Enabled) { $params['Enabled'] = $desired.Enabled }
        if ($null -ne $desired.Default) { $params['Default'] = $desired.Default }

        try {
            Set-SharingPolicy -Identity $policyName @params -ErrorAction Stop

            Write-M365Log -Message "Sharing policy '$policyName' updated." -Level Info
            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = "Sharing Policy: $policyName"
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update sharing policy: $_" -Level Error
            throw
        }
    }
}
