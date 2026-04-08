function Set-M365SPOAccessControl {
    <#
    .SYNOPSIS
        Configures SharePoint Online access control and conditional access settings.
    .DESCRIPTION
        Sets unmanaged device access, browser idle signout, IP restrictions,
        and conditional access enforcement for SharePoint and OneDrive.
    .PARAMETER ConfigName
        Name of the JSON config from configs/SharePoint/.
    .EXAMPLE
        Set-M365SPOAccessControl -ConfigName 'SPO-AccessControl'
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

    Assert-M365Connection -Service SharePoint

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/SharePoint/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('SPO Access Control', 'Update access control settings')) {
        Write-M365Log -Message "Applying SPO access control settings..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # Tenant-level access control
        $tenantParams = @{}
        $tenantProps = @(
            'ConditionalAccessPolicy', 'DisallowInfectedFileDownload',
            'IPAddressEnforcement', 'IPAddressAllowList',
            'IPAddressWACTokenLifetime',
            'AllowDownloadingNonWebViewableFiles',
            'BlockDownloadLinksFileType'
        )

        foreach ($prop in $tenantProps) {
            if ($null -ne $desired[$prop]) {
                $tenantParams[$prop] = $desired[$prop]
            }
        }

        if ($tenantParams.Count -gt 0) {
            try {
                Set-PnPTenant @tenantParams -ErrorAction Stop
                Write-M365Log -Message "SPO access control settings updated." -Level Info
                $results.Add([PSCustomObject]@{
                    Setting = 'Access Control'
                    Action  = 'Updated'
                    Changed = $true
                })
            }
            catch {
                Write-M365Log -Message "Failed to update access control: $_" -Level Error
                $results.Add([PSCustomObject]@{
                    Setting = 'Access Control'
                    Action  = 'Failed'
                    Changed = $false
                    Error   = $_.ToString()
                })
            }
        }

        # Browser idle signout
        if ($desired.BrowserIdleSignout) {
            $idleSettings = $desired.BrowserIdleSignout
            try {
                Set-PnPBrowserIdleSignout `
                    -Enabled:$idleSettings.Enabled `
                    -WarnAfter (New-TimeSpan -Minutes $idleSettings.WarnAfterMinutes) `
                    -SignOutAfter (New-TimeSpan -Minutes $idleSettings.SignOutAfterMinutes) `
                    -ErrorAction Stop

                Write-M365Log -Message "Browser idle signout: Enabled=$($idleSettings.Enabled), Warn=$($idleSettings.WarnAfterMinutes)m, SignOut=$($idleSettings.SignOutAfterMinutes)m" -Level Info
                $results.Add([PSCustomObject]@{
                    Setting = 'Browser Idle Signout'
                    Action  = 'Updated'
                    Changed = $true
                })
            }
            catch {
                Write-M365Log -Message "Failed to set browser idle signout: $_" -Level Error
                $results.Add([PSCustomObject]@{
                    Setting = 'Browser Idle Signout'
                    Action  = 'Failed'
                    Changed = $false
                    Error   = $_.ToString()
                })
            }
        }

        return $results
    }
}
