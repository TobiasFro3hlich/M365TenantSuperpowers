function New-M365IntuneCompliancePolicy {
    <#
    .SYNOPSIS
        Creates or updates a device compliance policy from a JSON config.
    .DESCRIPTION
        Deploys platform-specific compliance policies (Windows, iOS, Android, macOS)
        that define minimum security requirements for devices accessing corporate data.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Intune/.
    .EXAMPLE
        New-M365IntuneCompliancePolicy -ConfigName 'INTUNE-ComplianceWindows'
    .EXAMPLE
        New-M365IntuneCompliancePolicy -ConfigName 'INTUNE-ComplianceiOS'
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

    if ($PSCmdlet.ShouldProcess($policyName, "Create/Update compliance policy")) {
        Write-M365Log -Message "Applying compliance policy: $policyName ($odataType)" -Level Info

        try {
            # Check for existing policy by name
            $allPolicies = Invoke-M365IntuneGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies' `
                -Description 'Get compliance policies'

            $existing = $allPolicies.value | Where-Object { $_.displayName -eq $policyName }

            # Build body from config settings
            $body = @{ '@odata.type' = $odataType; displayName = $policyName }

            if ($desired.description) { $body['description'] = $desired.description }

            # Copy all platform-specific settings
            foreach ($key in $desired.Keys) {
                if ($key -notin @('displayName', 'description', '@odata.type', 'assignments')) {
                    $body[$key] = $desired[$key]
                }
            }

            if ($existing) {
                $policyId = $existing.id
                Invoke-M365IntuneGraphRequest -Method PATCH `
                    -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$policyId" `
                    -Body $body `
                    -Description "Update compliance policy '$policyName'"

                Write-M365Log -Message "Compliance policy '$policyName' updated (ID: $policyId)." -Level Info

                return [PSCustomObject]@{
                    ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                    PolicyName = $policyName
                    PolicyId   = $policyId
                    Platform   = $odataType
                    Action     = 'Updated'
                    Changed    = $true
                }
            }
            else {
                $response = Invoke-M365IntuneGraphRequest -Method POST `
                    -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies' `
                    -Body $body `
                    -Description "Create compliance policy '$policyName'"

                Write-M365Log -Message "Compliance policy '$policyName' created (ID: $($response.id))." -Level Info

                # Assign to all users if specified
                if ($desired.assignments) {
                    $assignBody = @{
                        assignments = $desired.assignments
                    }
                    Invoke-M365IntuneGraphRequest -Method POST `
                        -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$($response.id)/assign" `
                        -Body $assignBody `
                        -Description "Assign compliance policy"
                    Write-M365Log -Message "Compliance policy assigned." -Level Info
                }

                return [PSCustomObject]@{
                    ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                    PolicyName = $policyName
                    PolicyId   = $response.id
                    Platform   = $odataType
                    Action     = 'Created'
                    Changed    = $true
                }
            }
        }
        catch {
            Write-M365Log -Message "Failed to apply compliance policy '$policyName': $_" -Level Error
            throw
        }
    }
}
