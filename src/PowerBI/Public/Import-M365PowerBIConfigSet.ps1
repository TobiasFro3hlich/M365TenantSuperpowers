function Import-M365PowerBIConfigSet {
    <#
    .SYNOPSIS
        Applies a set of Power BI configurations.
    .PARAMETER ConfigNames
        Array of config names (without .json) to apply.
    .EXAMPLE
        Import-M365PowerBIConfigSet -ConfigNames 'PBI-TenantSettings'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ConfigNames,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    Write-M365Log -Message "Importing $($ConfigNames.Count) Power BI configs..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($configName in $ConfigNames) {
        Write-M365Log -Message "Processing: $configName" -Level Info
        try {
            $result = Set-M365PowerBITenantSettings -ConfigName $configName -Parameters $Parameters
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

    return $results
}
