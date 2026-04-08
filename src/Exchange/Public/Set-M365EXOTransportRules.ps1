function Set-M365EXOTransportRules {
    <#
    .SYNOPSIS
        Applies transport (mail flow) rules from a JSON config.
    .DESCRIPTION
        Creates or updates transport rules for common scenarios like external
        email disclaimers, auto-forwarding blocks, and encryption triggers.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXOTransportRules -ConfigName 'EXO-TransportRules'
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
    $rules = $config.settings.rules

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($rule in $rules) {
        $ruleName = $rule.Name

        if ($PSCmdlet.ShouldProcess($ruleName, "Create/Update transport rule")) {
            try {
                $existing = Get-TransportRule -Identity $ruleName -ErrorAction SilentlyContinue
                $ruleParams = @{}

                foreach ($key in $rule.Keys) {
                    if ($key -ne 'Name') {
                        $ruleParams[$key] = $rule[$key]
                    }
                }

                if ($existing) {
                    Set-TransportRule -Identity $ruleName @ruleParams -ErrorAction Stop
                    $results.Add([PSCustomObject]@{
                        RuleName = $ruleName
                        Action   = 'Updated'
                        Changed  = $true
                    })
                    Write-M365Log -Message "Updated transport rule: $ruleName" -Level Info
                }
                else {
                    New-TransportRule -Name $ruleName @ruleParams -ErrorAction Stop
                    $results.Add([PSCustomObject]@{
                        RuleName = $ruleName
                        Action   = 'Created'
                        Changed  = $true
                    })
                    Write-M365Log -Message "Created transport rule: $ruleName" -Level Info
                }
            }
            catch {
                Write-M365Log -Message "Failed to apply transport rule '$ruleName': $_" -Level Error
                $results.Add([PSCustomObject]@{
                    RuleName = $ruleName
                    Action   = 'Failed'
                    Changed  = $false
                    Error    = $_.ToString()
                })
            }
        }
    }

    return $results
}
