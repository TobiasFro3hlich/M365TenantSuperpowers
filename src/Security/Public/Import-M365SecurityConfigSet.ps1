function Import-M365SecurityConfigSet {
    <#
    .SYNOPSIS
        Applies a set of security/compliance configurations.
    .PARAMETER ConfigNames
        Array of config names (without .json) to apply.
    .EXAMPLE
        Import-M365SecurityConfigSet -ConfigNames 'SEC-DLP-PII', 'SEC-SensitivityLabels', 'SEC-AuditRetention'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ConfigNames,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service ExchangeOnline

    Write-M365Log -Message "Importing $($ConfigNames.Count) Security configs..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    $functionMap = @{
        'DLP'              = 'New-M365DLPPolicy'
        'SensitivityLabels' = 'New-M365SensitivityLabel'
        'LabelPolicy'      = 'Set-M365LabelPolicy'
        'Retention'        = 'New-M365RetentionPolicy'
        'AuditRetention'   = 'Set-M365AuditRetention'
        'AlertPolicies'    = 'Set-M365AlertPolicy'
    }

    foreach ($configName in $ConfigNames) {
        Write-M365Log -Message "Processing: $configName" -Level Info

        try {
            $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
            $configPath = Join-Path $moduleRoot "configs/Security/$configName.json"
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

    $applied = ($results | Where-Object Action -in 'Updated', 'Created', 'Enabled').Count
    Write-M365Log -Message "Security import: $applied applied, $(($results | Where-Object Action -eq 'Failed').Count) failed" -Level Info
    return $results
}
