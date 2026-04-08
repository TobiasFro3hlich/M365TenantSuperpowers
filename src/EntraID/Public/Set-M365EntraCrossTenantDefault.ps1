function Set-M365EntraCrossTenantDefault {
    <#
    .SYNOPSIS
        Configures default cross-tenant access policy settings.
    .DESCRIPTION
        Sets the default inbound and outbound trust settings for B2B collaboration
        and B2B direct connect with external organizations. Controls whether to
        trust MFA, compliant devices, and hybrid joined devices from external tenants.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraCrossTenantDefault -ConfigName 'ENTRA-CrossTenantDefault'
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

    if ($PSCmdlet.ShouldProcess('Cross-Tenant Access Policy Default', 'Update default cross-tenant settings')) {
        Write-M365Log -Message "Applying cross-tenant access default policy..." -Level Info

        $body = @{}

        # Inbound trust settings
        if ($desired.inboundTrust) {
            $body['inboundTrust'] = $desired.inboundTrust
        }

        # B2B Collaboration inbound
        if ($desired.b2bCollaborationInbound) {
            $body['b2bCollaborationInbound'] = $desired.b2bCollaborationInbound
        }

        # B2B Collaboration outbound
        if ($desired.b2bCollaborationOutbound) {
            $body['b2bCollaborationOutbound'] = $desired.b2bCollaborationOutbound
        }

        # B2B Direct Connect inbound
        if ($desired.b2bDirectConnectInbound) {
            $body['b2bDirectConnectInbound'] = $desired.b2bDirectConnectInbound
        }

        # B2B Direct Connect outbound
        if ($desired.b2bDirectConnectOutbound) {
            $body['b2bDirectConnectOutbound'] = $desired.b2bDirectConnectOutbound
        }

        # Automatic user consent
        if ($desired.automaticUserConsentSettings) {
            $body['automaticUserConsentSettings'] = $desired.automaticUserConsentSettings
        }

        try {
            Invoke-M365EntraGraphRequest -Method PATCH `
                -Uri 'https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/default' `
                -Body $body `
                -Description 'Update default cross-tenant access policy'

            Write-M365Log -Message "Cross-tenant access default policy updated." -Level Info

            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'Cross-Tenant Access Default'
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update cross-tenant access policy: $_" -Level Error
            throw
        }
    }
}
