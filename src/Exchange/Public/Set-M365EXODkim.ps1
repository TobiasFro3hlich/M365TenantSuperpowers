function Set-M365EXODkim {
    <#
    .SYNOPSIS
        Enables DKIM signing for all accepted domains.
    .DESCRIPTION
        Iterates through accepted domains and enables DKIM signing configuration.
        DKIM is critical for email authentication and deliverability.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXODkim -ConfigName 'EXO-Dkim'
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
        $ConfigPath = Join-Path $moduleRoot "configs/Exchange/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters

    if ($PSCmdlet.ShouldProcess('DKIM Signing', 'Enable DKIM for all domains')) {
        Write-M365Log -Message "Enabling DKIM signing for domains..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()
        $domains = Get-AcceptedDomain -ErrorAction Stop

        foreach ($domain in $domains) {
            try {
                $dkimConfig = Get-DkimSigningConfig -Identity $domain.DomainName -ErrorAction SilentlyContinue

                if ($dkimConfig -and $dkimConfig.Enabled) {
                    $results.Add([PSCustomObject]@{
                        Domain  = $domain.DomainName
                        Action  = 'AlreadyEnabled'
                        Changed = $false
                    })
                    Write-M365Log -Message "DKIM already enabled for: $($domain.DomainName)" -Level Info
                }
                elseif ($dkimConfig) {
                    Set-DkimSigningConfig -Identity $domain.DomainName -Enabled $true -ErrorAction Stop
                    $results.Add([PSCustomObject]@{
                        Domain  = $domain.DomainName
                        Action  = 'Enabled'
                        Changed = $true
                    })
                    Write-M365Log -Message "DKIM enabled for: $($domain.DomainName)" -Level Info
                }
                else {
                    New-DkimSigningConfig -DomainName $domain.DomainName -Enabled $true -ErrorAction Stop
                    $results.Add([PSCustomObject]@{
                        Domain  = $domain.DomainName
                        Action  = 'Created'
                        Changed = $true
                    })
                    Write-M365Log -Message "DKIM config created and enabled for: $($domain.DomainName)" -Level Info
                }
            }
            catch {
                Write-M365Log -Message "Failed to configure DKIM for $($domain.DomainName): $_" -Level Warning
                $results.Add([PSCustomObject]@{
                    Domain  = $domain.DomainName
                    Action  = 'Failed'
                    Changed = $false
                    Error   = $_.ToString()
                })
            }
        }

        $enabled = ($results | Where-Object Action -in 'Enabled', 'Created').Count
        Write-M365Log -Message "DKIM: $enabled domains enabled, $($results.Count) total" -Level Info

        return $results
    }
}
