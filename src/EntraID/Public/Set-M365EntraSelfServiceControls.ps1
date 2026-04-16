function Set-M365EntraSelfServiceControls {
    <#
    .SYNOPSIS
        Configures self-service trials, purchases, and app store access controls.
    .DESCRIPTION
        Controls three separate mechanisms:
        1. Entra ID: AllowedToSignUpEmailBasedSubscriptions (ad-hoc/viral sign-ups)
        2. M365 Admin: Office Store access + user-initiated trials (Graph beta API)
        3. MSCommerce: Per-product self-service purchase/trial (requires MSCommerce module)

        Required by CIS 1.3.4 "Ensure 'User owned apps and services' is restricted".
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraSelfServiceControls -ConfigName 'ENTRA-SelfServiceControls'
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

    if ($PSCmdlet.ShouldProcess('Self-Service Controls', 'Update trial, purchase, and app store settings')) {
        Write-M365Log -Message "Applying self-service controls..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        # 1. Entra ID Authorization Policy — ad-hoc subscriptions
        if ($null -ne $desired.allowedToSignUpEmailBasedSubscriptions) {
            try {
                Invoke-M365EntraGraphRequest -Method PATCH `
                    -Uri 'https://graph.microsoft.com/v1.0/policies/authorizationPolicy' `
                    -Body @{ allowedToSignUpEmailBasedSubscriptions = $desired.allowedToSignUpEmailBasedSubscriptions } `
                    -Description 'Set AllowedToSignUpEmailBasedSubscriptions'

                $results.Add([PSCustomObject]@{
                    Setting = 'Ad-hoc Email Subscriptions'
                    Value   = $desired.allowedToSignUpEmailBasedSubscriptions
                    Action  = 'Updated'
                    Changed = $true
                })
                Write-M365Log -Message "Ad-hoc subscriptions set to: $($desired.allowedToSignUpEmailBasedSubscriptions)" -Level Info
            }
            catch {
                Write-M365Log -Message "Failed to set ad-hoc subscriptions: $_" -Level Error
                $results.Add([PSCustomObject]@{ Setting = 'Ad-hoc Email Subscriptions'; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
            }
        }

        # 2. M365 Admin — Office Store + User Trials (beta API)
        if ($null -ne $desired.isOfficeStoreEnabled -or $null -ne $desired.isAppAndServicesTrialEnabled) {
            try {
                $body = @{}
                if ($null -ne $desired.isOfficeStoreEnabled) {
                    $body['isOfficeStoreEnabled'] = $desired.isOfficeStoreEnabled
                }
                if ($null -ne $desired.isAppAndServicesTrialEnabled) {
                    $body['isAppAndServicesTrialEnabled'] = $desired.isAppAndServicesTrialEnabled
                }

                Invoke-M365EntraGraphRequest -Method PATCH `
                    -Uri 'https://graph.microsoft.com/beta/admin/appsAndServices' `
                    -Body $body `
                    -Description 'Set Apps and Services settings'

                $results.Add([PSCustomObject]@{
                    Setting = 'Office Store Access'
                    Value   = $desired.isOfficeStoreEnabled
                    Action  = 'Updated'
                    Changed = $true
                })
                $results.Add([PSCustomObject]@{
                    Setting = 'User-Initiated Trials'
                    Value   = $desired.isAppAndServicesTrialEnabled
                    Action  = 'Updated'
                    Changed = $true
                })
                Write-M365Log -Message "Office Store: $($desired.isOfficeStoreEnabled), Trials: $($desired.isAppAndServicesTrialEnabled)" -Level Info
            }
            catch {
                Write-M365Log -Message "Failed to set apps and services: $_" -Level Error
                $results.Add([PSCustomObject]@{ Setting = 'Office Store / Trials'; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
            }
        }

        # 3. MSCommerce — Per-product self-service purchase
        if ($desired.disableSelfServicePurchaseForAllProducts) {
            try {
                # Check if MSCommerce module is available
                $msCommerceAvailable = Get-Module -ListAvailable -Name MSCommerce

                if ($msCommerceAvailable) {
                    Import-Module MSCommerce -ErrorAction Stop
                    Connect-MSCommerce -ErrorAction Stop

                    $products = Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase -ErrorAction Stop

                    $disabled = 0
                    foreach ($product in $products) {
                        if ($product.PolicyValue -eq 'Enabled') {
                            try {
                                Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase `
                                    -ProductId $product.ProductId -Enabled $false -ErrorAction Stop
                                $disabled++
                                Write-M365Log -Message "Disabled self-service purchase for: $($product.ProductName)" -Level Info
                            }
                            catch {
                                Write-M365Log -Message "Failed to disable for $($product.ProductName): $_" -Level Warning
                            }
                        }
                    }

                    $results.Add([PSCustomObject]@{
                        Setting = 'Self-Service Purchase (all products)'
                        Value   = "Disabled for $disabled products"
                        Action  = 'Updated'
                        Changed = ($disabled -gt 0)
                    })
                    Write-M365Log -Message "Self-service purchase disabled for $disabled of $($products.Count) products." -Level Info
                }
                else {
                    Write-M365Log -Message "MSCommerce module not installed. Install with: Install-Module -Name MSCommerce" -Level Warning
                    $results.Add([PSCustomObject]@{
                        Setting = 'Self-Service Purchase'
                        Value   = 'MSCommerce module not installed'
                        Action  = 'Skipped'
                        Changed = $false
                        Note    = 'Install-Module -Name MSCommerce, then re-run'
                    })
                }
            }
            catch {
                Write-M365Log -Message "MSCommerce self-service purchase control failed: $_" -Level Error
                $results.Add([PSCustomObject]@{ Setting = 'Self-Service Purchase'; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
            }
        }

        return $results
    }
}
