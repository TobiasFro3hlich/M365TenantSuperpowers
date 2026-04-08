function Set-M365EXOExternalTag {
    <#
    .SYNOPSIS
        Enables or configures the external sender identification tag in Outlook.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXOExternalTag -ConfigName 'EXO-ExternalTag'
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
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('External Sender Tag', 'Configure external sender identification')) {
        Write-M365Log -Message "Configuring external sender tag..." -Level Info

        try {
            $params = @{}
            if ($null -ne $desired.Enabled) { $params['Enabled'] = $desired.Enabled }
            if ($desired.AllowList) { $params['AllowList'] = $desired.AllowList }

            Set-ExternalInOutlook @params -ErrorAction Stop

            Write-M365Log -Message "External sender tag configured (Enabled: $($desired.Enabled))." -Level Info
            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'External In Outlook'
                Enabled    = $desired.Enabled
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to configure external tag: $_" -Level Error
            throw
        }
    }
}
