function Set-M365IntuneComplianceSettings {
    <#
    .SYNOPSIS
        Configures tenant-wide Intune compliance settings.
    .DESCRIPTION
        Sets whether devices without a compliance policy are marked as compliant or
        non-compliant. CIS 4.1 requires marking them as non-compliant.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Intune/.
    .EXAMPLE
        Set-M365IntuneComplianceSettings -ConfigName 'INTUNE-ComplianceSettings'
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
        $ConfigPath = Join-Path $moduleRoot "configs/Intune/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Intune Compliance Settings', 'Update device compliance settings')) {
        Write-M365Log -Message "Applying Intune compliance settings..." -Level Info

        try {
            # Get current settings
            $current = Invoke-M365IntuneGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/beta/deviceManagement/settings' `
                -Description 'Get device management settings'

            $body = @{
                deviceComplianceCheckinThresholdDays = $desired.deviceComplianceCheckinThresholdDays
                secureByDefault                     = $desired.secureByDefault
            }

            Invoke-M365IntuneGraphRequest -Method PATCH `
                -Uri 'https://graph.microsoft.com/beta/deviceManagement/settings' `
                -Body $body `
                -Description 'Update compliance settings'

            Write-M365Log -Message "Compliance settings updated (secureByDefault: $($desired.secureByDefault))." -Level Info

            return [PSCustomObject]@{
                ConfigName     = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting        = 'Compliance Settings'
                SecureByDefault = $desired.secureByDefault
                Action         = 'Updated'
                Changed        = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update compliance settings: $_" -Level Error
            throw
        }
    }
}
