function Import-M365CAPolicySet {
    <#
    .SYNOPSIS
        Applies a set of CA policies from config files to the tenant.
    .DESCRIPTION
        Takes a list of policy config names and creates or updates them in the tenant.
        Uses idempotent check-before-apply logic. Policies are deployed in report-only
        mode by default.
    .PARAMETER PolicyNames
        Array of policy config names (without .json) to apply.
    .PARAMETER Parameters
        Runtime parameters shared across all policies.
    .PARAMETER State
        Override the state for all policies in the set.
    .EXAMPLE
        Import-M365CAPolicySet -PolicyNames 'CA001-BlockLegacyAuth','CA002-RequireMFAAdmins'
    .EXAMPLE
        Import-M365CAPolicySet -PolicyNames (Get-ChildItem configs/ConditionalAccess/*.json | ForEach-Object BaseName)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string[]]$PolicyNames,

        [Parameter()]
        [hashtable]$Parameters = @{},

        [Parameter()]
        [ValidateSet('enabled', 'disabled', 'enabledForReportingButNotEnforced')]
        [string]$State
    )

    Assert-M365Connection -Service Graph

    Write-M365Log -Message "Importing $($PolicyNames.Count) CA policies..." -Level Info

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($policyName in $PolicyNames) {
        Write-M365Log -Message "Processing: $policyName" -Level Info

        try {
            # Load config to check display name
            $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
            $configPath = Join-Path $moduleRoot "configs/ConditionalAccess/$policyName.json"
            $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters
            $displayName = $config.policy.displayName

            # Check if policy exists
            $existing = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue

            if ($existing) {
                # Update existing
                $setParams = @{
                    PolicyName = $policyName
                    Parameters = $Parameters
                }
                if ($State) { $setParams['State'] = $State }

                $result = Set-M365CAPolicy @setParams
            }
            else {
                # Create new
                $newParams = @{
                    PolicyName = $policyName
                    Parameters = $Parameters
                }
                if ($State) { $newParams['State'] = $State }

                $result = New-M365CAPolicy @newParams
            }

            if ($result) { $results.Add($result) }
        }
        catch {
            Write-M365Log -Message "Failed to process '$policyName': $_" -Level Error
            $results.Add([PSCustomObject]@{
                PolicyName = $policyName
                Action     = 'Failed'
                Error      = $_.ToString()
                Changed    = $false
            })
        }
    }

    # Summary
    $created = ($results | Where-Object Action -eq 'Created').Count
    $updated = ($results | Where-Object Action -eq 'Updated').Count
    $skipped = ($results | Where-Object Action -in 'Skipped', 'NoChange').Count
    $failed  = ($results | Where-Object Action -eq 'Failed').Count

    Write-M365Log -Message "Import complete: $created created, $updated updated, $skipped unchanged, $failed failed" -Level Info

    return $results
}
