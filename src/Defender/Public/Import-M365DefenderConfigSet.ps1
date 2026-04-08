function Import-M365DefenderConfigSet {
    <#
    .SYNOPSIS
        Applies a set of Defender for Office 365 configurations.
    .PARAMETER ConfigNames
        Array of config names (without .json) to apply.
    .PARAMETER Parameters
        Shared runtime parameters.
    .EXAMPLE
        Import-M365DefenderConfigSet -ConfigNames 'DEF-AtpGlobal', 'DEF-SafeLinks', 'DEF-SafeAttachments'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ConfigNames,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service ExchangeOnline

    Write-M365Log -Message "Importing $($ConfigNames.Count) Defender configs..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    $functionMap = @{
        'AntiPhish'       = 'Set-M365DefenderAntiPhish'
        'AntiSpam'        = 'Set-M365DefenderAntiSpam'
        'AntiMalware'     = 'Set-M365DefenderAntiMalware'
        'SafeLinks'       = 'Set-M365DefenderSafeLinks'
        'SafeAttachments' = 'Set-M365DefenderSafeAttachments'
        'AtpGlobal'       = 'Set-M365DefenderGlobal'
    }

    foreach ($configName in $ConfigNames) {
        Write-M365Log -Message "Processing: $configName" -Level Info

        try {
            $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
            $configPath = Join-Path $moduleRoot "configs/Defender/$configName.json"
            $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters

            $category = $config.metadata.category
            $targetFunction = $functionMap[$category]

            if (-not $targetFunction) {
                Write-M365Log -Message "No handler for category '$category' in config '$configName'" -Level Warning
                $results.Add([PSCustomObject]@{
                    ConfigName = $configName
                    Action     = 'Skipped'
                    Changed    = $false
                })
                continue
            }

            $result = & $targetFunction -ConfigName $configName -Parameters $Parameters
            if ($result) {
                if ($result -is [array]) {
                    foreach ($r in $result) { $results.Add($r) }
                } else {
                    $results.Add($result)
                }
            }
        }
        catch {
            Write-M365Log -Message "Failed to process '$configName': $_" -Level Error
            $results.Add([PSCustomObject]@{
                ConfigName = $configName
                Action     = 'Failed'
                Changed    = $false
                Error      = $_.ToString()
            })
        }
    }

    $applied = ($results | Where-Object Action -in 'Updated', 'Created').Count
    $failed  = ($results | Where-Object Action -eq 'Failed').Count
    Write-M365Log -Message "Defender import complete: $applied applied, $failed failed" -Level Info

    return $results
}
