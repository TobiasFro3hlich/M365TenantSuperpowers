function Set-M365EXOMobilePolicy {
    <#
    .SYNOPSIS
        Configures mobile device mailbox policy (PIN, encryption, app restrictions).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXOMobilePolicy -ConfigName 'EXO-MobilePolicy'
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

    if ($PSCmdlet.ShouldProcess($policyName, "Update mobile device policy")) {
        Write-M365Log -Message "Applying mobile device policy: $policyName" -Level Info

        $params = @{}
        foreach ($key in $desired.Keys) {
            $params[$key] = $desired[$key]
        }

        try {
            Set-MobileDeviceMailboxPolicy -Identity $policyName @params -ErrorAction Stop

            Write-M365Log -Message "Mobile device policy '$policyName' updated." -Level Info
            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = "Mobile Policy: $policyName"
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update mobile policy: $_" -Level Error
            throw
        }
    }
}
