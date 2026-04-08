function Get-M365Config {
    <#
    .SYNOPSIS
        Loads and validates a JSON config file, resolving runtime parameters.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable

    # Resolve parameters if the config defines them
    if ($config.ContainsKey('parameters') -and $config.parameters.Count -gt 0) {
        foreach ($paramName in $config.parameters.Keys) {
            $paramDef = $config.parameters[$paramName]

            if ($Parameters.ContainsKey($paramName)) {
                # Parameter provided at runtime — inject into the policy
                $paramValue = $Parameters[$paramName]
                $config = Resolve-ConfigParameter -Config $config -ParameterName $paramName -Value $paramValue
            }
            elseif ($paramDef.required -eq $true) {
                throw "Required parameter '$paramName' not provided for config: $(Split-Path $ConfigPath -Leaf). Description: $($paramDef.description)"
            }
        }
    }

    return $config
}

function Resolve-ConfigParameter {
    <#
    .SYNOPSIS
        Injects a resolved parameter value into the config's policy section.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$ParameterName,

        [Parameter(Mandatory)]
        $Value
    )

    $paramDef = $Config.parameters[$ParameterName]

    # Apply parameter based on its type
    switch ($paramDef.type) {
        'groupObjectId' {
            # Add to user exclusions in conditions
            if ($Config.policy.conditions.users -and -not $Config.policy.conditions.users.excludeGroups) {
                $Config.policy.conditions.users.excludeGroups = @()
            }
            if ($Config.policy.conditions.users) {
                $Config.policy.conditions.users.excludeGroups += $Value
            }
        }
        'stringArray' {
            # Replace placeholder in policy with the actual values
            $Config.policy[$paramDef.targetProperty] = $Value
        }
        default {
            Write-Verbose "Parameter type '$($paramDef.type)' for '$ParameterName' — no auto-injection, available in parameters hashtable."
        }
    }

    return $Config
}
