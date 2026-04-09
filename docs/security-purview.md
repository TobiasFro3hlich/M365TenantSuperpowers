# Security & Compliance (Purview) Module

Manages Microsoft Purview data protection and compliance settings. Covers Data Loss Prevention (DLP), sensitivity labels, retention policies, audit log retention, and alert policies.

**Requires:** Exchange Online connection (`Connect-M365Tenant -Services ExchangeOnline`)

## Functions

### New-M365DLPPolicy

Creates or updates a DLP policy with rules for sensitive information types.

```powershell
New-M365DLPPolicy -ConfigName 'SEC-DLP-PII'
```

**Default config (SEC-DLP-PII):** Blocks sharing of credit card numbers, SSN, and ITIN across Exchange, SharePoint, OneDrive, and Teams. Deploys in test mode with notifications first.

**Also available:** `SEC-DLP-FinancialData` — Protects IBAN, SWIFT codes, credit cards (DACH-focused).

| Setting | Value |
|---------|-------|
| Mode | TestWithNotifications (safe deployment) |
| Locations | Exchange, SharePoint, OneDrive, Teams |
| Action | Block + notify site admin and last modifier |
| CISA | MS.DEFENDER.4.1v2, 4.2v1, 4.3v1, 4.4v1 |
| CIS | 3.2.1, 3.2.2 |

---

### New-M365SensitivityLabel

Creates a standard set of sensitivity labels.

```powershell
New-M365SensitivityLabel -ConfigName 'SEC-SensitivityLabels'
```

**Default labels:**

| Label | Priority | Encryption | Content Marking |
|-------|----------|------------|-----------------|
| Public | 0 | No | None |
| Internal | 1 | No | Header + Footer |
| Confidential | 2 | No | Header + Footer "CONFIDENTIAL" |
| Highly Confidential | 3 | **Yes** (Do Not Forward) | Header + Footer + Watermark |

---

### Set-M365LabelPolicy

Publishes sensitivity labels to users.

```powershell
Set-M365LabelPolicy -ConfigName 'SEC-LabelPolicy'
```

**Default config:** Publishes all 4 labels to all users with mandatory labeling and justification required for downgrades. CIS 3.3.1.

---

### New-M365RetentionPolicy

Creates retention policies across workloads.

```powershell
New-M365RetentionPolicy -ConfigName 'SEC-RetentionDefault'
```

**Default config:** Retains content for 1 year across Exchange, SharePoint, OneDrive, and Teams. Action: KeepAndDelete after 365 days.

---

### Set-M365AuditRetention

Enables unified audit logging and creates retention policies.

```powershell
Set-M365AuditRetention -ConfigName 'SEC-AuditRetention'
```

**What it does:**
1. Ensures unified audit logging is enabled
2. Creates 12-month audit retention for all activities
3. Creates specific retention for admin activities (Entra, Exchange, SharePoint)

| CISA | CIS |
|------|-----|
| MS.DEFENDER.6.1v1 (audit enabled) | 3.1.1 |
| MS.DEFENDER.6.3v1 (12+ months retention) | |

---

### Set-M365AlertPolicy

Enables CISA-required alert policies.

```powershell
Set-M365AlertPolicy -ConfigName 'SEC-AlertPolicies'
```

**Alerts enabled (CISA MS.DEFENDER.5.1v1):**
- Suspicious email sending patterns
- Suspicious connector activity
- Suspicious Email Forwarding Activity
- Messages have been delayed
- Tenant restricted from sending email
- Potentially malicious URL click detected
- Malicious URL/malware removed after delivery

---

### Get-M365SecurityReport

Generates a report of current security/compliance settings.

```powershell
Get-M365SecurityReport | Export-M365Report -Format HTML -Title 'Security Audit'
```

Reports on: Audit logging status, DLP policies, sensitivity labels, label policies, retention policies, alert policies (system alerts, disabled count).

---

### Import-M365SecurityConfigSet

Bulk-applies security configs.

```powershell
Import-M365SecurityConfigSet -ConfigNames @(
    'SEC-AuditRetention', 'SEC-AlertPolicies',
    'SEC-DLP-PII', 'SEC-DLP-FinancialData',
    'SEC-SensitivityLabels', 'SEC-LabelPolicy',
    'SEC-RetentionDefault'
)
```

## Built-in Configs

| Config | Severity | What it configures |
|--------|----------|--------------------|
| SEC-DLP-PII | Critical | DLP for credit cards, SSN, ITIN |
| SEC-DLP-FinancialData | High | DLP for IBAN, SWIFT, credit cards |
| SEC-SensitivityLabels | Critical | 4 labels: Public → Highly Confidential |
| SEC-LabelPolicy | Critical | Publish labels, mandatory labeling |
| SEC-RetentionDefault | High | 1 year retention all workloads |
| SEC-AuditRetention | Critical | Audit log 12-month retention |
| SEC-AlertPolicies | Critical | 9 CISA-required alert policies |
