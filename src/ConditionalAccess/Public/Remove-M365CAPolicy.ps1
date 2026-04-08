function Remove-M365CAPolicy {
    <#
    .SYNOPSIS
        Removes a Conditional Access policy from the tenant.
    .DESCRIPTION
        Deletes a CA policy by ID or display name. Always requires confirmation.
    .PARAMETER PolicyId
        The ID of the policy to remove.
    .PARAMETER DisplayName
        The display name of the policy to remove.
    .EXAMPLE
        Remove-M365CAPolicy -DisplayName 'CA001 - Block Legacy Authentication'
    .EXAMPLE
        Remove-M365CAPolicy -PolicyId '...' -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [string]$PolicyId,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$DisplayName
    )

    Assert-M365Connection -Service Graph

    # Resolve policy
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $policy = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$DisplayName'" -ErrorAction SilentlyContinue
        if (-not $policy) {
            Write-Error "Policy '$DisplayName' not found."
            return
        }
        $PolicyId = $policy.Id
        $policyName = $DisplayName
    }
    else {
        $policy = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $PolicyId -ErrorAction Stop
        $policyName = $policy.DisplayName
    }

    if ($PSCmdlet.ShouldProcess("$policyName ($PolicyId)", "DELETE Conditional Access Policy")) {
        Write-M365Log -Message "Removing CA policy: $policyName ($PolicyId)" -Level Warning

        try {
            Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $PolicyId -ErrorAction Stop

            Write-M365Log -Message "Removed CA policy: $policyName" -Level Info

            return [PSCustomObject]@{
                PolicyName = $policyName
                PolicyId   = $PolicyId
                Action     = 'Removed'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to remove CA policy: $_" -Level Error
            throw
        }
    }
}
