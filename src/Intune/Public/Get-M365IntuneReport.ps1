function Get-M365IntuneReport {
    <#
    .SYNOPSIS
        Generates a report of current Intune configuration.
    .EXAMPLE
        Get-M365IntuneReport | Export-M365Report -Format HTML -Title 'Intune Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service Graph

    $report = [System.Collections.Generic.List[object]]::new()

    # Compliance settings
    try {
        $settings = Invoke-M365IntuneGraphRequest -Method GET `
            -Uri 'https://graph.microsoft.com/beta/deviceManagement/settings' `
            -Description 'Get compliance settings'
        $report.Add([PSCustomObject]@{ Section = 'Compliance Settings'; Setting = 'Secure By Default (no-policy = non-compliant)'; Value = $settings.secureByDefault })
        $report.Add([PSCustomObject]@{ Section = 'Compliance Settings'; Setting = 'Check-in Threshold Days'; Value = $settings.deviceComplianceCheckinThresholdDays })
    }
    catch { Write-M365Log -Message "Could not read compliance settings: $_" -Level Warning }

    # Compliance policies
    try {
        $policies = Invoke-M365IntuneGraphRequest -Method GET `
            -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies' `
            -Description 'Get compliance policies'
        $report.Add([PSCustomObject]@{ Section = 'Compliance Policies'; Setting = 'Total Policies'; Value = $policies.value.Count })
        foreach ($p in $policies.value) {
            $platform = switch -Wildcard ($p.'@odata.type') {
                '*windows10*' { 'Windows' }
                '*iosCompliancePolicy' { 'iOS' }
                '*android*' { 'Android' }
                '*macOS*' { 'macOS' }
                default { $p.'@odata.type' }
            }
            $report.Add([PSCustomObject]@{ Section = 'Compliance Policies'; Setting = "$($p.displayName) ($platform)"; Value = "Created: $($p.createdDateTime)" })
        }
    }
    catch { Write-M365Log -Message "Could not read compliance policies: $_" -Level Warning }

    # Enrollment restrictions
    try {
        $configs = Invoke-M365IntuneGraphRequest -Method GET `
            -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations' `
            -Description 'Get enrollment configs'
        $limitConfig = $configs.value | Where-Object { $_.'@odata.type' -like '*LimitConfiguration*' -and $_.priority -eq 0 }
        if ($limitConfig) {
            $report.Add([PSCustomObject]@{ Section = 'Enrollment'; Setting = 'Device Limit'; Value = $limitConfig.limit })
        }
        $platformConfig = $configs.value | Where-Object { $_.'@odata.type' -like '*PlatformRestrictions*' -and $_.priority -eq 0 }
        if ($platformConfig) {
            foreach ($platform in @('iosRestriction', 'androidRestriction', 'windowsRestriction', 'macOSRestriction')) {
                $r = $platformConfig.$platform
                if ($r) {
                    $report.Add([PSCustomObject]@{
                        Section = 'Enrollment'
                        Setting = "$platform — Personal Blocked"
                        Value   = $r.personalDeviceEnrollmentBlocked
                    })
                }
            }
        }
    }
    catch { Write-M365Log -Message "Could not read enrollment configs: $_" -Level Warning }

    # App protection policies
    try {
        $ios = Invoke-M365IntuneGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections' -Description 'Get iOS MAM'
        $android = Invoke-M365IntuneGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceAppManagement/androidManagedAppProtections' -Description 'Get Android MAM'
        $report.Add([PSCustomObject]@{ Section = 'App Protection'; Setting = 'iOS MAM Policies'; Value = $ios.value.Count })
        $report.Add([PSCustomObject]@{ Section = 'App Protection'; Setting = 'Android MAM Policies'; Value = $android.value.Count })
    }
    catch { Write-M365Log -Message "Could not read app protection: $_" -Level Warning }

    return $report
}
