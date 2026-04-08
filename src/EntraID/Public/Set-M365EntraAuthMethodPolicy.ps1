function Set-M365EntraAuthMethodPolicy {
    <#
    .SYNOPSIS
        Configures authentication method policies (Authenticator, FIDO2, SMS, Email, TAP).
    .DESCRIPTION
        Sets which authentication methods are enabled for the tenant, including
        Microsoft Authenticator settings (number matching, push), FIDO2 security keys,
        SMS, Email OTP, and Temporary Access Pass.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .PARAMETER ConfigPath
        Full path to a custom JSON config.
    .PARAMETER Parameters
        Runtime parameters.
    .EXAMPLE
        Set-M365EntraAuthMethodPolicy -ConfigName 'ENTRA-AuthMethodPolicy'
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

    if ($PSCmdlet.ShouldProcess('Authentication Method Policy', 'Update auth method settings')) {
        Write-M365Log -Message "Applying authentication method policies..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # Configure each authentication method
        foreach ($method in $desired.authenticationMethodConfigurations) {
            $methodId = $method.id
            $methodState = $method.state  # 'enabled' or 'disabled'

            Write-M365Log -Message "Configuring auth method: $methodId (state: $methodState)" -Level Info

            try {
                $body = @{
                    '@odata.type' = $method.'@odata.type'
                    state         = $methodState
                }

                # Add method-specific settings
                switch ($methodId) {
                    'MicrosoftAuthenticator' {
                        if ($method.featureSettings) {
                            $body['featureSettings'] = $method.featureSettings
                        }
                        if ($method.isSoftwareOathEnabled) {
                            $body['isSoftwareOathEnabled'] = $method.isSoftwareOathEnabled
                        }
                    }
                    'Fido2' {
                        if ($null -ne $method.isSelfServiceRegistrationAllowed) {
                            $body['isSelfServiceRegistrationAllowed'] = $method.isSelfServiceRegistrationAllowed
                        }
                        if ($null -ne $method.isAttestationEnforced) {
                            $body['isAttestationEnforced'] = $method.isAttestationEnforced
                        }
                        if ($method.keyRestrictions) {
                            $body['keyRestrictions'] = $method.keyRestrictions
                        }
                    }
                    'TemporaryAccessPass' {
                        if ($method.defaultLifetimeInMinutes) {
                            $body['defaultLifetimeInMinutes'] = $method.defaultLifetimeInMinutes
                        }
                        if ($method.defaultLength) {
                            $body['defaultLength'] = $method.defaultLength
                        }
                        if ($null -ne $method.isUsableOnce) {
                            $body['isUsableOnce'] = $method.isUsableOnce
                        }
                        if ($method.minimumLifetimeInMinutes) {
                            $body['minimumLifetimeInMinutes'] = $method.minimumLifetimeInMinutes
                        }
                        if ($method.maximumLifetimeInMinutes) {
                            $body['maximumLifetimeInMinutes'] = $method.maximumLifetimeInMinutes
                        }
                    }
                    'Sms' {
                        # SMS only has state and includeTargets
                    }
                    'Email' {
                        if ($null -ne $method.allowExternalIdToUseEmailOtp) {
                            $body['allowExternalIdToUseEmailOtp'] = $method.allowExternalIdToUseEmailOtp
                        }
                    }
                }

                # Include targets if specified
                if ($method.includeTargets) {
                    $body['includeTargets'] = $method.includeTargets
                }
                if ($method.excludeTargets) {
                    $body['excludeTargets'] = $method.excludeTargets
                }

                Invoke-M365EntraGraphRequest -Method PATCH `
                    -Uri "https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/$methodId" `
                    -Body $body `
                    -Description "Update $methodId auth method"

                $results.Add([PSCustomObject]@{
                    Method  = $methodId
                    State   = $methodState
                    Action  = 'Updated'
                    Changed = $true
                })

                Write-M365Log -Message "Auth method '$methodId' configured successfully." -Level Info
            }
            catch {
                Write-M365Log -Message "Failed to configure auth method '$methodId': $_" -Level Error
                $results.Add([PSCustomObject]@{
                    Method  = $methodId
                    State   = $methodState
                    Action  = 'Failed'
                    Changed = $false
                    Error   = $_.ToString()
                })
            }
        }

        # Update top-level policy settings if specified
        if ($desired.registrationEnforcement -or $desired.reportSuspiciousActivitySettings) {
            $topBody = @{}
            if ($desired.registrationEnforcement) {
                $topBody['registrationEnforcement'] = $desired.registrationEnforcement
            }
            if ($desired.reportSuspiciousActivitySettings) {
                $topBody['reportSuspiciousActivitySettings'] = $desired.reportSuspiciousActivitySettings
            }

            try {
                Invoke-M365EntraGraphRequest -Method PATCH `
                    -Uri 'https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy' `
                    -Body $topBody `
                    -Description 'Update auth methods policy top-level settings'

                Write-M365Log -Message "Top-level auth method policy settings updated." -Level Info
            }
            catch {
                Write-M365Log -Message "Failed to update top-level auth method settings: $_" -Level Error
            }
        }

        return $results
    }
}
