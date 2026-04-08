function Set-M365EntraGroupLifecycle {
    <#
    .SYNOPSIS
        Configures the M365 group expiration/lifecycle policy.
    .DESCRIPTION
        Sets the expiration lifetime for M365 groups, which groups it applies to,
        and notification settings for group owners.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraGroupLifecycle -ConfigName 'ENTRA-GroupLifecycle'
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
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Group Lifecycle Policy', 'Update group expiration settings')) {
        Write-M365Log -Message "Applying group lifecycle policy..." -Level Info

        try {
            # Check for existing lifecycle policy
            $existing = Invoke-M365EntraGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/v1.0/groupLifecyclePolicies' `
                -Description 'Get group lifecycle policies'

            $body = @{
                groupLifetimeInDays               = $desired.groupLifetimeInDays
                managedGroupTypes                  = $desired.managedGroupTypes
                alternateNotificationEmails        = $desired.alternateNotificationEmails
            }

            if ($existing.value -and $existing.value.Count -gt 0) {
                $policyId = $existing.value[0].id
                Invoke-M365EntraGraphRequest -Method PATCH `
                    -Uri "https://graph.microsoft.com/v1.0/groupLifecyclePolicies/$policyId" `
                    -Body $body `
                    -Description 'Update group lifecycle policy'

                Write-M365Log -Message "Group lifecycle policy updated (lifetime: $($desired.groupLifetimeInDays) days)." -Level Info
                $action = 'Updated'
            }
            else {
                Invoke-M365EntraGraphRequest -Method POST `
                    -Uri 'https://graph.microsoft.com/v1.0/groupLifecyclePolicies' `
                    -Body $body `
                    -Description 'Create group lifecycle policy'

                Write-M365Log -Message "Group lifecycle policy created (lifetime: $($desired.groupLifetimeInDays) days)." -Level Info
                $action = 'Created'
            }

            return [PSCustomObject]@{
                ConfigName          = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting             = 'Group Lifecycle Policy'
                GroupLifetimeInDays = $desired.groupLifetimeInDays
                ManagedGroupTypes   = $desired.managedGroupTypes
                Action              = $action
                Changed             = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update group lifecycle policy: $_" -Level Error
            throw
        }
    }
}
