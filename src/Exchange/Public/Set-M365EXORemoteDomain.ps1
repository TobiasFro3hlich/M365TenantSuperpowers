function Set-M365EXORemoteDomain {
    <#
    .SYNOPSIS
        Configures the default remote domain settings (message format, OOF, NDR).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXORemoteDomain -ConfigName 'EXO-RemoteDomain'
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

    if ($PSCmdlet.ShouldProcess('Default Remote Domain', "Update remote domain settings")) {
        Write-M365Log -Message "Applying remote domain settings..." -Level Info

        $params = @{}
        $props = @(
            'AllowedOOFType', 'AutoForwardEnabled', 'AutoReplyEnabled',
            'DeliveryReportEnabled', 'NDREnabled', 'TNEFEnabled',
            'CharacterSet', 'ContentType'
        )
        foreach ($prop in $props) {
            if ($null -ne $desired[$prop]) {
                $params[$prop] = $desired[$prop]
            }
        }

        try {
            Set-RemoteDomain -Identity 'Default' @params -ErrorAction Stop

            Write-M365Log -Message "Remote domain 'Default' updated." -Level Info
            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'Remote Domain: Default'
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update remote domain: $_" -Level Error
            throw
        }
    }
}
