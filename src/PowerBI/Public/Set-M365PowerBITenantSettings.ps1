function Set-M365PowerBITenantSettings {
    <#
    .SYNOPSIS
        Configures Power BI / Microsoft Fabric tenant settings.
    .DESCRIPTION
        Sets tenant-wide Power BI settings including guest access, publish to web,
        external sharing, service principal access, sensitivity labels, and R/Python visuals.
        Covers CIS 9.x controls.
    .PARAMETER ConfigName
        Name of the JSON config from configs/PowerBI/.
    .EXAMPLE
        Set-M365PowerBITenantSettings -ConfigName 'PBI-TenantSettings'
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
        $ConfigPath = Join-Path $moduleRoot "configs/PowerBI/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Power BI Tenant Settings', 'Update Power BI configuration')) {
        Write-M365Log -Message "Applying Power BI tenant settings..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # Power BI Admin API uses a different endpoint pattern
        # Each setting is updated individually via the Power BI REST API
        foreach ($setting in $desired.tenantSettings) {
            $settingName = $setting.settingName
            $settingValue = $setting.enabled

            try {
                # Use Graph API for Fabric/Power BI admin settings
                $body = @{
                    settingName = $settingName
                    enabled     = $settingValue
                }

                if ($setting.tenantSettingGroup) {
                    $body['tenantSettingGroup'] = $setting.tenantSettingGroup
                }

                # Apply via Power BI Admin API
                Invoke-MgGraphRequest -Method PATCH `
                    -Uri "https://api.powerbi.com/v1.0/myorg/admin/tenantSettings" `
                    -Body ($body | ConvertTo-Json -Depth 5) `
                    -ContentType 'application/json' `
                    -ErrorAction Stop

                $results.Add([PSCustomObject]@{
                    Setting = $settingName
                    Enabled = $settingValue
                    Action  = 'Updated'
                    Changed = $true
                })
                Write-M365Log -Message "Power BI setting '$settingName' set to: $settingValue" -Level Info
            }
            catch {
                # Fallback: some settings may need Power BI PowerShell module
                Write-M365Log -Message "Graph API failed for '$settingName', may require Power BI Admin portal: $_" -Level Warning
                $results.Add([PSCustomObject]@{
                    Setting = $settingName
                    Enabled = $settingValue
                    Action  = 'ManualRequired'
                    Changed = $false
                    Note    = 'Configure in Power BI Admin Portal > Tenant Settings'
                })
            }
        }

        return $results
    }
}
