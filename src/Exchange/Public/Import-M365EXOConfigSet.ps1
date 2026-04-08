function Import-M365EXOConfigSet {
    <#
    .SYNOPSIS
        Applies a set of Exchange Online configurations.
    .PARAMETER ConfigNames
        Array of config names (without .json) to apply.
    .EXAMPLE
        Import-M365EXOConfigSet -ConfigNames 'EXO-OrganizationConfig', 'EXO-Dkim', 'EXO-ExternalTag'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ConfigNames,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service ExchangeOnline

    Write-M365Log -Message "Importing $($ConfigNames.Count) EXO configs..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    $functionMap = @{
        'OrganizationConfig' = 'Set-M365EXOOrganizationConfig'
        'Dkim'               = 'Set-M365EXODkim'
        'TransportRules'     = 'Set-M365EXOTransportRules'
        'ExternalTag'        = 'Set-M365EXOExternalTag'
        'OwaPolicy'          = 'Set-M365EXOOwaPolicy'
        'MobilePolicy'       = 'Set-M365EXOMobilePolicy'
        'SharingPolicy'      = 'Set-M365EXOSharingPolicy'
        'RemoteDomain'       = 'Set-M365EXORemoteDomain'
    }

    foreach ($configName in $ConfigNames) {
        Write-M365Log -Message "Processing: $configName" -Level Info

        try {
            $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
            $configPath = Join-Path $moduleRoot "configs/Exchange/$configName.json"
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
    $failed  = ($results | Where-Object Action -eq 'Failed').Count
    Write-M365Log -Message "EXO import: $applied applied, $failed failed" -Level Info

    return $results
}
