function Set-M365EntraAdminConsent {
    <#
    .SYNOPSIS
        Configures the admin consent request policy.
    .DESCRIPTION
        Controls whether users can request admin consent for apps they cannot
        consent to themselves, who reviews those requests, and notification settings.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraAdminConsent -ConfigName 'ENTRA-AdminConsent'
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

    if ($PSCmdlet.ShouldProcess('Admin Consent Request Policy', 'Update admin consent settings')) {
        Write-M365Log -Message "Applying admin consent request policy..." -Level Info

        $body = @{
            isEnabled          = $desired.isEnabled
            notifyReviewers    = $desired.notifyReviewers
            remindersEnabled   = $desired.remindersEnabled
            requestDurationInDays = $desired.requestDurationInDays
        }

        if ($desired.reviewers) {
            $body['reviewers'] = $desired.reviewers
        }

        try {
            Invoke-M365EntraGraphRequest -Method PUT `
                -Uri 'https://graph.microsoft.com/v1.0/policies/adminConsentRequestPolicy' `
                -Body $body `
                -Description 'Update admin consent request policy'

            Write-M365Log -Message "Admin consent request policy updated." -Level Info

            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'Admin Consent Request Policy'
                Enabled    = $desired.isEnabled
                Action     = 'Updated'
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update admin consent policy: $_" -Level Error
            throw
        }
    }
}
