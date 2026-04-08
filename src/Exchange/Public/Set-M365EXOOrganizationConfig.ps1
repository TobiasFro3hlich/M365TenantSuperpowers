function Set-M365EXOOrganizationConfig {
    <#
    .SYNOPSIS
        Configures Exchange Online organization-wide settings.
    .DESCRIPTION
        Sets critical org-level EXO settings including audit logging, mail tips,
        OAuth, focused inbox, public folder quotas, and more.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXOOrganizationConfig -ConfigName 'EXO-OrganizationConfig'
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

    if ($PSCmdlet.ShouldProcess('Organization Configuration', 'Update EXO organization settings')) {
        Write-M365Log -Message "Applying EXO organization configuration..." -Level Info

        $params = @{}
        foreach ($key in $desired.Keys) {
            $params[$key] = $desired[$key]
        }

        try {
            Set-OrganizationConfig @params -ErrorAction Stop

            Write-M365Log -Message "EXO organization configuration updated." -Level Info
            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'Organization Config'
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update organization config: $_" -Level Error
            throw
        }
    }
}
