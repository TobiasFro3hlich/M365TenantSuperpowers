function New-M365IntuneAppProtection {
    <#
    .SYNOPSIS
        Creates or updates an app protection (MAM) policy from a JSON config.
    .DESCRIPTION
        Deploys app protection policies for iOS and Android that protect corporate
        data without requiring full device enrollment (BYOD scenarios).
    .PARAMETER ConfigName
        Name of the JSON config from configs/Intune/.
    .EXAMPLE
        New-M365IntuneAppProtection -ConfigName 'INTUNE-AppProtectioniOS'
    .EXAMPLE
        New-M365IntuneAppProtection -ConfigName 'INTUNE-AppProtectionAndroid'
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
        $ConfigPath = Join-Path $moduleRoot "configs/Intune/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings
    $policyName = $desired.displayName
    $odataType = $desired.'@odata.type'

    # Determine platform endpoint
    $endpoint = switch -Wildcard ($odataType) {
        '*iosManagedAppProtection'     { 'iosManagedAppProtections' }
        '*androidManagedAppProtection' { 'androidManagedAppProtections' }
        default { throw "Unknown app protection type: $odataType" }
    }

    if ($PSCmdlet.ShouldProcess($policyName, "Create/Update app protection policy")) {
        Write-M365Log -Message "Applying app protection policy: $policyName" -Level Info

        try {
            # Check existing
            $allPolicies = Invoke-M365IntuneGraphRequest -Method GET `
                -Uri "https://graph.microsoft.com/beta/deviceAppManagement/$endpoint" `
                -Description "Get $endpoint"

            $existing = $allPolicies.value | Where-Object { $_.displayName -eq $policyName }

            # Build body
            $body = @{ '@odata.type' = $odataType; displayName = $policyName }
            foreach ($key in $desired.Keys) {
                if ($key -notin @('displayName', '@odata.type')) {
                    $body[$key] = $desired[$key]
                }
            }

            if ($existing) {
                Invoke-M365IntuneGraphRequest -Method PATCH `
                    -Uri "https://graph.microsoft.com/beta/deviceAppManagement/$endpoint/$($existing.id)" `
                    -Body $body `
                    -Description "Update app protection '$policyName'"

                Write-M365Log -Message "App protection '$policyName' updated." -Level Info
                return [PSCustomObject]@{ ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }; PolicyName = $policyName; Action = 'Updated'; Changed = $true }
            }
            else {
                $response = Invoke-M365IntuneGraphRequest -Method POST `
                    -Uri "https://graph.microsoft.com/beta/deviceAppManagement/$endpoint" `
                    -Body $body `
                    -Description "Create app protection '$policyName'"

                Write-M365Log -Message "App protection '$policyName' created (ID: $($response.id))." -Level Info
                return [PSCustomObject]@{ ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }; PolicyName = $policyName; PolicyId = $response.id; Action = 'Created'; Changed = $true }
            }
        }
        catch {
            Write-M365Log -Message "Failed to apply app protection '$policyName': $_" -Level Error
            throw
        }
    }
}
