# Examples

Real-world usage scenarios and workflows for M365TenantSuperpowers.

## Scenario 1: New Customer Tenant Setup

A new SMB customer needs a secure M365 baseline deployed.

```powershell
# 1. Import and connect
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'customer.onmicrosoft.com'

# 2. Check prerequisites
Test-M365Prerequisites -Services Graph

# 3. Preview the SMB profile
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
} -WhatIf

# 4. Deploy (all policies in report-only mode)
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
}

# 5. Verify deployment
Get-M365CAPolicy -DisplayName 'CA0*' | Export-M365Report -Format Console

# 6. After review period, enable policies one by one
Set-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -State enabled
Set-M365CAPolicy -PolicyName 'CA002-RequireMFAAdmins' -State enabled
Set-M365CAPolicy -PolicyName 'CA003-RequireMFAAllUsers' -State enabled

# 7. Disconnect
Disconnect-M365Tenant
```

## Scenario 2: Audit Existing Tenant

Check an existing tenant's CA policies against best practices.

```powershell
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'existing-customer.onmicrosoft.com'

# Get full inventory
Get-M365CAPolicy | Export-M365Report -Format HTML, CSV -Title 'CA Policy Audit'

# Test compliance against each config
$breakGlass = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
$configs = (Get-ChildItem ./configs/ConditionalAccess/*.json -Exclude '_schema.json').BaseName

$complianceReport = foreach ($config in $configs) {
    Test-M365CAPolicy -PolicyName $config -Parameters @{
        excludeBreakGlassGroup = $breakGlass
    }
}

# Show non-compliant policies
$complianceReport | Where-Object { -not $_.InDesiredState } |
    Select-Object ConfigName, Status, @{N='Diffs';E={$_.Differences.Count}} |
    Export-M365Report -Format Console

# Full compliance report as HTML
$complianceReport | Select-Object ConfigName, PolicyName, Status, InDesiredState |
    Export-M365Report -Format HTML -Title 'CA Compliance Report'
```

## Scenario 3: Tenant Migration / Snapshot

Export all CA policies from a production tenant and re-import them to a staging tenant.

```powershell
# --- Source tenant ---
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'source-tenant.onmicrosoft.com'

# Export all policies
Export-M365CAPolicySet -OutputPath './migration/source-ca' -Prefix 'SOURCE'
Disconnect-M365Tenant

# --- Target tenant ---
Connect-M365Tenant -TenantId 'target-tenant.onmicrosoft.com'

# Import exported policies (they will be in report-only mode)
$exportedConfigs = (Get-ChildItem './migration/source-ca/*.json').FullName
foreach ($configPath in $exportedConfigs) {
    New-M365CAPolicy -ConfigPath $configPath -WhatIf
}

# After review, apply for real
foreach ($configPath in $exportedConfigs) {
    New-M365CAPolicy -ConfigPath $configPath
}

Disconnect-M365Tenant
```

## Scenario 4: Cherry-Pick Policies

A customer only wants MFA for admins and legacy auth blocking — nothing else.

```powershell
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'customer.onmicrosoft.com'

# Deploy only the two policies you want
Import-M365CAPolicySet -PolicyNames 'CA001-BlockLegacyAuth', 'CA002-RequireMFAAdmins' `
    -Parameters @{ excludeBreakGlassGroup = '...' }

Disconnect-M365Tenant
```

## Scenario 5: Promote Policies After Review Period

After deploying in report-only mode and reviewing the impact in Entra admin center.

```powershell
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'customer.onmicrosoft.com'

# Check current states
Get-M365CAPolicy -DisplayName 'CA0*' | Select-Object DisplayName, State |
    Export-M365Report -Format Console

# Enable specific policies
'CA001-BlockLegacyAuth', 'CA002-RequireMFAAdmins', 'CA003-RequireMFAAllUsers' | ForEach-Object {
    Set-M365CAPolicy -PolicyName $_ -State enabled
}

# Verify
Get-M365CAPolicy -State enabled | Export-M365Report -Format Console

Disconnect-M365Tenant
```

## Scenario 6: Use Cherry-Pick Steps from Profile

Deploy only the identity protection steps from the Enterprise profile, skip device compliance.

```powershell
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'customer.onmicrosoft.com'

# Preview all steps
Invoke-M365Profile -Name 'Enterprise-Hardened' -Parameters @{
    excludeBreakGlassGroup = '...'
} -WhatIf

# Only execute steps 1 and 4 (identity + external access)
Invoke-M365Profile -Name 'Enterprise-Hardened' -StepOrder 1, 4 -Parameters @{
    excludeBreakGlassGroup = '...'
}

Disconnect-M365Tenant
```

## Scenario 7: Drift Detection in Scheduled Job

Run drift detection on a schedule to catch unauthorized changes.

```powershell
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'customer.onmicrosoft.com'

$breakGlass = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
$configs = @('CA001-BlockLegacyAuth', 'CA002-RequireMFAAdmins', 'CA003-RequireMFAAllUsers')

$driftReport = foreach ($config in $configs) {
    Test-M365CAPolicy -PolicyName $config -Parameters @{
        excludeBreakGlassGroup = $breakGlass
    }
}

# Alert on drift
$drifted = $driftReport | Where-Object Status -eq 'Drift'
if ($drifted) {
    Write-M365Log -Message "DRIFT DETECTED in $($drifted.Count) policies!" -Level Warning
    $drifted | ForEach-Object {
        Write-M365Log -Message "  $($_.ConfigName): $($_.Differences.Count) differences" -Level Warning
    }
}

# Export report
$driftReport | Select-Object ConfigName, Status, InDesiredState |
    Export-M365Report -Format HTML -Title "Drift Report $(Get-Date -Format 'yyyy-MM-dd')"

Disconnect-M365Tenant
```

## Scenario 8: Generate Report for Customer Handover

Create professional HTML reports for customer documentation.

```powershell
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'customer.onmicrosoft.com'

# CA Policy inventory with full details
Get-M365CAPolicy | Export-M365Report -Format HTML, CSV `
    -Title 'Conditional Access Policies - Customer Handover' `
    -OutputPath './reports/customer'

# Prerequisites status
Test-M365Prerequisites | Export-M365Report -Format HTML `
    -Title 'Module Prerequisites Status' `
    -OutputPath './reports/customer'

Disconnect-M365Tenant
```
