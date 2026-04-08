function Get-M365PowerBIReport {
    <#
    .SYNOPSIS
        Generates a report of current Power BI tenant settings.
    .EXAMPLE
        Get-M365PowerBIReport | Export-M365Report -Format HTML -Title 'Power BI Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service Graph

    $report = [System.Collections.Generic.List[object]]::new()

    try {
        $settings = Invoke-MgGraphRequest -Method GET `
            -Uri 'https://api.powerbi.com/v1.0/myorg/admin/tenantSettings' `
            -ErrorAction Stop

        foreach ($setting in $settings.tenantSettings) {
            $report.Add([PSCustomObject]@{
                Section = $setting.tenantSettingGroup
                Setting = $setting.settingName
                Value   = $setting.enabled
            })
        }
    }
    catch {
        Write-M365Log -Message "Could not read Power BI tenant settings: $_" -Level Warning
        $report.Add([PSCustomObject]@{
            Section = 'Error'
            Setting = 'Power BI Admin API'
            Value   = "Access denied or API unavailable. Requires Power BI Admin role. Error: $_"
        })
    }

    return $report
}
