# Intune / Endpoint Manager Module

Manages Microsoft Intune device compliance, enrollment restrictions, and app protection (MAM) policies. Ensures only secure, managed devices access corporate data.

**Requires:** Graph connection (`Connect-M365Tenant -TenantId ... -Services Graph`)

## Functions

### Set-M365IntuneComplianceSettings

Configures tenant-wide compliance settings.

```powershell
Set-M365IntuneComplianceSettings -ConfigName 'INTUNE-ComplianceSettings'
```

**Critical setting:** `secureByDefault = true` — marks devices without a compliance policy as **non-compliant**. Without this, unmanaged devices bypass CA device compliance policies. CIS 4.1.

---

### New-M365IntuneCompliancePolicy

Creates platform-specific device compliance policies.

```powershell
New-M365IntuneCompliancePolicy -ConfigName 'INTUNE-ComplianceWindows'
New-M365IntuneCompliancePolicy -ConfigName 'INTUNE-ComplianceiOS'
New-M365IntuneCompliancePolicy -ConfigName 'INTUNE-ComplianceAndroid'
```

**Windows compliance requirements:**

| Setting | Value |
|---------|-------|
| BitLocker | Required |
| Secure Boot | Required |
| Code Integrity | Required |
| Firewall | Required |
| Defender | Required + real-time protection |
| Antivirus/Antispyware | Required |
| Password | 8 chars, alphanumeric |
| Min OS | 10.0.19045 (22H2) |
| Encryption | Required |
| Grace period | 24 hours before block |

**iOS compliance:** Jailbreak blocked, passcode 6+ digits, min OS 16.0

**Android compliance:** Root blocked, password 6+ digits complex, min OS 13.0, encryption, verify apps

All policies auto-assign to all licensed users.

---

### Set-M365IntuneEnrollmentRestriction

Configures enrollment restrictions and device limits.

```powershell
Set-M365IntuneEnrollmentRestriction -ConfigName 'INTUNE-EnrollmentRestriction'
```

**Default config (CIS 4.2):**
- **Personal devices blocked** on all platforms (Windows, iOS, Android, macOS)
- Device limit: 15 per user
- Minimum OS versions enforced per platform

---

### New-M365IntuneAppProtection

Creates app protection (MAM) policies for BYOD scenarios.

```powershell
New-M365IntuneAppProtection -ConfigName 'INTUNE-AppProtectioniOS'
New-M365IntuneAppProtection -ConfigName 'INTUNE-AppProtectionAndroid'
```

**What MAM protects (without device enrollment):**

| Protection | iOS | Android |
|-----------|-----|---------|
| Data transfer to unmanaged apps | Blocked | Blocked |
| Clipboard (copy/paste out) | Managed apps only | Managed apps only |
| Backup to cloud | Blocked | Blocked |
| Save As to unmanaged | Blocked | Blocked |
| Print | Blocked | Blocked |
| Screenshot | N/A | Blocked |
| PIN required | 6 digits, no simple | 6 digits, no simple |
| Encryption | When device locked | Required |
| Jailbreak/Root | Block access | Block access |
| Offline grace period | 12 hours | 12 hours |
| Wipe after offline | 90 days | 90 days |

---

### Get-M365IntuneReport

Generates a report of current Intune configuration.

```powershell
Get-M365IntuneReport | Export-M365Report -Format HTML -Title 'Intune Audit'
```

Reports on: Compliance settings (secure-by-default), compliance policies per platform, enrollment restrictions (device limit, personal blocked per platform), app protection policy count.

---

### Import-M365IntuneConfigSet

Bulk-applies Intune configs.

```powershell
Import-M365IntuneConfigSet -ConfigNames @(
    'INTUNE-ComplianceSettings',
    'INTUNE-EnrollmentRestriction',
    'INTUNE-ComplianceWindows', 'INTUNE-ComplianceiOS', 'INTUNE-ComplianceAndroid',
    'INTUNE-AppProtectioniOS', 'INTUNE-AppProtectionAndroid'
)
```

## Built-in Configs

| Config | Severity | What it configures |
|--------|----------|--------------------|
| INTUNE-ComplianceSettings | Critical | secureByDefault=true (CIS 4.1) |
| INTUNE-ComplianceWindows | Critical | BitLocker, Defender, Firewall, password, encryption |
| INTUNE-ComplianceiOS | Critical | Jailbreak block, passcode, min OS |
| INTUNE-ComplianceAndroid | Critical | Root block, password, encryption, min OS |
| INTUNE-EnrollmentRestriction | High | Block personal devices (CIS 4.2), device limit 15 |
| INTUNE-AppProtectioniOS | Critical | MAM: data transfer, PIN, encryption, jailbreak |
| INTUNE-AppProtectionAndroid | Critical | MAM: data transfer, PIN, encryption, screenshot block |
