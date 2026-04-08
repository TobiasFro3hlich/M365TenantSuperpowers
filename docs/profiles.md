# Profiles

Profiles are pre-built bundles that combine multiple configuration steps into a single deployment. Instead of applying policies one by one, you can deploy a complete baseline with a single command.

## Available Profiles

### SMB-Standard (v4.0)

Complete security baseline for small and medium businesses. 13 steps covering all 7 service areas.

**Requires:** Graph + ExchangeOnline + SharePoint + Teams connection

| Step | Module | What it deploys |
|------|--------|----------------|
| 1 | Entra ID | Disable Security Defaults, harden authorization policy |
| 2 | Entra ID | Auth methods (Authenticator, FIDO2), password protection |
| 3 | Entra ID | Admin consent workflow, named locations (DACH) |
| 4 | Conditional Access | CA001 Block Legacy Auth, CA002 MFA Admins, CA003 MFA All |
| 5 | Conditional Access | CA004 Block High Risk, CA007 MFA Guests, CA009 Session Timeout |
| 6 | Defender | ATP Global, Safe Links, Safe Attachments |
| 7 | Defender | Anti-Phishing, Anti-Spam, Anti-Malware |
| 8 | Exchange | Org Config (audit on), DKIM, external sender tag |
| 9 | Exchange | Block auto-forwarding, transport rules ([EXTERNAL] prefix) |
| 10 | SharePoint | Disable legacy auth, restrict sharing to existing guests, browser idle signout |
| 11 | Teams | Meeting policy (lobby for guests), messaging policy, block consumer federation |
| 12 | Teams | Guest access config, block third-party cloud storage (DropBox, Google Drive) |
| 13 | Entra ID | Group creation restrictions, 365-day group expiration |

**Required parameters:**
- `excludeBreakGlassGroup` — Object ID of the break-glass/emergency access group

```powershell
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services Graph, ExchangeOnline, SharePoint, Teams `
    -SharePointAdminUrl 'https://contoso-admin.sharepoint.com'
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = '00000000-0000-0000-0000-000000000000'
}
```

### Enterprise-Hardened (v4.0)

Maximum security baseline for enterprise environments. 15 steps — full coverage across all 7 service areas with strict controls.

**Requires:** Graph + ExchangeOnline + SharePoint + Teams connection

| Step | Module | What it deploys |
|------|--------|----------------|
| 1-3 | Entra ID | Same as SMB + cross-tenant access restrictions + device registration (MFA for join) |
| 4 | Conditional Access | CA001-CA004 (all core identity protection) |
| 5 | Conditional Access | CA005 Compliant Device, CA006 Block Countries |
| 6 | Conditional Access | CA007 MFA Guests, CA008 App Protection, CA009 Session |
| 7-8 | Defender | Full threat protection stack (same as SMB) |
| 9 | Exchange | Org Config, DKIM, external tag |
| 10 | Exchange | **Full lockdown:** block forwarding, transport rules, OWA, mobile, sharing |
| 11 | SharePoint | Legacy auth off, restricted sharing, browser idle signout |
| 12 | Teams | Meeting, messaging, calling policies |
| 13 | Teams | App permissions, federation (block consumer), guest config |
| 14 | Teams | Channels policy (block external shared channels), block third-party storage |
| 15 | Entra ID | Group governance with strict controls |

**Additional over SMB:**
- Cross-tenant access restrictions (B2B Direct Connect blocked)
- MFA required for device join, device quota set
- Device compliance required via CA005
- Geo-blocking via CA006
- App protection on mobile via CA008
- OWA: LinkedIn/Facebook/external storage disabled
- Mobile: PIN, encryption, device wipe
- Calendar sharing: Free/Busy only
- Teams calling policy configured
- Teams app permission policy (custom apps blocked)
- Teams external shared channels blocked

```powershell
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services Graph, ExchangeOnline, SharePoint, Teams `
    -SharePointAdminUrl 'https://contoso-admin.sharepoint.com'
Invoke-M365Profile -Name 'Enterprise-Hardened' -Parameters @{
    excludeBreakGlassGroup = '00000000-0000-0000-0000-000000000000'
}
```

## Using Profiles

### Preview Before Applying

Always preview what a profile will do before applying it:

```powershell
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = '...'
} -WhatIf
```

Output:
```
[WhatIf] Would execute: Step 1: Deploy core identity protection policies [Import-M365CAPolicySet]
         Configs: CA001-BlockLegacyAuth, CA002-RequireMFAAdmins, CA003-RequireMFAAllUsers
[WhatIf] Would execute: Step 2: Deploy risk-based sign-in protection [Import-M365CAPolicySet]
         Configs: CA004-BlockHighRiskSignIns
...
```

### Cherry-Pick Steps

Apply only specific steps from a profile using `-StepOrder`:

```powershell
# Only steps 1 and 3
Invoke-M365Profile -Name 'SMB-Standard' -StepOrder 1, 3 -Parameters @{
    excludeBreakGlassGroup = '...'
}
```

### Apply Full Profile

```powershell
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = '...'
}
```

## Creating Custom Profiles

Profiles are JSON files in the `profiles/` directory. Create your own by following this structure:

```json
{
    "metadata": {
        "name": "My-Custom-Profile",
        "description": "Custom baseline for my organization",
        "version": "1.0.0",
        "author": "Your Name"
    },
    "requiredServices": ["Graph"],
    "requiredParameters": {
        "excludeBreakGlassGroup": {
            "description": "Object ID of the break-glass group",
            "required": true,
            "example": "00000000-0000-0000-0000-000000000000"
        }
    },
    "steps": [
        {
            "order": 1,
            "module": "ConditionalAccess",
            "action": "Import-M365CAPolicySet",
            "configs": [
                "CA001-BlockLegacyAuth",
                "CA003-RequireMFAAllUsers"
            ],
            "description": "Deploy minimal MFA baseline"
        }
    ]
}
```

### Profile Fields

| Field | Required | Description |
|-------|----------|-------------|
| `metadata.name` | Yes | Profile name (used with `-Name` parameter) |
| `metadata.description` | Yes | Human-readable description |
| `metadata.version` | Yes | Semantic version (X.Y.Z) |
| `requiredServices` | Yes | Which M365 services must be connected |
| `requiredParameters` | No | Parameters that must be provided at runtime |
| `steps` | Yes | Ordered list of configuration steps |
| `steps[].order` | Yes | Execution order (integer, must be unique) |
| `steps[].module` | Yes | Which sub-module this step belongs to |
| `steps[].action` | Yes | Function name to execute |
| `steps[].configs` | No | Config names to pass to the action |
| `steps[].description` | Yes | What this step does |

Save your profile as `profiles/My-Custom-Profile.json` and it is immediately available:

```powershell
Invoke-M365Profile -Name 'My-Custom-Profile' -Parameters @{ ... }
```
