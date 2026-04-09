# Profiles

Profiles are pre-built bundles that combine multiple configuration steps into a single deployment. Instead of applying policies one by one, you can deploy a complete baseline with a single command.

## Available Profiles

### SMB-Standard (v6.0)

Complete security baseline for SMBs. 17 steps covering all 10 service areas including Intune MAM, DLP, sensitivity labels, and compliance audit.

**Requires:** Graph + ExchangeOnline + SharePoint + Teams connection

| Step | Module | What it deploys |
|------|--------|----------------|
| 1 | Entra ID | Disable Security Defaults, harden authorization policy |
| 2 | Entra ID | Auth methods (Authenticator, FIDO2), password protection |
| 3 | Entra ID | Admin consent workflow, named locations (DACH) |
| 4 | Conditional Access | CA001 Block Legacy Auth, CA002 MFA Admins, CA003 MFA All |
| 5 | Conditional Access | CA004 Block High Risk Sign-ins, CA011 Block High Risk Users |
| 6 | Conditional Access | CA007 MFA Guests, CA009 Session Timeout, CA012 Block Device Code |
| 7 | Defender | ATP Global, Safe Links, Safe Attachments |
| 8 | Defender | Anti-Phishing, Anti-Spam, Anti-Malware |
| 9 | Exchange | Org Config (audit on, SMTP AUTH off), DKIM, external tag |
| 10 | Exchange | Block auto-forwarding, transport rules ([EXTERNAL] prefix) |
| 11 | SharePoint | Disable legacy auth, restrict sharing, browser idle signout |
| 12 | Teams | Meeting (lobby, no anonymous start), messaging, block consumer federation |
| 13 | Teams | Guest config, block third-party cloud storage |
| 14 | Intune | Secure-by-default compliance, iOS + Android app protection (MAM) |
| 15 | Security | Audit retention 1yr, CISA-required alert policies |
| 16 | Security | DLP for PII, sensitivity labels (4 levels), label publishing |
| 17 | Entra ID | Group creation restrictions, 365-day group expiration |

**Required parameters:**
- `excludeBreakGlassGroup` — Object ID of the break-glass/emergency access group

```powershell
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services Graph, ExchangeOnline, SharePoint, Teams `
    -SharePointAdminUrl 'https://contoso-admin.sharepoint.com'
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = '00000000-0000-0000-0000-000000000000'
}
```

### Enterprise-Hardened (v6.1)

Maximum security baseline. 23 steps — full coverage across all 10 service areas with Intune device compliance, PIM, DLP, phishing-resistant MFA, and access reviews.

**Requires:** Graph + ExchangeOnline + SharePoint + Teams connection

| Step | Module | What it deploys |
|------|--------|----------------|
| 1-3 | Entra ID | Same as SMB + cross-tenant restrictions + device registration (MFA) |
| 4 | Entra ID | **PIM: require approval for GA, no permanent assignments, alerts** |
| 5 | Conditional Access | CA001-CA004 + CA011 Block High Risk Users |
| 6 | Conditional Access | CA005 Compliant Device, CA006 Block Countries |
| 7 | Conditional Access | CA007 MFA Guests, CA008 App Protection, CA009 Session |
| 8 | Conditional Access | **CA012 Block Device Code, CA013 Managed Device for MFA Reg** |
| 9-10 | Defender | Full threat protection stack |
| 11-12 | Exchange | Full lockdown: audit, DKIM, forwarding, OWA, mobile, sharing |
| 13 | SharePoint | Restricted sharing, browser idle signout |
| 14-16 | Teams | Full policy suite: meeting, messaging, calling, apps, federation, guest, channels |
| 17 | Intune | **Secure-by-default, block personal devices** |
| 18 | Intune | **Device compliance: Windows (BitLocker, Defender), iOS, Android** |
| 19 | Intune | **App protection (MAM) for iOS and Android** |
| 20 | Security | Audit retention 1yr, CISA alerts |
| 21 | Security | **DLP: PII + financial data protection** |
| 22 | Security | **Sensitivity labels, publishing, 1yr retention** |
| 23 | Entra ID | Group governance |

**Additional over SMB:**
- PIM with approval workflows and activation alerts
- Phishing-resistant MFA option (CA014/CA015 available)
- Device code flow blocked (CA012)
- Managed device for MFA registration (CA013)
- Cross-tenant access restrictions (B2B Direct Connect blocked)
- Full Intune: device compliance + enrollment restrictions + MAM
- DLP for financial data (IBAN, SWIFT) in addition to PII
- 1-year retention policy across all workloads
- Full EXO lockdown: OWA, mobile, sharing policies
- Full Teams lockdown: all 8 policies

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
