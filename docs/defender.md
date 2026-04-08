# Defender for Office 365 Module

Manages Microsoft Defender for Office 365 (formerly ATP) threat protection policies. Covers Safe Links, Safe Attachments, anti-phishing, anti-spam, anti-malware, and global ATP settings.

**Requires:** Exchange Online connection (`Connect-M365Tenant -Services ExchangeOnline`)

## Functions

### Set-M365DefenderGlobal

Configures tenant-wide Defender/ATP settings.

```powershell
Set-M365DefenderGlobal -ConfigName 'DEF-AtpGlobal'
```

**What it enables:**

| Setting | Value | Impact |
|---------|-------|--------|
| Safe Attachments for SPO/OneDrive/Teams | `true` | Scans files uploaded to SharePoint, OneDrive, and Teams |
| Safe Documents | `true` | Scans documents opened in Protected View |
| Allow Safe Docs Open | `false` | Blocks opening documents that fail scanning |

---

### Set-M365DefenderSafeLinks

Configures Safe Links URL protection policy.

```powershell
Set-M365DefenderSafeLinks -ConfigName 'DEF-SafeLinks'
```

**Default config:**

| Setting | Value | What it does |
|---------|-------|-------------|
| Email scanning | Enabled | Rewrites and scans URLs in emails |
| Teams scanning | Enabled | Scans URLs in Teams messages |
| Office scanning | Enabled | Scans URLs in Office documents |
| Real-time URL scan | Enabled | Scans at click time, not just at delivery |
| Wait for scan | Enabled | Holds message delivery until URL scan completes |
| Internal senders | Enabled | Also scans URLs from internal users (compromised account protection) |
| Track clicks | Enabled | Logs URL click events |
| Allow click-through | `false` | Blocks users from clicking through warning pages |
| URL rewriting | Enabled | Rewrites URLs for protection |

**Customize:** Add URLs to exclude from rewriting via the `doNotRewriteUrls` parameter (e.g., internal app URLs).

---

### Set-M365DefenderSafeAttachments

Configures Safe Attachments detonation policy.

```powershell
Set-M365DefenderSafeAttachments -ConfigName 'DEF-SafeAttachments'
```

**Default config:** Dynamic Delivery mode — emails are delivered immediately with placeholder attachments while originals are scanned in a sandbox. If malware is detected, the attachment is quarantined.

| Action Mode | Behavior |
|-------------|----------|
| `DynamicDelivery` | **(Default)** Immediate delivery, async scan, minimal delay |
| `Block` | Hold entire message until scan completes |
| `Replace` | Deliver message body, remove attachment if malicious |
| `Monitor` | Deliver everything, log results only |

**Optional:** Set `Redirect: true` and `RedirectAddress` to forward detected malicious attachments to a SecOps mailbox for analysis.

---

### Set-M365DefenderAntiPhish

Configures anti-phishing policy with impersonation and spoof protection.

```powershell
Set-M365DefenderAntiPhish -ConfigName 'DEF-AntiPhish'
```

**Default config highlights:**

| Feature | Setting | Impact |
|---------|---------|--------|
| Phish threshold | Level 3 (Aggressive) | More aggressive phishing detection |
| Mailbox intelligence | Enabled | Learns user mail patterns to detect impersonation |
| Mailbox intelligence protection | Quarantine | Quarantines impersonation attempts |
| Spoof intelligence | Enabled | Detects spoofed senders |
| Honor DMARC | Enabled | Respects sender's DMARC policy |
| First contact safety tips | Enabled | Warns on first email from a new sender |
| Similar users safety tips | Enabled | Warns on display names similar to internal users |
| Similar domains safety tips | Enabled | Warns on domains similar to org domains |
| Unauthenticated sender tag | Enabled | Shows "?" icon for unauthenticated senders |
| Organization domain protection | Enabled | Protects against impersonation of org domains |

---

### Set-M365DefenderAntiSpam

Configures inbound spam filtering (hosted content filter) policy.

```powershell
Set-M365DefenderAntiSpam -ConfigName 'DEF-AntiSpam'
```

**Default config (Microsoft Standard recommendations):**

| Verdict | Action |
|---------|--------|
| Spam | Move to Junk folder |
| High-confidence spam | Quarantine |
| Phishing | Quarantine |
| High-confidence phishing | Quarantine |
| Bulk mail | Move to Junk folder |

- Bulk threshold: 6 (range 1-9, lower = more aggressive)
- Zero-hour Auto Purge (ZAP): Enabled for spam and phishing
- Quarantine retention: 30 days
- All ASF (Advanced Spam Filter) options: Off (Microsoft recommendation)

---

### Set-M365DefenderAntiMalware

Configures anti-malware filtering policy.

```powershell
Set-M365DefenderAntiMalware -ConfigName 'DEF-AntiMalware'
```

**Default config:**
- Common attachment filter: Enabled (blocks .exe, .bat, .cmd, .js, etc.)
- File type action: Reject (NDR to sender)
- Zero-hour Auto Purge: Enabled
- Admin notifications: Disabled by default (enable per customer)

---

### Get-M365DefenderReport

Generates a comprehensive report of all Defender policies.

```powershell
# Full audit
Get-M365DefenderReport | Export-M365Report -Format HTML -Title 'Defender Policy Audit'

# Quick console view
Get-M365DefenderReport | Export-M365Report -Format Console
```

Reports on: ATP Global settings, Anti-Phishing policies, Safe Links policies, Safe Attachments policies, Anti-Spam policies, Anti-Malware policies.

---

### Import-M365DefenderConfigSet

Bulk-applies Defender configs. Routes each config to the correct function based on `metadata.category`.

```powershell
# Deploy full Defender stack
Import-M365DefenderConfigSet -ConfigNames @(
    'DEF-AtpGlobal',
    'DEF-SafeLinks',
    'DEF-SafeAttachments',
    'DEF-AntiPhish',
    'DEF-AntiSpam',
    'DEF-AntiMalware'
)
```

## Built-in Configs

| Config | Severity | What it configures |
|--------|----------|--------------------|
| DEF-AtpGlobal | Critical | Safe Attachments for SPO/ODB/Teams, Safe Documents |
| DEF-AntiPhish | Critical | Impersonation, spoof intelligence, DMARC, safety tips |
| DEF-AntiSpam | Critical | Spam thresholds, quarantine actions, ZAP |
| DEF-AntiMalware | Critical | Common attachment filter, ZAP, reject action |
| DEF-SafeLinks | Critical | URL scanning in email/Teams/Office, click tracking |
| DEF-SafeAttachments | Critical | Dynamic Delivery sandbox scanning |

## Policy + Rule Architecture

Defender policies in Exchange Online follow a **policy + rule** pattern:
- **Policy** defines the *settings* (what to do)
- **Rule** defines the *scope* (who it applies to — recipients, domains)

Our functions handle both automatically. When you apply a config, it creates/updates both the policy and its associated rule. The rule's `RecipientDomainIs` defaults to empty (applies to all), but can be scoped per customer.
