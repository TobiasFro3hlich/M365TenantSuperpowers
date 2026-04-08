function New-M365SensitivityLabel {
    <#
    .SYNOPSIS
        Creates sensitivity labels from a JSON config.
    .DESCRIPTION
        Deploys sensitivity labels for information protection. Labels can apply
        encryption, content marking (headers/footers/watermarks), and access restrictions.
        Required by CIS 3.3.1.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Security/.
    .EXAMPLE
        New-M365SensitivityLabel -ConfigName 'SEC-SensitivityLabels'
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
    $labels = $config.settings.labels

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($label in $labels) {
        $labelName = $label.displayName

        if ($PSCmdlet.ShouldProcess($labelName, "Create/Update sensitivity label")) {
            $existing = Get-Label -Identity $labelName -ErrorAction SilentlyContinue

            $labelParams = @{}
            if ($label.tooltip) { $labelParams['Tooltip'] = $label.tooltip }
            if ($label.comment) { $labelParams['Comment'] = $label.comment }
            if ($null -ne $label.priority) { $labelParams['Priority'] = $label.priority }
            if ($label.contentType) { $labelParams['ContentType'] = $label.contentType }

            # Encryption settings
            if ($label.encryptionEnabled) {
                $labelParams['EncryptionEnabled'] = $true
                if ($label.encryptionProtectionType) { $labelParams['EncryptionProtectionType'] = $label.encryptionProtectionType }
                if ($null -ne $label.encryptionDoNotForward) { $labelParams['EncryptionDoNotForward'] = $label.encryptionDoNotForward }
            }

            # Content marking
            if ($null -ne $label.headerEnabled) { $labelParams['HeaderEnabled'] = $label.headerEnabled }
            if ($label.headerText) { $labelParams['HeaderText'] = $label.headerText }
            if ($null -ne $label.footerEnabled) { $labelParams['FooterEnabled'] = $label.footerEnabled }
            if ($label.footerText) { $labelParams['FooterText'] = $label.footerText }
            if ($null -ne $label.watermarkEnabled) { $labelParams['WatermarkEnabled'] = $label.watermarkEnabled }
            if ($label.watermarkText) { $labelParams['WatermarkText'] = $label.watermarkText }

            try {
                if ($existing) {
                    Set-Label -Identity $labelName @labelParams -ErrorAction Stop
                    $results.Add([PSCustomObject]@{ Component = 'Sensitivity Label'; Name = $labelName; Action = 'Updated'; Changed = $true })
                }
                else {
                    New-Label -DisplayName $labelName -Name ($labelName -replace '\s', '') @labelParams -ErrorAction Stop
                    $results.Add([PSCustomObject]@{ Component = 'Sensitivity Label'; Name = $labelName; Action = 'Created'; Changed = $true })
                }
                Write-M365Log -Message "Sensitivity label '$labelName' applied." -Level Info
            }
            catch {
                Write-M365Log -Message "Failed to apply label '$labelName': $_" -Level Error
                $results.Add([PSCustomObject]@{ Component = 'Sensitivity Label'; Name = $labelName; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
            }
        }
    }

    return $results
}
