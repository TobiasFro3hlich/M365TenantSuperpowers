function Set-M365EntraNamedLocations {
    <#
    .SYNOPSIS
        Creates or updates named locations for use in Conditional Access policies.
    .DESCRIPTION
        Manages IP-based and country-based named locations. Named locations are
        referenced by CA policies (e.g., CA006-BlockCountries uses trusted locations).
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .PARAMETER ConfigPath
        Full path to a custom JSON config.
    .PARAMETER Parameters
        Runtime parameters.
    .EXAMPLE
        Set-M365EntraNamedLocations -ConfigName 'ENTRA-NamedLocations'
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
        $ConfigPath = Join-Path $moduleRoot "configs/EntraID/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings.namedLocations

    # Get existing named locations
    $existing = Invoke-M365EntraGraphRequest -Method GET `
        -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' `
        -Description 'Get named locations'

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($location in $desired) {
        $displayName = $location.displayName
        $match = $existing.value | Where-Object { $_.displayName -eq $displayName }

        if ($PSCmdlet.ShouldProcess($displayName, "Create/Update named location")) {
            try {
                $body = @{
                    displayName = $displayName
                }

                if ($location.ipRanges) {
                    # IP-based named location
                    $body['@odata.type'] = '#microsoft.graph.ipNamedLocation'
                    $body['ipRanges'] = $location.ipRanges
                    $body['isTrusted'] = if ($null -ne $location.isTrusted) { $location.isTrusted } else { $false }
                }
                elseif ($location.countriesAndRegions) {
                    # Country-based named location
                    $body['@odata.type'] = '#microsoft.graph.countryNamedLocation'
                    $body['countriesAndRegions'] = $location.countriesAndRegions
                    $body['includeUnknownCountriesAndRegions'] = if ($null -ne $location.includeUnknownCountriesAndRegions) { $location.includeUnknownCountriesAndRegions } else { $false }
                }

                if ($match) {
                    # Update existing
                    Invoke-M365EntraGraphRequest -Method PATCH `
                        -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations/$($match.id)" `
                        -Body $body `
                        -Description "Update named location '$displayName'"

                    $results.Add([PSCustomObject]@{
                        LocationName = $displayName
                        LocationId   = $match.id
                        Action       = 'Updated'
                        Changed      = $true
                    })
                    Write-M365Log -Message "Updated named location: $displayName" -Level Info
                }
                else {
                    # Create new
                    $response = Invoke-M365EntraGraphRequest -Method POST `
                        -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' `
                        -Body $body `
                        -Description "Create named location '$displayName'"

                    $results.Add([PSCustomObject]@{
                        LocationName = $displayName
                        LocationId   = $response.id
                        Action       = 'Created'
                        Changed      = $true
                    })
                    Write-M365Log -Message "Created named location: $displayName (ID: $($response.id))" -Level Info
                }
            }
            catch {
                Write-M365Log -Message "Failed to set named location '$displayName': $_" -Level Error
                $results.Add([PSCustomObject]@{
                    LocationName = $displayName
                    Action       = 'Failed'
                    Changed      = $false
                    Error        = $_.ToString()
                })
            }
        }
    }

    return $results
}
