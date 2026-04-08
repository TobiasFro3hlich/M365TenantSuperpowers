function Import-M365SPOConfigSet {
    <#
    .SYNOPSIS
        Applies a set of SharePoint Online configurations.
    .PARAMETER ConfigNames
        Array of config names (without .json) to apply.
    .EXAMPLE
        Import-M365SPOConfigSet -ConfigNames 'SPO-TenantSettings', 'SPO-SharingSettings', 'SPO-AccessControl'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ConfigNames,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service SharePoint

    Write-M365Log -Message "Importing $($ConfigNames.Count) SPO configs..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    $functionMap = @{
        'TenantSettings' = 'Set-M365SPOTenantSettings'
        'Sharing'        = 'Set-M365SPOSharing'
        'AccessControl'  = 'Set-M365SPOAccessControl'
    }

    foreach ($configName in $ConfigNames) {
        Write-M365Log -Message "Processing: $configName" -Level Info

        try {
            $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
            $configPath = Join-Path $moduleRoot "configs/SharePoint/$configName.json"
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
    Write-M365Log -Message "SPO import: $applied applied, $(($results | Where-Object Action -eq 'Failed').Count) failed" -Level Info
    return $results
}
