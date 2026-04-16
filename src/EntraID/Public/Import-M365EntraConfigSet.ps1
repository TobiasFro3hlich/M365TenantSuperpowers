function Import-M365EntraConfigSet {
    <#
    .SYNOPSIS
        Applies a set of Entra ID configurations from config files.
    .DESCRIPTION
        Takes a list of config names and applies them to the tenant.
        Each config is routed to the appropriate Set-M365Entra* function
        based on its metadata category.
    .PARAMETER ConfigNames
        Array of config names (without .json) to apply.
    .PARAMETER Parameters
        Shared runtime parameters.
    .EXAMPLE
        Import-M365EntraConfigSet -ConfigNames 'ENTRA-AuthorizationPolicy', 'ENTRA-SecurityDefaults'
    .EXAMPLE
        Import-M365EntraConfigSet -ConfigNames (Get-ChildItem configs/EntraID/*.json -Exclude '_schema.json').BaseName
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$ConfigNames,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    Write-M365Log -Message "Importing $($ConfigNames.Count) Entra ID configs..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    # Config category to function mapping
    $functionMap = @{
        'AuthorizationPolicy' = 'Set-M365EntraAuthorizationPolicy'
        'AuthMethods'         = 'Set-M365EntraAuthMethodPolicy'
        'SecurityDefaults'    = 'Set-M365EntraSecurityDefaults'
        'NamedLocations'      = 'Set-M365EntraNamedLocations'
        'AdminConsent'        = 'Set-M365EntraAdminConsent'
        'CrossTenantAccess'   = 'Set-M365EntraCrossTenantDefault'
        'PasswordProtection'  = 'Set-M365EntraPasswordProtection'
        'GroupSettings'       = 'Set-M365EntraGroupSettings'
        'GroupLifecycle'       = 'Set-M365EntraGroupLifecycle'
        'DeviceRegistration'  = 'Set-M365EntraDeviceRegistration'
        'PIM'                 = 'Set-M365EntraPIMRoleSettings'
        'SelfServiceControls' = 'Set-M365EntraSelfServiceControls'
        'AccessReviews'       = 'New-M365EntraAccessReview'
    }

    foreach ($configName in $ConfigNames) {
        Write-M365Log -Message "Processing: $configName" -Level Info

        try {
            $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
            $configPath = Join-Path $moduleRoot "configs/EntraID/$configName.json"
            $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters

            $category = $config.metadata.category
            $targetFunction = $functionMap[$category]

            if (-not $targetFunction) {
                Write-M365Log -Message "No handler for category '$category' in config '$configName'" -Level Warning
                $results.Add([PSCustomObject]@{
                    ConfigName = $configName
                    Category   = $category
                    Action     = 'Skipped'
                    Reason     = "No handler for category '$category'"
                    Changed    = $false
                })
                continue
            }

            $result = & $targetFunction -ConfigName $configName -Parameters $Parameters
            if ($result) {
                if ($result -is [array]) {
                    foreach ($r in $result) { $results.Add($r) }
                }
                else {
                    $results.Add($result)
                }
            }
        }
        catch {
            Write-M365Log -Message "Failed to process '$configName': $_" -Level Error
            $results.Add([PSCustomObject]@{
                ConfigName = $configName
                Action     = 'Failed'
                Error      = $_.ToString()
                Changed    = $false
            })
        }
    }

    # Summary
    $updated = ($results | Where-Object Action -in 'Updated', 'Created').Count
    $failed  = ($results | Where-Object Action -eq 'Failed').Count
    $skipped = ($results | Where-Object Action -in 'Skipped', 'NoChange').Count

    Write-M365Log -Message "Import complete: $updated applied, $skipped unchanged, $failed failed" -Level Info

    return $results
}
