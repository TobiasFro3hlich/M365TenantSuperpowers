function Set-M365EntraDeviceRegistration {
    <#
    .SYNOPSIS
        Configures the Entra ID device registration policy.
    .DESCRIPTION
        Controls who can join/register devices to Entra ID, device limits per user,
        and MFA requirements for device join.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraDeviceRegistration -ConfigName 'ENTRA-DeviceRegistration'
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

    Assert-M365Connection -Service Graph

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/EntraID/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Device Registration Policy', 'Update device registration settings')) {
        Write-M365Log -Message "Applying device registration policy..." -Level Info

        try {
            $body = @{}

            if ($desired.azureADJoin) {
                $body['azureADJoin'] = $desired.azureADJoin
            }
            if ($desired.azureADRegistration) {
                $body['azureADRegistration'] = $desired.azureADRegistration
            }
            if ($null -ne $desired.multiFactorAuthConfiguration) {
                $body['multiFactorAuthConfiguration'] = $desired.multiFactorAuthConfiguration
            }
            if ($null -ne $desired.userDeviceQuota) {
                $body['userDeviceQuota'] = $desired.userDeviceQuota
            }

            Invoke-M365EntraGraphRequest -Method PATCH `
                -Uri 'https://graph.microsoft.com/v1.0/policies/deviceRegistrationPolicy' `
                -Body $body `
                -Description 'Update device registration policy'

            Write-M365Log -Message "Device registration policy updated." -Level Info

            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'Device Registration Policy'
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update device registration policy: $_" -Level Error
            throw
        }
    }
}
