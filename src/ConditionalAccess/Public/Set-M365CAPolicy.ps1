function Set-M365CAPolicy {
    <#
    .SYNOPSIS
        Updates an existing Conditional Access policy.
    .DESCRIPTION
        Updates a CA policy by applying changes from a config file or by changing
        specific properties like the policy state. Uses check-before-apply pattern.
    .PARAMETER PolicyId
        The ID of the policy to update.
    .PARAMETER PolicyName
        Config name to use as the desired state. Looks up existing policy by displayName.
    .PARAMETER State
        Set the policy state (e.g., promote from report-only to enabled).
    .PARAMETER Parameters
        Runtime parameters for config resolution.
    .EXAMPLE
        Set-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -State enabled
    .EXAMPLE
        Set-M365CAPolicy -PolicyId '...' -State disabled
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [string]$PolicyId,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$PolicyName,

        [Parameter()]
        [ValidateSet('enabled', 'disabled', 'enabledForReportingButNotEnforced')]
        [string]$State,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    # Resolve the target policy
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $configPath = Join-Path $moduleRoot "configs/ConditionalAccess/$PolicyName.json"
        $config = Get-M365Config -ConfigPath $configPath -Parameters $Parameters
        $bodyParam = ConvertTo-M365CAPolicyParam -Config $config

        # Find existing policy by display name
        $existing = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$($bodyParam.displayName)'" -ErrorAction SilentlyContinue
        if (-not $existing) {
            Write-Error "Policy '$($bodyParam.displayName)' not found in tenant. Use New-M365CAPolicy to create it."
            return
        }
        $PolicyId = $existing.Id
    }
    else {
        $existing = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $PolicyId -ErrorAction Stop
    }

    # Build update body
    $updateBody = @{}

    if ($State) {
        if ($State -ne $existing.State) {
            $updateBody['state'] = $State
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByName' -and $bodyParam) {
        # Apply full config update
        if ($State) { $bodyParam.state = $State }
        $updateBody = $bodyParam
    }

    if ($updateBody.Count -eq 0) {
        Write-M365Log -Message "Policy '$($existing.DisplayName)' is already in desired state. No changes needed." -Level Info
        return [PSCustomObject]@{
            PolicyName = $existing.DisplayName
            PolicyId   = $existing.Id
            Action     = 'NoChange'
            Changed    = $false
        }
    }

    if ($PSCmdlet.ShouldProcess("$($existing.DisplayName) ($PolicyId)", "Update Conditional Access Policy")) {
        Write-M365Log -Message "Updating CA policy: $($existing.DisplayName)" -Level Info

        try {
            Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $PolicyId -BodyParameter $updateBody -ErrorAction Stop

            Write-M365Log -Message "Updated CA policy: $($existing.DisplayName)" -Level Info

            return [PSCustomObject]@{
                PolicyName = $existing.DisplayName
                PolicyId   = $PolicyId
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update CA policy: $_" -Level Error
            throw
        }
    }
}
