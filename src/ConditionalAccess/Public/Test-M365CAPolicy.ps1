function Test-M365CAPolicy {
    <#
    .SYNOPSIS
        Tests whether a CA policy in the tenant matches the desired config.
    .DESCRIPTION
        Compares the current state of a CA policy against a JSON config definition.
        Returns a diff report without making any changes (drift detection).
    .PARAMETER PolicyName
        Config name to test against. The policy is matched by displayName.
    .PARAMETER Parameters
        Runtime parameters for config resolution.
    .EXAMPLE
        Test-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth'
    .EXAMPLE
        Test-M365CAPolicy -PolicyName 'CA002-RequireMFAAdmins' -Parameters @{ excludeBreakGlassGroup = '...' }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PolicyName,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    # Load desired config
    $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
    $configPath = Join-Path $moduleRoot "configs/ConditionalAccess/$PolicyName.json"
    $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters

    $desiredDisplayName = $config.policy.displayName

    # Find existing policy
    $existing = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$desiredDisplayName'" -ErrorAction SilentlyContinue

    if (-not $existing) {
        return [PSCustomObject]@{
            PolicyName     = $desiredDisplayName
            ConfigName     = $PolicyName
            InDesiredState = $false
            Status         = 'Missing'
            Differences    = @([PSCustomObject]@{
                Property     = 'Existence'
                CurrentValue = 'Not found'
                DesiredValue = 'Should exist'
            })
        }
    }

    # Compare
    $comparison = Compare-M365CAPolicy -DesiredConfig $config -CurrentPolicy $existing

    $comparison | Add-Member -NotePropertyName 'ConfigName' -NotePropertyValue $PolicyName
    $comparison | Add-Member -NotePropertyName 'Status' -NotePropertyValue $(
        if ($comparison.InDesiredState) { 'Compliant' } else { 'Drift' }
    )

    return $comparison
}
