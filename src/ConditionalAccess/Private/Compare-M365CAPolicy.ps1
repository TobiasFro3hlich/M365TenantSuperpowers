function Compare-M365CAPolicy {
    <#
    .SYNOPSIS
        Compares a desired CA policy config against an existing policy in the tenant.
    .DESCRIPTION
        Returns a diff object showing what would change if the policy were applied.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DesiredConfig,

        [Parameter(Mandatory)]
        [object]$CurrentPolicy
    )

    $differences = [System.Collections.Generic.List[object]]::new()

    $desired = ConvertTo-M365CAPolicyParam -Config $DesiredConfig

    # Compare key properties
    $propsToCompare = @(
        @{ Path = 'state'; Label = 'Policy State' }
        @{ Path = 'displayName'; Label = 'Display Name' }
    )

    foreach ($prop in $propsToCompare) {
        $desiredVal = $desired[$prop.Path]
        $currentVal = $CurrentPolicy.$($prop.Path)
        if ($desiredVal -and $desiredVal -ne $currentVal) {
            $differences.Add([PSCustomObject]@{
                Property     = $prop.Label
                CurrentValue = $currentVal
                DesiredValue = $desiredVal
            })
        }
    }

    # Deep compare conditions
    $conditionDiffs = Compare-NestedProperty -Desired $desired.conditions -Current $CurrentPolicy.Conditions -Prefix 'conditions'
    foreach ($diff in $conditionDiffs) { $differences.Add($diff) }

    # Deep compare grant controls
    if ($desired.grantControls -and $CurrentPolicy.GrantControls) {
        $grantDiffs = Compare-NestedProperty -Desired $desired.grantControls -Current $CurrentPolicy.GrantControls -Prefix 'grantControls'
        foreach ($diff in $grantDiffs) { $differences.Add($diff) }
    }

    # Deep compare session controls
    if ($desired.sessionControls -and $CurrentPolicy.SessionControls) {
        $sessionDiffs = Compare-NestedProperty -Desired $desired.sessionControls -Current $CurrentPolicy.SessionControls -Prefix 'sessionControls'
        foreach ($diff in $sessionDiffs) { $differences.Add($diff) }
    }

    [PSCustomObject]@{
        PolicyName     = $desired.displayName
        InDesiredState = ($differences.Count -eq 0)
        Differences    = $differences
        CurrentState   = $CurrentPolicy
        DesiredState   = $desired
    }
}

function Compare-NestedProperty {
    <#
    .SYNOPSIS
        Recursively compares two hashtable/object structures and returns differences.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        $Desired,

        [Parameter()]
        $Current,

        [Parameter()]
        [string]$Prefix = ''
    )

    $diffs = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $Desired) { return $diffs }
    if ($null -eq $Current) {
        $diffs.Add([PSCustomObject]@{
            Property     = $Prefix
            CurrentValue = $null
            DesiredValue = $Desired
        })
        return $diffs
    }

    if ($Desired -is [hashtable]) {
        foreach ($key in $Desired.Keys) {
            $path = if ($Prefix) { "$Prefix.$key" } else { $key }
            $currentVal = if ($Current -is [hashtable]) { $Current[$key] } else { $Current.$key }
            $subDiffs = Compare-NestedProperty -Desired $Desired[$key] -Current $currentVal -Prefix $path
            foreach ($d in $subDiffs) { $diffs.Add($d) }
        }
    }
    elseif ($Desired -is [array]) {
        $desiredSorted = ($Desired | Sort-Object) -join ','
        $currentArray = if ($Current -is [array]) { $Current } else { @($Current) }
        $currentSorted = ($currentArray | Sort-Object) -join ','
        if ($desiredSorted -ne $currentSorted) {
            $diffs.Add([PSCustomObject]@{
                Property     = $Prefix
                CurrentValue = $currentSorted
                DesiredValue = $desiredSorted
            })
        }
    }
    else {
        if ("$Desired" -ne "$Current") {
            $diffs.Add([PSCustomObject]@{
                Property     = $Prefix
                CurrentValue = $Current
                DesiredValue = $Desired
            })
        }
    }

    return $diffs
}
