# Conditional Access Module

Manages Conditional Access policies in Entra ID. Supports creating policies from JSON configs, auditing existing policies, drift detection, bulk import/export, and state management.

## Functions

### New-M365CAPolicy

Creates a new CA policy from a JSON config file. Policies default to **report-only mode** for safety.

```powershell
New-M365CAPolicy
    -PolicyName <string>    # Config name (without .json) from configs/ConditionalAccess/
    -ConfigPath <string>    # OR: full path to a custom JSON config
    -Parameters <hashtable> # Runtime parameters (e.g., break-glass group)
    -State <string>         # Override state: enabled, disabled, enabledForReportingButNotEnforced
    -WhatIf / -Confirm      # ShouldProcess support
```

**Idempotent:** If a policy with the same `displayName` already exists, it is skipped with a warning.

**Examples:**

```powershell
# Create from built-in config
New-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -Parameters @{
    excludeBreakGlassGroup = '00000000-0000-0000-0000-000000000000'
}

# Create from custom file
New-M365CAPolicy -ConfigPath './custom/MyPolicy.json'

# Preview without creating
New-M365CAPolicy -PolicyName 'CA002-RequireMFAAdmins' -Parameters @{
    excludeBreakGlassGroup = '...'
} -WhatIf

# Create directly in enabled state (use with caution!)
New-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -Parameters @{
    excludeBreakGlassGroup = '...'
} -State enabled
```

---

### Get-M365CAPolicy

Retrieves and displays CA policies from the tenant.

```powershell
Get-M365CAPolicy
    -PolicyId <string>      # Get specific policy by ID
    -DisplayName <string>   # Filter by name (supports wildcards)
    -State <string>         # Filter by state
```

**Output properties:** Id, DisplayName, State, IncludeUsers, IncludeRoles, IncludeApps, GrantControls, ClientAppTypes, CreatedDateTime, ModifiedDateTime.

**Examples:**

```powershell
# List all policies
Get-M365CAPolicy

# Filter by name pattern
Get-M365CAPolicy -DisplayName 'CA0*'

# Only report-only policies
Get-M365CAPolicy -State enabledForReportingButNotEnforced

# Export to HTML report
Get-M365CAPolicy | Export-M365Report -Format HTML -Title 'CA Policy Audit'

# Export to CSV
Get-M365CAPolicy -State enabled | Export-M365Report -Format CSV -Title 'Active CA Policies'
```

---

### Set-M365CAPolicy

Updates an existing CA policy. Most commonly used to promote policies from report-only to enabled.

```powershell
Set-M365CAPolicy
    -PolicyId <string>      # Update by policy ID
    -PolicyName <string>    # OR: update by config name (matches by displayName)
    -State <string>         # New state
    -Parameters <hashtable> # Runtime parameters
    -WhatIf / -Confirm
```

**Idempotent:** If the policy is already in the desired state, no changes are made.

**Examples:**

```powershell
# Promote to enabled (most common use case)
Set-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -State enabled

# Disable a policy
Set-M365CAPolicy -PolicyName 'CA003-RequireMFAAllUsers' -State disabled

# Update by ID
Set-M365CAPolicy -PolicyId '12345678-...' -State enabled

# Full config update from JSON
Set-M365CAPolicy -PolicyName 'CA002-RequireMFAAdmins' -Parameters @{
    excludeBreakGlassGroup = '...'
}
```

---

### Remove-M365CAPolicy

Deletes a CA policy. Has **High ConfirmImpact** — always prompts for confirmation unless `-Confirm:$false` is specified.

```powershell
Remove-M365CAPolicy
    -PolicyId <string>      # Remove by ID
    -DisplayName <string>   # OR: remove by display name
    -WhatIf / -Confirm
```

**Examples:**

```powershell
# Remove by name (will prompt for confirmation)
Remove-M365CAPolicy -DisplayName 'CA001 - Block Legacy Authentication'

# Remove by ID without confirmation (use with caution!)
Remove-M365CAPolicy -PolicyId '...' -Confirm:$false
```

---

### Test-M365CAPolicy

Compares a CA policy in the tenant against the desired JSON config. Returns a drift report **without making any changes**.

```powershell
Test-M365CAPolicy
    -PolicyName <string>    # Config name to test against
    -Parameters <hashtable> # Runtime parameters
```

**Output properties:**

| Property | Description |
|----------|-------------|
| PolicyName | Display name of the policy |
| ConfigName | Config file name |
| InDesiredState | `$true` if policy matches config |
| Status | `Compliant`, `Drift`, or `Missing` |
| Differences | Array of property-level diffs |

**Examples:**

```powershell
# Test a single policy
Test-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -Parameters @{
    excludeBreakGlassGroup = '...'
}

# Test all policies and report
$configs = (Get-ChildItem ./configs/ConditionalAccess/*.json -Exclude '_schema.json').BaseName
$results = $configs | ForEach-Object {
    Test-M365CAPolicy -PolicyName $_ -Parameters @{ excludeBreakGlassGroup = '...' }
}
$results | Export-M365Report -Format HTML -Title 'CA Compliance Report'

# Quick compliance check
$results | Where-Object { -not $_.InDesiredState }
```

---

### Import-M365CAPolicySet

Bulk-applies a set of CA policies. Creates new policies or updates existing ones. This is the primary function for deploying policies.

```powershell
Import-M365CAPolicySet
    -PolicyNames <string[]> # Array of config names to apply
    -Parameters <hashtable> # Shared runtime parameters
    -State <string>         # Override state for all policies
    -WhatIf / -Confirm
```

**Returns:** Array of result objects with PolicyName, Action (Created/Updated/Skipped/NoChange/Failed), PolicyId, Changed.

**Examples:**

```powershell
# Deploy specific policies
Import-M365CAPolicySet -PolicyNames 'CA001-BlockLegacyAuth', 'CA002-RequireMFAAdmins' `
    -Parameters @{ excludeBreakGlassGroup = '...' }

# Deploy all configs in the folder
$allConfigs = (Get-ChildItem ./configs/ConditionalAccess/*.json -Exclude '_schema.json').BaseName
Import-M365CAPolicySet -PolicyNames $allConfigs -Parameters @{ excludeBreakGlassGroup = '...' }

# Preview first
Import-M365CAPolicySet -PolicyNames 'CA001-BlockLegacyAuth' `
    -Parameters @{ excludeBreakGlassGroup = '...' } -WhatIf
```

---

### Export-M365CAPolicySet

Exports all CA policies from the tenant to JSON config files. Useful for backing up, migrating, or snapshotting a tenant.

```powershell
Export-M365CAPolicySet
    -OutputPath <string>    # Default: './export/ConditionalAccess'
    -Prefix <string>        # Default: 'CA-Export'. Prefix for filenames
```

**Examples:**

```powershell
# Export all policies
Export-M365CAPolicySet

# Export with custom path and prefix
Export-M365CAPolicySet -OutputPath './backup/contoso-ca' -Prefix 'PROD'

# Export and review
$exported = Export-M365CAPolicySet
$exported | Format-Table PolicyName, State, FilePath
```

The exported JSON files follow the same format as the built-in configs, so they can be used directly with `New-M365CAPolicy` or `Import-M365CAPolicySet`.

## Built-in CA Policy Configs

The module ships with 10 pre-built CA policy configurations:

| Config | Severity | Description |
|--------|----------|-------------|
| CA001-BlockLegacyAuth | Critical | Blocks IMAP, POP3, SMTP, basic ActiveSync |
| CA002-RequireMFAAdmins | Critical | MFA for 14 privileged admin roles |
| CA003-RequireMFAAllUsers | Critical | MFA for all users, all apps |
| CA004-BlockHighRiskSignIns | Critical | Blocks high-risk sign-ins (requires P2) |
| CA005-RequireCompliantDevice | High | Requires Intune-compliant device |
| CA006-BlockCountries | High | Blocks sign-ins from untrusted locations |
| CA007-RequireMFAGuestAccess | High | MFA for all guest/external users |
| CA008-AppProtectionPolicy | Medium | Requires approved app or MAM on iOS/Android |
| CA009-SessionTimeout | Medium | 24h sign-in frequency, no persistent browser |
| CA010-RequireTOS | Low | Requires Terms of Use acceptance |

All policies deploy in **report-only mode** by default. Review in the Entra admin center before promoting to enabled with `Set-M365CAPolicy -State enabled`.
