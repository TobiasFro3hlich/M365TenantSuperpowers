function Set-M365EntraSecurityDefaults {
    <#
    .SYNOPSIS
        Enables or disables Entra ID Security Defaults.
    .DESCRIPTION
        Security Defaults provide a basic level of security (MFA for all, block legacy auth).
        When using Conditional Access policies, Security Defaults should typically be DISABLED
        as they conflict with CA policies.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .PARAMETER Enabled
        Directly set Security Defaults enabled state. Use this for quick toggle.
    .EXAMPLE
        Set-M365EntraSecurityDefaults -ConfigName 'ENTRA-SecurityDefaults'
    .EXAMPLE
        Set-M365EntraSecurityDefaults -Enabled $false
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByConfig')]
        [string]$ConfigName,

        [Parameter(Mandatory, ParameterSetName = 'ByValue')]
        [bool]$Enabled,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    if ($PSCmdlet.ParameterSetName -eq 'ByConfig') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $configPath = Join-Path $moduleRoot "configs/EntraID/$ConfigName.json"
        $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters
        $Enabled = $config.settings.isEnabled
    }

    # Read current state
    $current = Invoke-M365EntraGraphRequest -Method GET `
        -Uri 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy' `
        -Description 'Get security defaults state'

    if ($current.isEnabled -eq $Enabled) {
        Write-M365Log -Message "Security Defaults already set to: $Enabled. No change needed." -Level Info
        return [PSCustomObject]@{
            Setting = 'Security Defaults'
            State   = $Enabled
            Action  = 'NoChange'
            Changed = $false
        }
    }

    $stateText = if ($Enabled) { 'ENABLE' } else { 'DISABLE' }

    if ($PSCmdlet.ShouldProcess("Security Defaults", "$stateText Security Defaults")) {
        Write-M365Log -Message "Setting Security Defaults to: $Enabled" -Level Info

        try {
            Invoke-M365EntraGraphRequest -Method PATCH `
                -Uri 'https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy' `
                -Body @{ isEnabled = $Enabled } `
                -Description "Set security defaults to $Enabled"

            Write-M365Log -Message "Security Defaults set to: $Enabled" -Level Info

            return [PSCustomObject]@{
                Setting = 'Security Defaults'
                State   = $Enabled
                Action  = 'Updated'
                Changed = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to set Security Defaults: $_" -Level Error
            throw
        }
    }
}
