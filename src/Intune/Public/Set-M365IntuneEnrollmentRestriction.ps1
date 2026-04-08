function Set-M365IntuneEnrollmentRestriction {
    <#
    .SYNOPSIS
        Configures device enrollment restrictions (platform, limit, personal devices).
    .DESCRIPTION
        Sets which platforms can enroll, whether personal devices are blocked,
        minimum OS versions, and per-user device limits.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Intune/.
    .EXAMPLE
        Set-M365IntuneEnrollmentRestriction -ConfigName 'INTUNE-EnrollmentRestriction'
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

    if ($PSCmdlet.ShouldProcess('Enrollment Restrictions', 'Update enrollment restrictions')) {
        Write-M365Log -Message "Applying enrollment restrictions..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # Device limit restriction
        if ($desired.deviceLimit) {
            try {
                # Get default device limit restriction
                $restrictions = Invoke-M365IntuneGraphRequest -Method GET `
                    -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations' `
                    -Description 'Get enrollment configurations'

                $limitConfig = $restrictions.value | Where-Object {
                    $_.'@odata.type' -eq '#microsoft.graph.deviceEnrollmentLimitConfiguration' -and $_.priority -eq 0
                }

                if ($limitConfig) {
                    $body = @{
                        '@odata.type' = '#microsoft.graph.deviceEnrollmentLimitConfiguration'
                        limit         = $desired.deviceLimit
                    }
                    Invoke-M365IntuneGraphRequest -Method PATCH `
                        -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations/$($limitConfig.id)" `
                        -Body $body `
                        -Description 'Update device limit'

                    $results.Add([PSCustomObject]@{ Setting = 'Device Limit'; Value = $desired.deviceLimit; Action = 'Updated'; Changed = $true })
                    Write-M365Log -Message "Device enrollment limit set to: $($desired.deviceLimit)" -Level Info
                }
            }
            catch {
                Write-M365Log -Message "Failed to set device limit: $_" -Level Error
                $results.Add([PSCustomObject]@{ Setting = 'Device Limit'; Action = 'Failed'; Changed = $false })
            }
        }

        # Platform restriction (block personal devices)
        if ($desired.platformRestriction) {
            try {
                $restrictions = Invoke-M365IntuneGraphRequest -Method GET `
                    -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations' `
                    -Description 'Get enrollment configurations'

                $platformConfig = $restrictions.value | Where-Object {
                    $_.'@odata.type' -eq '#microsoft.graph.deviceEnrollmentPlatformRestrictionsConfiguration' -and $_.priority -eq 0
                }

                if ($platformConfig) {
                    $body = @{
                        '@odata.type' = '#microsoft.graph.deviceEnrollmentPlatformRestrictionsConfiguration'
                    }

                    foreach ($platform in @('iosRestriction', 'androidRestriction', 'windowsRestriction', 'macOSRestriction')) {
                        if ($desired.platformRestriction.$platform) {
                            $body[$platform] = $desired.platformRestriction.$platform
                        }
                    }

                    Invoke-M365IntuneGraphRequest -Method PATCH `
                        -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations/$($platformConfig.id)" `
                        -Body $body `
                        -Description 'Update platform restrictions'

                    $results.Add([PSCustomObject]@{ Setting = 'Platform Restrictions'; Action = 'Updated'; Changed = $true })
                    Write-M365Log -Message "Platform enrollment restrictions updated." -Level Info
                }
            }
            catch {
                Write-M365Log -Message "Failed to set platform restrictions: $_" -Level Error
                $results.Add([PSCustomObject]@{ Setting = 'Platform Restrictions'; Action = 'Failed'; Changed = $false })
            }
        }

        return $results
    }
}
