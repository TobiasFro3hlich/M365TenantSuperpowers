function Set-M365LabelPolicy {
    <#
    .SYNOPSIS
        Creates or updates a sensitivity label publishing policy.
    .DESCRIPTION
        Publishes sensitivity labels to users/groups so they can apply them to
        documents and emails. Required by CIS 3.3.1.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Security/.
    .EXAMPLE
        Set-M365LabelPolicy -ConfigName 'SEC-LabelPolicy'
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

    $policyName = $desired.policyName

    if ($PSCmdlet.ShouldProcess($policyName, "Create/Update label publishing policy")) {
        Write-M365Log -Message "Applying label policy: $policyName" -Level Info

        $existing = Get-LabelPolicy -Identity $policyName -ErrorAction SilentlyContinue

        $policyParams = @{}
        if ($desired.labels) { $policyParams['Labels'] = $desired.labels }
        if ($desired.exchangeLocation) { $policyParams['ExchangeLocation'] = $desired.exchangeLocation }
        if ($null -ne $desired.advancedSettings) { $policyParams['AdvancedSettings'] = $desired.advancedSettings }

        try {
            if ($existing) {
                Set-LabelPolicy -Identity $policyName @policyParams -ErrorAction Stop
                Write-M365Log -Message "Label policy '$policyName' updated." -Level Info
                return [PSCustomObject]@{ Component = 'Label Policy'; Name = $policyName; Action = 'Updated'; Changed = $true }
            }
            else {
                New-LabelPolicy -Name $policyName @policyParams -ErrorAction Stop
                Write-M365Log -Message "Label policy '$policyName' created." -Level Info
                return [PSCustomObject]@{ Component = 'Label Policy'; Name = $policyName; Action = 'Created'; Changed = $true }
            }
        }
        catch {
            Write-M365Log -Message "Failed to apply label policy: $_" -Level Error
            throw
        }
    }
}
