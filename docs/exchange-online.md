# Exchange Online Module

Manages Exchange Online tenant-level configuration. Covers organization settings, DKIM, transport rules, external sender tagging, OWA policies, mobile device policies, sharing policies, and remote domain settings.

**Requires:** Exchange Online connection (`Connect-M365Tenant -Services ExchangeOnline`)

## Functions

### Set-M365EXOOrganizationConfig

Configures the master organization-wide Exchange Online settings.

```powershell
Set-M365EXOOrganizationConfig -ConfigName 'EXO-OrganizationConfig'
```

**Default config — key settings:**

| Setting | Value | Why |
|---------|-------|-----|
| `AuditDisabled` | `false` | **Critical.** Ensures mailbox audit logging is active |
| `OAuth2ClientProfileEnabled` | `true` | Required for modern auth apps |
| `MailTipsAllTipsEnabled` | `true` | Shows mail tips (large audience, external, etc.) |
| `MailTipsExternalRecipientsTipsEnabled` | `true` | Warns when sending to external recipients |
| `MailTipsGroupMetricsEnabled` | `true` | Shows distribution group size tips |
| `MailTipsLargeAudienceThreshold` | `25` | Warns when sending to 25+ recipients |
| `SendFromAliasEnabled` | `true` | Users can send from proxy addresses |
| `ReadTrackingEnabled` | `false` | Disables read receipts tracking |
| `ConnectorsEnabled` | `true` | Enables M365 connectors |

---

### Set-M365EXODkim

Enables DKIM signing for all accepted domains.

```powershell
Set-M365EXODkim -ConfigName 'EXO-Dkim'
```

**What it does:** Iterates through all accepted domains in the tenant and enables DKIM signing configuration for each. DKIM is essential for:
- Email authentication (proves the email came from your domain)
- Deliverability (many receivers check DKIM)
- DMARC alignment (DKIM is one of the two mechanisms DMARC checks)

**Idempotent:** Already-enabled domains are skipped. Missing configs are created.

**Important:** After enabling DKIM, you must add the CNAME records to your DNS. The function enables the signing config in M365, but DNS changes must be done at your DNS provider.

---

### Set-M365EXOTransportRules

Creates or updates mail flow (transport) rules from a JSON config.

```powershell
Set-M365EXOTransportRules -ConfigName 'EXO-TransportRules'
```

**Default config deploys:**

| Rule | What it does |
|------|-------------|
| **M365SP - External Email Warning** | Prepends `[EXTERNAL]` to subject line and sets `X-External-Mail: true` header for all inbound external emails. Helps users identify phishing. |

**Idempotent:** Rules are matched by name. Existing rules are updated, new ones are created.

**Extend:** Add more rules to the `rules` array in the JSON config:
```json
{
    "Name": "Block Auto-Forward to External",
    "FromScope": "InOrganization",
    "SentToScope": "NotInOrganization",
    "MessageTypeMatches": "AutoForward",
    "RejectMessageReasonText": "Auto-forwarding to external recipients is not allowed.",
    "Mode": "Enforce"
}
```

---

### Set-M365EXOExternalTag

Enables the external sender identification tag in Outlook.

```powershell
Set-M365EXOExternalTag -ConfigName 'EXO-ExternalTag'
```

When enabled, emails from outside the organization display an `[External]` tag in Outlook. This helps users identify potential phishing and social engineering attempts.

**Optional:** Exclude trusted partner domains via the `AllowList` setting.

---

### Set-M365EXORemoteDomain

Configures the default remote domain settings — controls what happens when your users email external recipients.

```powershell
Set-M365EXORemoteDomain -ConfigName 'EXO-RemoteDomain'
```

**Default config — critical security setting:**

| Setting | Value | Impact |
|---------|-------|--------|
| `AutoForwardEnabled` | **`false`** | **Blocks auto-forwarding to external domains.** This is a primary data exfiltration vector. Attackers who compromise a mailbox often set up forwarding rules. |
| `AllowedOOFType` | `External` | Only sends external-formatted OOF replies |
| `AutoReplyEnabled` | `true` | Allows OOF/auto-reply |
| `TNEFEnabled` | `false` | Disables winmail.dat (compatibility) |
| `DeliveryReportEnabled` | `true` | Allows delivery status notifications |
| `NDREnabled` | `true` | Allows non-delivery reports |

---

### Set-M365EXOOwaPolicy

Configures the Outlook on the Web (OWA) mailbox policy.

```powershell
Set-M365EXOOwaPolicy -ConfigName 'EXO-OwaPolicy'
```

**Default config:**
- Disables LinkedIn and Facebook integration
- Disables external WAC services
- Disables additional storage providers (Dropbox, Google Drive, Box)
- Disables personal account calendars
- Keeps classic attachments enabled

---

### Set-M365EXOMobilePolicy

Configures mobile device mailbox policy (ActiveSync).

```powershell
Set-M365EXOMobilePolicy -ConfigName 'EXO-MobilePolicy'
```

**Default config:**

| Setting | Value |
|---------|-------|
| Password required | Yes |
| Minimum password length | 6 |
| Simple password | Not allowed |
| Max failed attempts | 10 (then wipe) |
| Device encryption | Required |
| Inactivity lock | 15 minutes |

---

### Set-M365EXOSharingPolicy

Configures the default calendar/contact sharing policy.

```powershell
Set-M365EXOSharingPolicy -ConfigName 'EXO-SharingPolicy'
```

**Default config:** Restricts external sharing to Free/Busy time only. Prevents users from sharing detailed calendar information or contacts with external parties.

---

### Get-M365EXOReport

Generates a report of current Exchange Online configuration.

```powershell
Get-M365EXOReport | Export-M365Report -Format HTML -Title 'EXO Config Audit'
```

**Reports on:** Organization config (audit, mail tips, OAuth), DKIM signing status per domain, accepted domains, external sender tag, remote domain settings (auto-forward status).

---

### Import-M365EXOConfigSet

Bulk-applies Exchange Online configs. Routes each config to the correct function.

```powershell
# Deploy full EXO baseline
Import-M365EXOConfigSet -ConfigNames @(
    'EXO-OrganizationConfig',
    'EXO-Dkim',
    'EXO-ExternalTag',
    'EXO-RemoteDomain',
    'EXO-TransportRules',
    'EXO-OwaPolicy',
    'EXO-MobilePolicy',
    'EXO-SharingPolicy'
)
```

## Built-in Configs

| Config | Severity | What it configures |
|--------|----------|--------------------|
| EXO-OrganizationConfig | Critical | Audit logging, mail tips, OAuth, send-from-alias |
| EXO-Dkim | Critical | DKIM signing for all accepted domains |
| EXO-ExternalTag | High | External sender tag in Outlook |
| EXO-RemoteDomain | High | **Block auto-forwarding**, OOF type, TNEF |
| EXO-TransportRules | Critical | `[EXTERNAL]` subject prefix, X-External-Mail header |
| EXO-OwaPolicy | High | Disable LinkedIn/Facebook, external storage providers |
| EXO-MobilePolicy | High | PIN, encryption, device wipe policy |
| EXO-SharingPolicy | High | Calendar sharing restricted to Free/Busy only |

## Security Impact Summary

The Exchange Online baseline addresses these key security concerns:

1. **Data exfiltration** — Auto-forwarding blocked via Remote Domain
2. **Audit trail** — Mailbox audit logging ensured via Organization Config
3. **Email authentication** — DKIM signing enabled for all domains
4. **Phishing awareness** — External sender tag and `[EXTERNAL]` subject prefix
5. **Shadow IT** — External storage providers and social accounts disabled in OWA
6. **Device security** — PIN, encryption, and wipe policies for mobile devices
7. **Oversharing** — Calendar sharing restricted to Free/Busy only
