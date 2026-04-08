function New-M365CAPolicy {
    <#
    .SYNOPSIS
        Creates a new Conditional Access policy from a JSON config file.
    .DESCRIPTION
        Reads a CA policy definition from the configs/ConditionalAccess folder,
        resolves runtime parameters, and creates the policy in the tenant.
        Policies default to report-only mode for safety.
    .PARAMETER PolicyName
        Name of the policy config (without .json). Must exist in configs/ConditionalAccess/.
    .PARAMETER ConfigPath
        Full path to a custom JSON config file. Overrides PolicyName.
    .PARAMETER Parameters
        Runtime parameters (e.g., break-glass group ID).
    .PARAMETER State
        Override the policy state. Default: uses state from config (usually report-only).
    .EXAMPLE
        New-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -Parameters @{ excludeBreakGlassGroup = '...' }
    .EXAMPLE
        New-M365CAPolicy -ConfigPath './custom/MyPolicy.json'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$PolicyName,

        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [string]$ConfigPath,

        [Parameter()]
        [hashtable]$Parameters = @{},

        [Parameter()]
        [ValidateSet('enabled', 'disabled', 'enabledForReportingButNotEnforced')]
        [string]$State
    )

    Assert-M365Connection -Service Graph

    # Resolve config path
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/ConditionalAccess/$PolicyName.json"
    }

    # Load and resolve config
    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters

    # Override state if specified
    if ($State) {
        $config.policy.state = $State
    }

    # Convert to Graph API parameters
    $bodyParam = ConvertTo-M365CAPolicyParam -Config $config

    # Check if policy already exists
    $existing = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$($bodyParam.displayName)'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-M365Log -Message "Policy '$($bodyParam.displayName)' already exists (ID: $($existing.Id)). Use Set-M365CAPolicy to update." -Level Warning
        return [PSCustomObject]@{
            PolicyName = $bodyParam.displayName
            Action     = 'Skipped'
            Reason     = 'Already exists'
            PolicyId   = $existing.Id
            Changed    = $false
        }
    }

    if ($PSCmdlet.ShouldProcess($bodyParam.displayName, "Create Conditional Access Policy")) {
        Write-M365Log -Message "Creating CA policy: $($bodyParam.displayName) (State: $($bodyParam.state))" -Level Info

        try {
            $newPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $bodyParam -ErrorAction Stop

            Write-M365Log -Message "Created CA policy: $($newPolicy.DisplayName) (ID: $($newPolicy.Id))" -Level Info

            return [PSCustomObject]@{
                PolicyName = $newPolicy.DisplayName
                Action     = 'Created'
                PolicyId   = $newPolicy.Id
                State      = $newPolicy.State
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to create CA policy '$($bodyParam.displayName)': $_" -Level Error
            throw
        }
    }
}
