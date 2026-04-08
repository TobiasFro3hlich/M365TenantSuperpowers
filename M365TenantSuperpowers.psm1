# M365TenantSuperpowers Root Module
# Connection state shared across all sub-modules
$script:M365Connection = @{
    TenantId          = $null
    ConnectedServices = [System.Collections.Generic.List[string]]::new()
    GraphContext      = $null
    Timestamp         = $null
}

# Module root path for config resolution
$script:ModuleRoot = $PSScriptRoot

function Invoke-M365Profile {
    <#
    .SYNOPSIS
        Applies a named configuration profile to the connected M365 tenant.
    .DESCRIPTION
        Reads a profile JSON file and executes each step in order, applying the
        referenced configurations. Supports -WhatIf for preview and -StepOrder
        for cherry-picking specific steps.
    .PARAMETER Name
        Name of the profile (without .json extension). Must exist in the profiles/ folder.
    .PARAMETER Parameters
        Hashtable of runtime parameters (e.g., break-glass group ID, tenant domain).
    .PARAMETER StepOrder
        Array of step order numbers to execute. If omitted, all steps are executed.
    .EXAMPLE
        Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{ excludeBreakGlassGroup = '...' }
    .EXAMPLE
        Invoke-M365Profile -Name 'SMB-Standard' -StepOrder 1,3 -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [hashtable]$Parameters = @{},

        [Parameter()]
        [int[]]$StepOrder
    )

    $profilePath = Join-Path $script:ModuleRoot "profiles/$Name.json"
    if (-not (Test-Path $profilePath)) {
        Write-Error "Profile '$Name' not found at: $profilePath"
        return
    }

    $profile = Get-Content $profilePath -Raw | ConvertFrom-Json

    Write-M365Log -Message "Loading profile: $($profile.metadata.name) v$($profile.metadata.version)" -Level Info
    Write-M365Log -Message "Description: $($profile.metadata.description)" -Level Info

    # Filter steps if StepOrder specified
    $steps = $profile.steps
    if ($StepOrder) {
        $steps = $steps | Where-Object { $_.order -in $StepOrder }
        if (-not $steps) {
            Write-Error "No steps found matching order: $($StepOrder -join ', ')"
            return
        }
    }

    # Validate required services
    $requiredServices = $profile.requiredServices
    foreach ($service in $requiredServices) {
        if ($service -notin $script:M365Connection.ConnectedServices) {
            Write-Error "Profile requires service '$service' but it is not connected. Run Connect-M365Tenant first."
            return
        }
    }

    # Execute steps in order
    $sortedSteps = $steps | Sort-Object -Property order
    foreach ($step in $sortedSteps) {
        $stepDesc = "Step $($step.order): $($step.description) [$($step.action)]"

        if ($PSCmdlet.ShouldProcess($stepDesc, "Execute profile step")) {
            Write-M365Log -Message "Executing $stepDesc" -Level Info

            try {
                $actionCmd = Get-Command $step.action -ErrorAction Stop

                # Build parameters for the action
                $actionParams = @{}

                # Map configs based on the action
                switch -Wildcard ($step.action) {
                    'Import-M365CAPolicySet' {
                        $actionParams['PolicyNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365EntraConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365DefenderConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365EXOConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365SPOConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365TeamsConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365SecurityConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365IntuneConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Import-M365PowerBIConfigSet' {
                        $actionParams['ConfigNames'] = $step.configs
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Set-M365EXO*' {
                        $actionParams['ConfigName'] = $step.configs[0]
                        $actionParams['Parameters'] = $Parameters
                    }
                    'Set-M365Entra*' {
                        $actionParams['ConfigName'] = $step.configs[0]
                        $actionParams['Parameters'] = $Parameters
                    }
                    default {
                        if ($step.configs) {
                            $actionParams['ConfigName'] = $step.configs[0]
                        }
                        if ($Parameters.Count -gt 0) {
                            $actionParams['Parameters'] = $Parameters
                        }
                    }
                }

                & $actionCmd @actionParams
                Write-M365Log -Message "Completed: $stepDesc" -Level Info
            }
            catch {
                Write-M365Log -Message "Failed: $stepDesc - $_" -Level Error
                Write-Error "Step $($step.order) failed: $_"
            }
        }
        else {
            Write-Host "[WhatIf] Would execute: $stepDesc" -ForegroundColor Cyan
            if ($step.configs) {
                Write-Host "         Configs: $($step.configs -join ', ')" -ForegroundColor DarkCyan
            }
        }
    }

    Write-M365Log -Message "Profile '$Name' execution completed." -Level Info
}

Export-ModuleMember -Function 'Invoke-M365Profile'
