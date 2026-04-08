function Set-M365EntraGroupSettings {
    <#
    .SYNOPSIS
        Configures tenant-wide group settings (guest access, self-service, usage guidelines).
    .DESCRIPTION
        Sets M365 group defaults including whether guests can access groups,
        self-service group creation controls, usage guidelines URL, and
        classification/sensitivity labels for groups.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraGroupSettings -ConfigName 'ENTRA-GroupSettings'
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

    if ($PSCmdlet.ShouldProcess('Group Settings', 'Update tenant-wide group settings')) {
        Write-M365Log -Message "Applying group settings..." -Level Info

        try {
            # Get existing group settings
            $dirSettings = Invoke-M365EntraGraphRequest -Method GET `
                -Uri 'https://graph.microsoft.com/v1.0/settings' `
                -Description 'Get directory settings'

            $groupSettings = $dirSettings.value | Where-Object { $_.displayName -eq 'Group.Unified' }

            $settingsValues = @()

            $settingsMap = @{
                'enableGroupCreation'            = 'EnableGroupCreation'
                'allowGuestsToAccessGroups'       = 'AllowGuestsToAccessGroups'
                'allowGuestsToBeGroupOwner'       = 'AllowGuestsToBeGroupOwner'
                'allowToAddGuests'                = 'AllowToAddGuests'
                'groupCreationAllowedGroupId'     = 'GroupCreationAllowedGroupId'
                'usageGuidelinesUrl'              = 'UsageGuidelinesUrl'
                'classificationList'              = 'ClassificationList'
                'classificationDescriptions'      = 'ClassificationDescriptions'
                'defaultClassification'           = 'DefaultClassification'
                'enableMIPLabels'                 = 'EnableMIPLabels'
                'customBlockedWordsList'          = 'CustomBlockedWordsList'
                'prefixSuffixNamingRequirement'   = 'PrefixSuffixNamingRequirement'
            }

            foreach ($key in $settingsMap.Keys) {
                if ($null -ne $desired[$key]) {
                    $settingsValues += @{
                        name  = $settingsMap[$key]
                        value = $desired[$key].ToString()
                    }
                }
            }

            $body = @{ values = $settingsValues }

            if ($groupSettings) {
                Invoke-M365EntraGraphRequest -Method PATCH `
                    -Uri "https://graph.microsoft.com/v1.0/settings/$($groupSettings.id)" `
                    -Body $body `
                    -Description 'Update group settings'

                Write-M365Log -Message "Group settings updated." -Level Info
            }
            else {
                # Create from template
                $templates = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri 'https://graph.microsoft.com/v1.0/directorySettingTemplates' `
                    -Description 'Get directory setting templates'

                $template = $templates.value | Where-Object { $_.displayName -eq 'Group.Unified' }

                if ($template) {
                    $createBody = @{
                        templateId = $template.id
                        values     = $settingsValues
                    }
                    Invoke-M365EntraGraphRequest -Method POST `
                        -Uri 'https://graph.microsoft.com/v1.0/settings' `
                        -Body $createBody `
                        -Description 'Create group settings'
                }

                Write-M365Log -Message "Group settings created." -Level Info
            }

            return [PSCustomObject]@{
                ConfigName = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting    = 'Group.Unified Settings'
                Action     = if ($groupSettings) { 'Updated' } else { 'Created' }
                Changed    = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to update group settings: $_" -Level Error
            throw
        }
    }
}
