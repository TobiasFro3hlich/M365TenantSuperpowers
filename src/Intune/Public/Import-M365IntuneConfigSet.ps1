function Import-M365IntuneConfigSet {
    <#
    .SYNOPSIS
        Applies a set of Intune configurations.
    .PARAMETER ConfigNames
        Array of config names (without .json) to apply.
    .EXAMPLE
        Import-M365IntuneConfigSet -ConfigNames 'INTUNE-ComplianceSettings', 'INTUNE-ComplianceWindows', 'INTUNE-AppProtectioniOS'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ConfigNames,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    Write-M365Log -Message "Importing $($ConfigNames.Count) Intune configs..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    $functionMap = @{
        'ComplianceSettings'     = 'Set-M365IntuneComplianceSettings'
        'CompliancePolicy'       = 'New-M365IntuneCompliancePolicy'
        'EnrollmentRestriction'  = 'Set-M365IntuneEnrollmentRestriction'
        'AppProtection'          = 'New-M365IntuneAppProtection'
    }

    foreach ($configName in $ConfigNames) {
        Write-M365Log -Message "Processing: $configName" -Level Info

        try {
            $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
            $configPath = Join-Path $moduleRoot "configs/Intune/$configName.json"
            $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters

            $category = $config.metadata.category
            $targetFunction = $functionMap[$category]

            if (-not $targetFunction) {
                Write-M365Log -Message "No handler for category '$category'" -Level Warning
                $results.Add([PSCustomObject]@{ ConfigName = $configName; Action = 'Skipped'; Changed = $false })
                continue
            }

            $result = & $targetFunction -ConfigName $configName -Parameters $Parameters
            if ($result) {
                if ($result -is [array]) { foreach ($r in $result) { $results.Add($r) } }
                else { $results.Add($result) }
            }
        }
        catch {
            Write-M365Log -Message "Failed: $configName - $_" -Level Error
            $results.Add([PSCustomObject]@{ ConfigName = $configName; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
        }
    }

    $applied = ($results | Where-Object Action -in 'Updated', 'Created').Count
    Write-M365Log -Message "Intune import: $applied applied, $(($results | Where-Object Action -eq 'Failed').Count) failed" -Level Info
    return $results
}
