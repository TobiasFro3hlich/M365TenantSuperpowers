function Set-M365DefenderGlobal {
    <#
    .SYNOPSIS
        Configures global ATP/Defender for Office 365 settings.
    .DESCRIPTION
        Sets tenant-wide Defender settings including Safe Attachments for
        SharePoint/OneDrive/Teams, Safe Documents, and Teams protection.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Defender/.
    .EXAMPLE
        Set-M365DefenderGlobal -ConfigName 'DEF-AtpGlobal'
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
        $ConfigPath = Join-Path $moduleRoot "configs/Defender/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('ATP Global Policy', 'Update global Defender settings')) {
        Write-M365Log -Message "Applying global Defender for Office 365 settings..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # ATP Policy for O365 (Safe Attachments for SPO/ODB/Teams, Safe Documents)
        if ($desired.atpPolicy) {
            try {
                $atpParams = @{}
                $atpProps = @(
                    'EnableATPForSPOTeamsODB', 'EnableSafeDocs',
                    'AllowSafeDocsOpen', 'EnableSafeLinksForO365Clients'
                )
                foreach ($prop in $atpProps) {
                    if ($null -ne $desired.atpPolicy.$prop) {
                        $atpParams[$prop] = $desired.atpPolicy.$prop
                    }
                }

                Set-AtpPolicyForO365 @atpParams -ErrorAction Stop

                Write-M365Log -Message "ATP global policy updated." -Level Info
                $results.Add([PSCustomObject]@{
                    Component = 'ATP Global Policy'
                    Action    = 'Updated'
                    Changed   = $true
                })
            }
            catch {
                Write-M365Log -Message "Failed to update ATP global policy: $_" -Level Error
                $results.Add([PSCustomObject]@{
                    Component = 'ATP Global Policy'
                    Action    = 'Failed'
                    Changed   = $false
                    Error     = $_.ToString()
                })
            }
        }

        return $results
    }
}
