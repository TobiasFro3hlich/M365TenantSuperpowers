function Set-M365EntraPasswordProtection {
    <#
    .SYNOPSIS
        Configures Entra ID password protection settings (banned passwords, smart lockout).
    .DESCRIPTION
        Sets custom banned password lists and smart lockout thresholds to prevent
        weak passwords and brute force attacks.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraPasswordProtection -ConfigName 'ENTRA-PasswordProtection'
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

    if ($PSCmdlet.ShouldProcess('Password Protection', 'Update password protection settings')) {
        Write-M365Log -Message "Applying password protection settings..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # Update banned password list via directory settings
        # This uses the "Password Rule Settings" template
        try {
            # Get existing directory settings
            $dirSettings = Invoke-M365EntraGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/v1.0/settings' `
                -Description 'Get directory settings'

            $passwordSettings = $dirSettings.value | Where-Object { $_.displayName -eq 'Password Rule Settings' }

            $settingsValues = @()

            if ($desired.enableBannedPasswordCheck) {
                $settingsValues += @{
                    name  = 'EnableBannedPasswordCheck'
                    value = $desired.enableBannedPasswordCheck.ToString()
                }
            }
            if ($desired.bannedPasswordList) {
                $settingsValues += @{
                    name  = 'BannedPasswordList'
                    value = ($desired.bannedPasswordList -join ',')
                }
            }
            if ($desired.enableBannedPasswordCheckOnPremises) {
                $settingsValues += @{
                    name  = 'EnableBannedPasswordCheckOnPremises'
                    value = $desired.enableBannedPasswordCheckOnPremises.ToString()
                }
            }
            if ($desired.bannedPasswordCheckOnPremisesMode) {
                $settingsValues += @{
                    name  = 'BannedPasswordCheckOnPremisesMode'
                    value = $desired.bannedPasswordCheckOnPremisesMode
                }
            }
            if ($desired.lockoutThreshold) {
                $settingsValues += @{
                    name  = 'LockoutThreshold'
                    value = $desired.lockoutThreshold.ToString()
                }
            }
            if ($desired.lockoutDurationInSeconds) {
                $settingsValues += @{
                    name  = 'LockoutDurationInSeconds'
                    value = $desired.lockoutDurationInSeconds.ToString()
                }
            }

            $body = @{ values = $settingsValues }

            if ($passwordSettings) {
                # Update existing
                Invoke-M365EntraGraphRequest -Method PATCH `
                    -Uri "https://graph.microsoft.com/v1.0/settings/$($passwordSettings.id)" `
                    -Body $body `
                    -Description 'Update password rule settings'

                $results.Add([PSCustomObject]@{
                    Setting = 'Password Rule Settings'
                    Action  = 'Updated'
                    Changed = $true
                })
            }
            else {
                # Create new from template
                $templates = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri 'https://graph.microsoft.com/v1.0/directorySettingTemplates' `
                    -Description 'Get directory setting templates'

                $template = $templates.value | Where-Object { $_.displayName -eq 'Password Rule Settings' }

                if ($template) {
                    $createBody = @{
                        templateId = $template.id
                        values     = $settingsValues
                    }
                    Invoke-M365EntraGraphRequest -Method POST `
                        -Uri 'https://graph.microsoft.com/v1.0/settings' `
                        -Body $createBody `
                        -Description 'Create password rule settings'

                    $results.Add([PSCustomObject]@{
                        Setting = 'Password Rule Settings'
                        Action  = 'Created'
                        Changed = $true
                    })
                }
            }

            Write-M365Log -Message "Password protection settings applied." -Level Info
        }
        catch {
            Write-M365Log -Message "Failed to update password protection: $_" -Level Error
            $results.Add([PSCustomObject]@{
                Setting = 'Password Protection'
                Action  = 'Failed'
                Changed = $false
                Error   = $_.ToString()
            })
        }

        return $results
    }
}
