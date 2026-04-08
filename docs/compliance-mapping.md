# Compliance Mapping

Maps every M365TenantSuperpowers config to official security baselines. Each config references which CISA SCuBA, CIS Benchmark v6, and Microsoft Standard/Strict controls it satisfies.

## Baseline Sources

| Source | Controls | Coverage | Machine-Readable |
|--------|----------|----------|-----------------|
| **CISA SCuBA** | 76 (51 SHALL, 25 SHOULD) | Entra, EXO, Defender, SPO, Teams | ScubaGear (JSON/CSV) |
| **CIS M365 v6** | 140 (94 L1, 46 L2) | Entra, EXO, Defender, SPO, Teams, Intune, Power BI, Purview | Maester / CIS-CAT |
| **MS Defender Presets** | ~60 settings | EOP + Defender for O365 | PowerShell queryable |

## Legend

- **Covered** = Our config implements this control
- **Partial** = Our config addresses part of the control but needs adjustment
- **Gap** = Control not yet implemented in our toolkit
- **N/A** = Outside scope (DNS, SIEM, manual/operational)

---

## 1. ENTRA ID / CONDITIONAL ACCESS

### Our Configs vs. CISA SCuBA (28 controls)

| CISA ID | Control | Level | Our Config | Status |
|---------|---------|-------|------------|--------|
| MS.AAD.1.1v1 | Block legacy authentication | SHALL | `CA001-BlockLegacyAuth` | Covered |
| MS.AAD.2.1v1 | Block high-risk users | SHALL | — | **Gap** (need CA for user risk) |
| MS.AAD.2.3v1 | Block high-risk sign-ins | SHALL | `CA004-BlockHighRiskSignIns` | Covered |
| MS.AAD.3.1v1 | Phishing-resistant MFA for all users | SHALL | `CA003-RequireMFAAllUsers` | **Partial** (MFA, not phishing-resistant strength) |
| MS.AAD.3.2v2 | MFA for all users | SHALL | `CA003-RequireMFAAllUsers` | Covered |
| MS.AAD.3.3v2 | Authenticator context info | SHALL | `ENTRA-AuthMethodPolicy` | Covered |
| MS.AAD.3.4v1 | Migration Complete | SHALL | `ENTRA-AuthMethodPolicy` | **Gap** (need to add) |
| MS.AAD.3.5v2 | Disable SMS, Voice, Email OTP | SHALL | `ENTRA-AuthMethodPolicy` | **Partial** (SMS/Voice disabled, Email enabled) |
| MS.AAD.3.6v1 | Phishing-resistant MFA for admins | SHALL | `CA002-RequireMFAAdmins` | **Partial** (MFA, not phishing-resistant) |
| MS.AAD.3.7v1 | Require managed devices | SHOULD | `CA005-RequireCompliantDevice` | Covered |
| MS.AAD.3.8v1 | Managed device for MFA registration | SHOULD | — | **Gap** (new CA policy needed) |
| MS.AAD.3.9v1 | Block device code flow | SHOULD | — | **Gap** (new CA policy needed) |
| MS.AAD.5.1v1 | Only admins register apps | SHALL | `ENTRA-AuthorizationPolicy` | Covered |
| MS.AAD.5.2v1 | Restrict user consent | SHALL | `ENTRA-AdminConsent` | Covered |
| MS.AAD.5.3v1 | Admin consent workflow | SHALL | `ENTRA-AdminConsent` | Covered |
| MS.AAD.6.1v1 | Passwords never expire | SHALL | `ENTRA-PasswordProtection` | **Gap** (need to add) |
| MS.AAD.7.1-7.9 | PIM/PAM controls (8 controls) | SHALL | — | **Gap** (PIM not implemented) |
| MS.AAD.8.1v1 | Restrict guest directory access | SHOULD | `ENTRA-AuthorizationPolicy` | Covered |
| MS.AAD.8.2v1 | Guest inviter role only | SHOULD | `ENTRA-AuthorizationPolicy` | Covered |

### Our Configs vs. CIS v6 (Entra section, 42 controls)

| CIS ID | Control | Level | Our Config | Status |
|--------|---------|-------|------------|--------|
| 5.2.2.1 | MFA for admin roles | L1 | `CA002-RequireMFAAdmins` | Covered |
| 5.2.2.2 | MFA for all users | L1 | `CA003-RequireMFAAllUsers` | Covered |
| 5.2.2.3 | Block legacy auth | L1 | `CA001-BlockLegacyAuth` | Covered |
| 5.2.2.4 | Sign-in frequency for admins | L1 | `CA009-SessionTimeout` | Covered |
| 5.2.2.5 | Phishing-resistant MFA for admins | L2 | `CA002` | **Partial** |
| 5.2.2.6 | User risk policy | L1 | — | **Gap** |
| 5.2.2.7 | Sign-in risk policy | L1 | `CA004` | Covered |
| 5.2.2.9 | Managed device required | L1 | `CA005` | Covered |
| 5.2.2.10 | Managed device for MFA reg | L1 | — | **Gap** |
| 5.2.2.12 | Block device code flow | L1 | — | **Gap** |
| 5.2.3.1 | Authenticator number matching | L1 | `ENTRA-AuthMethodPolicy` | Covered |
| 5.2.3.2 | Custom banned passwords | L1 | `ENTRA-PasswordProtection` | Covered |
| 5.2.3.5 | Disable weak auth methods | L1 | `ENTRA-AuthMethodPolicy` | **Partial** |
| 5.1.5.2 | Admin consent workflow | L1 | `ENTRA-AdminConsent` | Covered |
| 1.3.1 | Passwords never expire | L1 | — | **Gap** |

---

## 2. DEFENDER FOR OFFICE 365

### Our Configs vs. Microsoft Standard/Strict

| Policy | Our Config | Aligns With | Corrections Needed |
|--------|-----------|-------------|-------------------|
| Anti-Phish | `DEF-AntiPhish` | **Standard** | PhishThreshold=3 correct; need QuarantineTag values |
| Anti-Spam | `DEF-AntiSpam` | **Standard** | SpamAction=MoveToJmf correct; need QuarantineTag values; QuarantineRetention should be 30 |
| Anti-Malware | `DEF-AntiMalware` | **Standard** | Values match Standard |
| Safe Links | `DEF-SafeLinks` | **Standard** | Action matches; DisableUrlRewrite should be $false (correct) |
| Safe Attachments | `DEF-SafeAttachments` | **Correction needed** | Action should be `Block` not `DynamicDelivery` for Standard/Strict |
| ATP Global | `DEF-AtpGlobal` | **Standard** | Matches Built-in Protection |

### Our Configs vs. CISA SCuBA (17 controls)

| CISA ID | Control | Level | Our Config | Status |
|---------|---------|-------|------------|--------|
| MS.DEFENDER.1.1v1 | Enable preset security policies | SHALL | DEF configs | **Partial** (custom policies, not presets) |
| MS.DEFENDER.1.2-1.5 | Assign presets to all users | SHALL | — | **Gap** (preset assignment) |
| MS.DEFENDER.2.1-2.3 | Impersonation protection | SHOULD | `DEF-AntiPhish` | Covered |
| MS.DEFENDER.3.1v1 | Safe Attachments for SPO/Teams | SHOULD | `DEF-AtpGlobal` | Covered |
| MS.DEFENDER.4.1v2 | DLP for PII | SHALL | — | **Gap** (DLP module needed) |
| MS.DEFENDER.5.1v1 | Alert policies | SHALL | — | **Gap** (Alerts not implemented) |
| MS.DEFENDER.6.1v1 | Unified audit logging | SHALL | `EXO-OrganizationConfig` | Covered (AuditDisabled=false) |

---

## 3. EXCHANGE ONLINE

### Our Configs vs. CISA SCuBA (10 controls)

| CISA ID | Control | Level | Our Config | Status |
|---------|---------|-------|------------|--------|
| MS.EXO.1.1v2 | Block auto-forwarding | SHALL | `EXO-RemoteDomain` | Covered |
| MS.EXO.2.2v3 | SPF records | SHALL | — | N/A (DNS) |
| MS.EXO.3.1v1 | DKIM enabled | SHOULD | `EXO-Dkim` | Covered |
| MS.EXO.4.1-4.4 | DMARC records | SHALL | — | N/A (DNS) |
| MS.EXO.5.1v1 | Disable SMTP AUTH | SHALL | `EXO-OrganizationConfig` | **Gap** (need SmtpClientAuthenticationDisabled) |
| MS.EXO.6.1v1 | No contact sharing with all domains | SHALL | `EXO-SharingPolicy` | Covered |
| MS.EXO.6.2v1 | No calendar detail sharing with all | SHALL | `EXO-SharingPolicy` | Covered |
| MS.EXO.7.1v1 | External sender warnings | SHALL | `EXO-TransportRules` + `EXO-ExternalTag` | Covered |
| MS.EXO.13.1v1 | Mailbox auditing enabled | SHALL | `EXO-OrganizationConfig` | Covered |

### Our Configs vs. CIS v6 (14 controls)

| CIS ID | Control | Level | Our Config | Status |
|--------|---------|-------|------------|--------|
| 6.1.1 | AuditDisabled = False | L1 | `EXO-OrganizationConfig` | Covered |
| 6.2.1 | Block all mail forwarding | L1 | `EXO-RemoteDomain` | Covered |
| 6.2.3 | External sender identified | L1 | `EXO-ExternalTag` + `EXO-TransportRules` | Covered |
| 6.5.1 | Modern auth enabled | L1 | `EXO-OrganizationConfig` | Covered (OAuth2) |
| 6.5.2 | MailTips enabled | L1 | `EXO-OrganizationConfig` | Covered |
| 6.5.3 | Additional storage restricted | L2 | `EXO-OwaPolicy` | Covered |
| 6.5.4 | SMTP AUTH disabled | L1 | — | **Gap** |
| 6.3.1 | Outlook add-ins restricted | L2 | — | **Gap** |

---

## 4. SHAREPOINT ONLINE

### Our Configs vs. CISA SCuBA (8 controls)

| CISA ID | Control | Level | Our Config | Status |
|---------|---------|-------|------------|--------|
| MS.SHAREPOINT.1.1v1 | Sharing limited to existing guests | SHALL | `SPO-SharingSettings` | Covered |
| MS.SHAREPOINT.1.2v1 | OneDrive sharing limited | SHALL | `SPO-SharingSettings` | Covered |
| MS.SHAREPOINT.1.3v1 | Sharing restricted by domain | SHALL | `SPO-SharingSettings` | **Partial** (structure there, needs domain list) |
| MS.SHAREPOINT.2.1v1 | Default link = Specific people | SHALL | `SPO-SharingSettings` | **Correction** (we set Internal, CISA wants Specific People) |
| MS.SHAREPOINT.2.2v1 | Default permission = View | SHALL | `SPO-SharingSettings` | Covered |
| MS.SHAREPOINT.3.1v1 | Anyone links expire 30 days | SHALL | `SPO-SharingSettings` | Covered |
| MS.SHAREPOINT.3.2v1 | Anyone links = View only | SHALL | `SPO-SharingSettings` | Covered |
| MS.SHAREPOINT.3.3v1 | Reauth within 30 days | SHALL | `SPO-SharingSettings` | Covered |

---

## 5. MICROSOFT TEAMS

### Our Configs vs. CISA SCuBA (13 controls)

| CISA ID | Control | Level | Our Config | Status |
|---------|---------|-------|------------|--------|
| MS.TEAMS.1.1v1 | External no request control | SHOULD | `TEAMS-MeetingPolicy` | Covered |
| MS.TEAMS.1.2v2 | Anonymous can't start meetings | SHALL | `TEAMS-MeetingPolicy` | **Gap** (need to add setting) |
| MS.TEAMS.1.3v1 | Anonymous not auto-admitted | SHOULD | `TEAMS-MeetingPolicy` | Covered |
| MS.TEAMS.1.6v1 | Recording disabled | SHOULD | `TEAMS-MeetingPolicy` | **Conflict** (we enable recording) |
| MS.TEAMS.2.1v2 | External per-domain only | SHALL | `TEAMS-Federation` | **Partial** (we allow all federated, CISA wants per-domain) |
| MS.TEAMS.2.2v2 | Unmanaged users can't initiate | SHALL | `TEAMS-Federation` | Covered (consumer blocked) |
| MS.TEAMS.4.1v1 | Email into channel disabled | SHALL | `TEAMS-ClientConfig` | **Conflict** (we enable it) |
| MS.TEAMS.5.1-5.3 | App restrictions | SHOULD | `TEAMS-AppPermissions` | Covered |

---

## Summary: Gaps to Close

### Critical Gaps (SHALL-level, not covered)

| # | Gap | Baseline | Action Needed |
|---|-----|----------|---------------|
| 1 | Block high-risk **users** (not just sign-ins) | CISA MS.AAD.2.1v1, CIS 5.2.2.6 | New CA policy: `CA011-BlockHighRiskUsers` |
| 2 | Block device code flow | CISA MS.AAD.3.9v1, CIS 5.2.2.12 | New CA policy: `CA012-BlockDeviceCodeFlow` |
| 3 | Managed device for MFA registration | CISA MS.AAD.3.8v1, CIS 5.2.2.10 | New CA policy: `CA013-RequireManagedDeviceForMFAReg` |
| 4 | Passwords never expire | CISA MS.AAD.6.1v1, CIS 1.3.1 | Add to `ENTRA-AuthorizationPolicy` or EXO config |
| 5 | SMTP AUTH disabled | CISA MS.EXO.5.1v1, CIS 6.5.4 | Add `SmtpClientAuthenticationDisabled` to `EXO-OrganizationConfig` |
| 6 | DLP policies for PII | CISA MS.DEFENDER.4.1v2, CIS 3.2.1 | New module: `src/Security/` with DLP |
| 7 | Alert policies enabled | CISA MS.DEFENDER.5.1v1 | New config for alert policies |
| 8 | PIM configuration (8 controls) | CISA MS.AAD.7.x | New module or extension for PIM |

### Config Corrections Needed

| Config | Issue | Correction |
|--------|-------|-----------|
| `DEF-SafeAttachments` | Action=DynamicDelivery | Change to `Block` (MS Standard/Strict) |
| `SPO-SharingSettings` | DefaultSharingLinkType=Internal | Change to `Direct` (CISA wants "Specific People") |
| `ENTRA-AuthMethodPolicy` | Email OTP enabled | Disable per CISA MS.AAD.3.5v2 |
| `TEAMS-MeetingPolicy` | Recording=true | Conflicts with CISA MS.TEAMS.1.6v1 (SHOULD disable) |
| `TEAMS-ClientConfig` | AllowEmailIntoChannel=true | Conflicts with CISA MS.TEAMS.4.1v1 (SHALL disable) |
| `TEAMS-Federation` | AllowFederatedUsers=true (all) | CISA wants per-domain only (SHALL) |
| `EXO-OrganizationConfig` | Missing SmtpClientAuthenticationDisabled | Add `SmtpClientAuthenticationDisabled = $true` |
