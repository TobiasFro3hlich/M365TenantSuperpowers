function Set-M365AlertPolicy {
    <#
    .SYNOPSIS
        Enables and configures required alert policies.
    .DESCRIPTION
        Ensures baseline alert policies are enabled per CISA SCuBA MS.DEFENDER.5.1v1.
        Covers suspicious email patterns, connector activity, forwarding, and
        potentially malicious URL clicks.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Security/.
    .EXAMPLE
        Set-M365AlertPolicy -ConfigName 'SEC-AlertPolicies'
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

    Assert-M365Connection -Service ExchangeOnline

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/Security/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Alert Policies', 'Enable and configure alert policies')) {
        Write-M365Log -Message "Configuring alert policies..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        foreach ($alert in $desired.alerts) {
            $alertName = $alert.name
            try {
                $existing = Get-ProtectionAlert -Identity $alertName -ErrorAction SilentlyContinue

                if ($existing) {
                    $params = @{}
                    if ($null -ne $alert.isEnabled) { $params['IsEnabled'] = $alert.isEnabled }
                    if ($alert.notifyUser) { $params['NotifyUser'] = $alert.notifyUser }
                    if ($null -ne $alert.severity) { $params['Severity'] = $alert.severity }

                    if ($params.Count -gt 0) {
                        Set-ProtectionAlert -Identity $alertName @params -ErrorAction Stop
                    }

                    $results.Add([PSCustomObject]@{
                        Component = 'Alert Policy'
                        Name      = $alertName
                        Enabled   = $alert.isEnabled
                        Action    = 'Updated'
                        Changed   = $true
                    })
                    Write-M365Log -Message "Alert '$alertName' configured (Enabled: $($alert.isEnabled))." -Level Info
                }
                else {
                    Write-M365Log -Message "Alert '$alertName' not found (built-in alert may have different name)." -Level Warning
                    $results.Add([PSCustomObject]@{
                        Component = 'Alert Policy'
                        Name      = $alertName
                        Action    = 'NotFound'
                        Changed   = $false
                    })
                }
            }
            catch {
                Write-M365Log -Message "Failed to configure alert '$alertName': $_" -Level Error
                $results.Add([PSCustomObject]@{ Component = 'Alert Policy'; Name = $alertName; Action = 'Failed'; Changed = $false })
            }
        }

        return $results
    }
}
