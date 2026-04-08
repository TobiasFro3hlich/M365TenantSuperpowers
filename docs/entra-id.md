# Entra ID Module

Manages Entra ID (formerly Azure AD) tenant-level identity and access settings. Covers authorization policies, authentication methods, password protection, cross-tenant access, named locations, group governance, and device registration.

## Functions

### Set-M365EntraAuthorizationPolicy

Configures the tenant-wide authorization policy — the most fundamental identity settings.

```powershell
Set-M365EntraAuthorizationPolicy -ConfigName 'ENTRA-AuthorizationPolicy'
```

**What it controls:**

| Setting | Default Config Value | Impact |
|---------|---------------------|--------|
| Users can register apps | `false` | Prevents uncontrolled app registrations |
| Users can create security groups | `true` | Allows self-service group creation |
| Users can create tenants | `false` | Blocks shadow tenant creation |
| Block MSOL PowerShell | `true` | Blocks deprecated MSOnline module |
| Guest invite restrictions | `adminsAndGuestInviters` | Only admins can invite guests |
| SSPR enabled | `true` | Users can reset their own passwords |
| Guest user role | Restricted Guest | Limits what guests can see in the directory |

---

### Set-M365EntraAuthMethodPolicy

Configures which authentication methods are available to users.

```powershell
Set-M365EntraAuthMethodPolicy -ConfigName 'ENTRA-AuthMethodPolicy'
```

**Default config enables:**
- Microsoft Authenticator with number matching and location display
- FIDO2 security keys with self-service registration
- Temporary Access Pass (one-time, 60 min, for onboarding)
- Email OTP (for external/B2B users)

**Default config disables:**
- SMS authentication (weak, SIM-swap vulnerable)
- Voice call authentication (weak)

**Also configures:**
- Registration enforcement campaign (nudges users to register Authenticator)
- Report suspicious activity (users can report fraudulent MFA prompts)

---

### Set-M365EntraSecurityDefaults

Enables or disables Entra ID Security Defaults.

```powershell
# Disable (required when using Conditional Access policies)
Set-M365EntraSecurityDefaults -ConfigName 'ENTRA-SecurityDefaults'

# Quick toggle
Set-M365EntraSecurityDefaults -Enabled $false
```

**Important:** Security Defaults and Conditional Access policies are mutually exclusive. When deploying CA policies, Security Defaults must be disabled. The `ENTRA-SecurityDefaults` config sets `isEnabled: false` for this reason.

---

### Set-M365EntraNamedLocations

Creates or updates named locations used by Conditional Access policies.

```powershell
Set-M365EntraNamedLocations -ConfigName 'ENTRA-NamedLocations'
```

**Default config creates:**
- **Allowed Countries - DACH** — Country-based location for Germany, Austria, Switzerland
- **Corporate Office IPs** — IP-based trusted location (placeholder CIDR, customize per customer)

**Idempotent:** Matches by `displayName` — existing locations are updated, new ones are created.

Named locations are referenced by CA policies (e.g., CA006-BlockCountries uses `AllTrusted` which includes IP locations marked as trusted).

---

### Set-M365EntraAdminConsent

Configures the admin consent request workflow.

```powershell
Set-M365EntraAdminConsent -ConfigName 'ENTRA-AdminConsent'
```

When enabled, users who encounter an app requiring permissions they cannot consent to will see a "Request approval" option instead of being blocked. This prevents shadow IT by providing a governed path to app access.

**Default config:** Enabled, with reviewer notifications and 30-day request expiration.

---

### Set-M365EntraCrossTenantDefault

Configures default cross-tenant access settings for B2B collaboration.

```powershell
Set-M365EntraCrossTenantDefault -ConfigName 'ENTRA-CrossTenantDefault'
```

**Default config:**

| Setting | Value | Reason |
|---------|-------|--------|
| Trust MFA from external tenants | `true` | Avoids double MFA prompts for guests |
| Trust compliant devices | `false` | Cannot verify external device compliance |
| Trust hybrid joined devices | `false` | Cannot verify external domain join |
| B2B Collaboration inbound | Allowed (all users, all apps) | Standard B2B guest access |
| B2B Collaboration outbound | Allowed | Users can be guests in other tenants |
| B2B Direct Connect inbound | Blocked | More restrictive, enable per-partner |
| B2B Direct Connect outbound | Blocked | More restrictive, enable per-partner |

Per-partner overrides can be configured separately with `Set-M365EntraCrossTenantPartner` (future).

---

### Set-M365EntraPasswordProtection

Configures custom banned password lists and smart lockout.

```powershell
Set-M365EntraPasswordProtection -ConfigName 'ENTRA-PasswordProtection'
```

**Default config:**
- Custom banned password list enabled with common weak passwords
- On-premises enforcement mode: Enforce (not Audit)
- Smart lockout threshold: 10 failed attempts
- Smart lockout duration: 60 seconds

**Customize per customer:** Add company-specific terms (company name, product names, city) to the banned list via the `customBannedWords` parameter or by editing the JSON config.

---

### Set-M365EntraGroupSettings

Configures tenant-wide M365 group settings.

```powershell
Set-M365EntraGroupSettings -ConfigName 'ENTRA-GroupSettings'
```

**Default config:**
- Group creation restricted (only members of a specified group can create M365 groups)
- Guest access to groups allowed
- Guests cannot be group owners
- Sensitivity labels for groups enabled
- Usage guidelines URL configurable per customer

---

### Set-M365EntraGroupLifecycle

Configures M365 group expiration policy.

```powershell
Set-M365EntraGroupLifecycle -ConfigName 'ENTRA-GroupLifecycle'
```

**Default config:** All M365 groups expire after 365 days. Owners receive renewal notifications. Prevents orphaned, unused groups from accumulating.

---

### Set-M365EntraDeviceRegistration

Configures the device registration policy.

```powershell
Set-M365EntraDeviceRegistration -ConfigName 'ENTRA-DeviceRegistration'
```

**Default config:**
- MFA required for device join
- Device quota: 50 per user
- Azure AD Join and Registration allowed for everyone

---

### Get-M365EntraReport

Reads current Entra ID settings and returns a structured report.

```powershell
# Full report
Get-M365EntraReport | Export-M365Report -Format HTML -Title 'Entra ID Audit'

# Specific sections
Get-M365EntraReport -Section AuthorizationPolicy, AuthMethods
```

**Available sections:** `AuthorizationPolicy`, `AuthMethods`, `SecurityDefaults`, `NamedLocations`, `CrossTenantAccess`, `GroupSettings`, `DeviceRegistration`

---

### Test-M365EntraConfig

Drift detection — compares current tenant state against a JSON config.

```powershell
Test-M365EntraConfig -ConfigName 'ENTRA-AuthorizationPolicy'
```

Returns `Compliant` or `Drift` with a list of property-level differences.

**Supported categories:** AuthorizationPolicy, SecurityDefaults, CrossTenantAccess

---

### Import-M365EntraConfigSet

Bulk-applies multiple Entra ID configs. Automatically routes each config to the correct `Set-M365Entra*` function based on its `metadata.category`.

```powershell
# Apply specific configs
Import-M365EntraConfigSet -ConfigNames 'ENTRA-AuthorizationPolicy', 'ENTRA-SecurityDefaults'

# Apply all
$all = (Get-ChildItem ./configs/EntraID/*.json).BaseName
Import-M365EntraConfigSet -ConfigNames $all
```

## Built-in Configs

| Config | Severity | Category |
|--------|----------|----------|
| ENTRA-AuthorizationPolicy | Critical | Default user permissions, guest invite restrictions |
| ENTRA-AuthMethodPolicy | Critical | Authenticator, FIDO2, TAP enabled; SMS/Voice disabled |
| ENTRA-SecurityDefaults | Critical | Disabled (replaced by CA policies) |
| ENTRA-NamedLocations | Critical | DACH countries + Corporate Office IPs |
| ENTRA-AdminConsent | Critical | Admin consent workflow enabled |
| ENTRA-CrossTenantDefault | Critical | Trust MFA, block B2B Direct Connect |
| ENTRA-PasswordProtection | Critical | Custom banned passwords, smart lockout |
| ENTRA-GroupSettings | High | Restrict group creation, enable labels |
| ENTRA-GroupLifecycle | High | 365-day group expiration |
| ENTRA-DeviceRegistration | High | MFA for device join, quota 50 |
