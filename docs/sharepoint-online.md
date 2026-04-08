# SharePoint Online Module

Manages SharePoint Online tenant-level settings. Covers tenant configuration, external sharing, access control, and browser idle signout.

**Requires:** SharePoint connection (`Connect-M365Tenant -Services SharePoint -SharePointAdminUrl 'https://contoso-admin.sharepoint.com'`)

## Functions

### Set-M365SPOTenantSettings

Configures core SharePoint tenant settings.

```powershell
Set-M365SPOTenantSettings -ConfigName 'SPO-TenantSettings'
```

**Default config:**
- Legacy auth protocols: **Disabled**
- Notifications: Enabled
- AIP (Azure Information Protection) integration: Enabled
- Custom app authentication: Disabled
- Comments on site pages: Enabled

---

### Set-M365SPOSharing

Configures the external sharing settings. **This is the single most impactful security decision for SharePoint.**

```powershell
Set-M365SPOSharing -ConfigName 'SPO-SharingSettings'
```

**Sharing capability levels:**

| Level | Description |
|-------|-------------|
| `Disabled` | No external sharing at all |
| `ExistingExternalUserSharingOnly` | **(Default config)** Only guests already in the directory |
| `ExternalUserSharingOnly` | New and existing guests (requires sign-in) |
| `ExternalUserAndGuestSharing` | Anyone links allowed (most permissive) |

**Default config highlights:**

| Setting | Value | Why |
|---------|-------|-----|
| Sharing capability | `ExistingExternalUserSharingOnly` | Only pre-approved guests |
| Default link type | `Internal` | People picker defaults to internal |
| Default link permission | `View` | Read-only by default |
| Require account match | `true` | Guest must use the invited email |
| Prevent resharing | `true` | Guests cannot share further |
| Anonymous link expiry | 30 days | Auto-expire any anonymous links |
| Guest expiry | 30 days | External user access expires |
| Notify on reshare | `true` | Owner notified when content reshared |

---

### Set-M365SPOAccessControl

Configures access control, conditional access enforcement, and browser idle signout.

```powershell
Set-M365SPOAccessControl -ConfigName 'SPO-AccessControl'
```

**Default config:**

| Setting | Value | Impact |
|---------|-------|--------|
| Conditional Access | `AllowLimitedAccess` | Unmanaged devices get web-only access |
| Block infected downloads | `true` | Prevents downloading malware-flagged files |
| Browser idle signout | Enabled, warn 5min, signout 60min | Auto-logs out idle browser sessions |

---

### Get-M365SPOReport

Generates a report of current SharePoint Online settings.

```powershell
Get-M365SPOReport | Export-M365Report -Format HTML -Title 'SPO Config Audit'
```

Reports on: Sharing capability, link defaults, account match, resharing, anonymous link expiry, legacy auth, conditional access, browser idle signout.

---

### Import-M365SPOConfigSet

Bulk-applies SharePoint configs.

```powershell
Import-M365SPOConfigSet -ConfigNames 'SPO-TenantSettings', 'SPO-SharingSettings', 'SPO-AccessControl'
```

## Built-in Configs

| Config | Severity | What it configures |
|--------|----------|--------------------|
| SPO-TenantSettings | Critical | Legacy auth off, AIP integration, notifications |
| SPO-SharingSettings | Critical | Restricted to existing guests, secure link defaults |
| SPO-AccessControl | Critical | Limited access for unmanaged devices, idle signout |
