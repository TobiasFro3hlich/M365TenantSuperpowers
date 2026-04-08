# Coverage Overview

Status der M365TenantSuperpowers Abdeckung gegen die drei offiziellen Baselines: CISA SCuBA, CIS Microsoft 365 v6, und Microsoft Standard/Strict Presets.

**Stand: April 2026**

---

## Gesamtübersicht

| Metrik | Wert |
|--------|------|
| Module | 9 |
| Exportierte Functions | 85 |
| JSON Configs | 63 |
| Configs mit Compliance-Referenz | 44 (70%) |
| CISA SCuBA Controls referenziert | 56 von 76 (74%) |
| CIS v6 Controls referenziert | 65 von 140 (46%) |
| Profile | SMB-Standard (17 Steps), Enterprise-Hardened (23 Steps) |

---

## Abdeckung nach Modul

| Modul | Functions | Configs | CISA Covered | CIS Covered | Status |
|-------|-----------|---------|-------------|-------------|--------|
| ConditionalAccess | 7 | 13 | 12/12 relevant | 12/12 relevant | Vollständig |
| EntraID (inkl. PIM) | 15 | 11 | 24/28 (86%) | 20/42 (48%) | Gut |
| Defender | 8 | 6 | 6/17 (35%) | 8/20 (40%) | Ausbaufähig |
| Exchange | 10 | 8 | 5/10 (50%) | 8/14 (57%) | Gut |
| SharePoint | 5 | 3 | 6/8 (75%) | 7/13 (54%) | Gut |
| Teams | 10 | 8 | 9/13 (69%) | 10/16 (63%) | Gut |
| Security/Purview | 8 | 7 | 6/6 relevant | 4/4 relevant | Vollständig |
| Intune | 6 | 7 | 0/0 (N/A) | 2/2 (100%) | Vollständig |
| Core | 6 | — | N/A | N/A | Framework |

---

## Detaillierte Abdeckung: CISA SCuBA (76 Controls)

### Entra ID — MS.AAD (28 Controls)

| CISA ID | Control | Level | Status | Unsere Config |
|---------|---------|-------|--------|--------------|
| MS.AAD.1.1v1 | Block legacy authentication | SHALL | ✅ Covered | `CA001-BlockLegacyAuth` |
| MS.AAD.2.1v1 | Block high-risk users | SHALL | ✅ Covered | `CA011-BlockHighRiskUsers` |
| MS.AAD.2.2v1 | Notify admin on high-risk users | SHOULD | ⚠️ Gap | Manual: Entra ID Protection notification |
| MS.AAD.2.3v1 | Block high-risk sign-ins | SHALL | ✅ Covered | `CA004-BlockHighRiskSignIns` |
| MS.AAD.3.1v1 | Phishing-resistant MFA all users | SHALL | ⚠️ Partial | `CA003` (MFA, not phishing-resistant strength) |
| MS.AAD.3.2v2 | MFA for all users | SHALL | ✅ Covered | `CA003-RequireMFAAllUsers` |
| MS.AAD.3.3v2 | Authenticator context info | SHALL | ✅ Covered | `ENTRA-AuthMethodPolicy` |
| MS.AAD.3.4v1 | Migration Complete | SHALL | ⚠️ Gap | Needs manual setting or config addition |
| MS.AAD.3.5v2 | Disable SMS, Voice, Email OTP | SHALL | ✅ Covered | `ENTRA-AuthMethodPolicy` |
| MS.AAD.3.6v1 | Phishing-resistant MFA admins | SHALL | ⚠️ Partial | `CA002` (MFA, not phishing-resistant strength) |
| MS.AAD.3.7v1 | Require managed devices | SHOULD | ✅ Covered | `CA005-RequireCompliantDevice` |
| MS.AAD.3.8v1 | Managed device for MFA reg | SHOULD | ✅ Covered | `CA013-RequireManagedDeviceForMFAReg` |
| MS.AAD.3.9v1 | Block device code flow | SHOULD | ✅ Covered | `CA012-BlockDeviceCodeFlow` |
| MS.AAD.4.1v1 | Send logs to SOC/SIEM | SHALL | ❌ N/A | Operational (SIEM config, not tenant config) |
| MS.AAD.5.1v1 | Only admins register apps | SHALL | ✅ Covered | `ENTRA-AuthorizationPolicy` |
| MS.AAD.5.2v1 | Restrict user consent | SHALL | ✅ Covered | `ENTRA-AdminConsent` |
| MS.AAD.5.3v1 | Admin consent workflow | SHALL | ✅ Covered | `ENTRA-AdminConsent` |
| MS.AAD.6.1v1 | Passwords never expire | SHALL | ⚠️ Gap | Needs tenant password policy config |
| MS.AAD.7.1v1 | 2-8 Global Admins | SHALL | 🔍 Audit | `Get-M365EntraPIMReport` checks this |
| MS.AAD.7.2v1 | Use fine-grained roles | SHALL | 🔍 Audit | `Get-M365EntraPIMReport` checks ratio |
| MS.AAD.7.3v1 | Cloud-only admin accounts | SHALL | 🔍 Audit | Operational check |
| MS.AAD.7.4v1 | No permanent active assignments | SHALL | ✅ Covered | `ENTRA-PIMRoleSettings` |
| MS.AAD.7.5v1 | All assignments via PIM | SHALL | ✅ Covered | `ENTRA-PIMRoleSettings` |
| MS.AAD.7.6v1 | GA activation requires approval | SHALL | ✅ Covered | `ENTRA-PIMRoleSettings` |
| MS.AAD.7.7v1 | Alert on role assignments | SHALL | ✅ Covered | `ENTRA-PIMRoleSettings` |
| MS.AAD.7.8v1 | Alert on GA activation | SHALL | ✅ Covered | `ENTRA-PIMRoleSettings` |
| MS.AAD.7.9v1 | Alert on other privileged activation | SHOULD | ✅ Covered | `ENTRA-PIMRoleSettings` |
| MS.AAD.8.1v1 | Restrict guest directory access | SHOULD | ✅ Covered | `ENTRA-AuthorizationPolicy` |
| MS.AAD.8.2v1 | Guest inviter role only | SHOULD | ✅ Covered | `ENTRA-AuthorizationPolicy` |
| MS.AAD.8.3v1 | Guest invites to specific domains | SHOULD | ⚠️ Partial | `ENTRA-CrossTenantDefault` (structure, needs domain list) |

**Entra Summary: 20 ✅ Covered, 4 ⚠️ Partial/Gap, 3 🔍 Audit-only, 1 ❌ N/A**

### Defender — MS.DEFENDER (17 Controls)

| CISA ID | Control | Level | Status | Unsere Config |
|---------|---------|-------|--------|--------------|
| MS.DEFENDER.1.1v1 | Enable preset security policies | SHALL | ⚠️ Partial | Custom policies statt Presets |
| MS.DEFENDER.1.2v1 | All users in EOP preset | SHALL | ⚠️ Gap | Preset assignment nicht implementiert |
| MS.DEFENDER.1.3v1 | All users in Defender preset | SHALL | ⚠️ Gap | Preset assignment nicht implementiert |
| MS.DEFENDER.1.4v1 | Sensitive accounts in strict | SHALL | ⚠️ Gap | Strict preset assignment nicht implementiert |
| MS.DEFENDER.1.5v1 | Sensitive accounts in strict Defender | SHALL | ⚠️ Gap | Strict preset assignment nicht implementiert |
| MS.DEFENDER.2.1v1 | User impersonation protection | SHOULD | ✅ Covered | `DEF-AntiPhish` |
| MS.DEFENDER.2.2v1 | Domain impersonation (org) | SHOULD | ✅ Covered | `DEF-AntiPhish` |
| MS.DEFENDER.2.3v1 | Domain impersonation (partners) | SHOULD | ✅ Covered | `DEF-AntiPhish` (needs domain list) |
| MS.DEFENDER.3.1v1 | Safe Attachments for SPO/Teams | SHOULD | ✅ Covered | `DEF-AtpGlobal` |
| MS.DEFENDER.4.1v2 | DLP for PII | SHALL | ✅ Covered | `SEC-DLP-PII` |
| MS.DEFENDER.4.2v1 | DLP across all workloads | SHOULD | ✅ Covered | `SEC-DLP-PII` (all locations) |
| MS.DEFENDER.4.3v1 | DLP block sharing | SHOULD | ✅ Covered | `SEC-DLP-PII` (blockAccess=true) |
| MS.DEFENDER.4.4v1 | DLP user notifications | SHOULD | ✅ Covered | `SEC-DLP-PII` (notifyUser) |
| MS.DEFENDER.4.5v1 | DLP restricted apps | SHOULD | ⚠️ Gap | Endpoint DLP nicht implementiert |
| MS.DEFENDER.4.6v1 | DLP block restricted apps | SHOULD | ⚠️ Gap | Endpoint DLP nicht implementiert |
| MS.DEFENDER.5.1v1 | Required alert policies | SHALL | ✅ Covered | `SEC-AlertPolicies` |
| MS.DEFENDER.5.2v1 | Alerts to monitored address | SHOULD | ✅ Covered | `SEC-AlertPolicies` (notifyRecipients) |
| MS.DEFENDER.6.1v1 | Unified audit logging | SHALL | ✅ Covered | `SEC-AuditRetention` |
| MS.DEFENDER.6.3v1 | Audit retention 12+ months | SHALL | ✅ Covered | `SEC-AuditRetention` |

**Defender Summary: 10 ✅ Covered, 7 ⚠️ Gap (davon 4x Preset Assignment)**

### Exchange Online — MS.EXO (10 Controls)

| CISA ID | Control | Level | Status | Unsere Config |
|---------|---------|-------|--------|--------------|
| MS.EXO.1.1v2 | Block auto-forwarding | SHALL | ✅ Covered | `EXO-RemoteDomain` |
| MS.EXO.2.2v3 | SPF records published | SHALL | ❌ N/A | DNS-Konfiguration (nicht M365) |
| MS.EXO.3.1v1 | DKIM enabled | SHOULD | ✅ Covered | `EXO-Dkim` |
| MS.EXO.4.1v1 | DMARC published | SHALL | ❌ N/A | DNS-Konfiguration (nicht M365) |
| MS.EXO.4.2v1 | DMARC p=reject | SHALL | ❌ N/A | DNS-Konfiguration |
| MS.EXO.4.3v1 | DMARC report to CISA | SHALL | ❌ N/A | DNS + nur für US Federal |
| MS.EXO.4.4v1 | DMARC agency contact | SHOULD | ❌ N/A | DNS-Konfiguration |
| MS.EXO.5.1v1 | SMTP AUTH disabled | SHALL | ✅ Covered | `EXO-OrganizationConfig` |
| MS.EXO.6.1v1 | No contact sharing with all | SHALL | ✅ Covered | `EXO-SharingPolicy` |
| MS.EXO.6.2v1 | No calendar detail sharing | SHALL | ✅ Covered | `EXO-SharingPolicy` |
| MS.EXO.7.1v1 | External sender warnings | SHALL | ✅ Covered | `EXO-ExternalTag` + `EXO-TransportRules` |
| MS.EXO.13.1v1 | Mailbox auditing enabled | SHALL | ✅ Covered | `EXO-OrganizationConfig` |

**Exchange Summary: 7 ✅ Covered, 0 ⚠️ Gap, 5 ❌ N/A (DNS)**

### SharePoint — MS.SHAREPOINT (8 Controls)

| CISA ID | Control | Level | Status | Unsere Config |
|---------|---------|-------|--------|--------------|
| MS.SHAREPOINT.1.1v1 | SPO sharing restricted | SHALL | ✅ Covered | `SPO-SharingSettings` |
| MS.SHAREPOINT.1.2v1 | ODB sharing restricted | SHALL | ✅ Covered | `SPO-SharingSettings` |
| MS.SHAREPOINT.1.3v1 | Sharing by domain/group | SHALL | ⚠️ Partial | Structure vorhanden, braucht Domain-Liste |
| MS.SHAREPOINT.2.1v1 | Default link = Specific People | SHALL | ✅ Covered | `SPO-SharingSettings` (Direct) |
| MS.SHAREPOINT.2.2v1 | Default permission = View | SHALL | ✅ Covered | `SPO-SharingSettings` |
| MS.SHAREPOINT.3.1v1 | Anyone links expire 30 days | SHALL | ✅ Covered | `SPO-SharingSettings` |
| MS.SHAREPOINT.3.2v1 | Anyone links = View only | SHALL | ✅ Covered | `SPO-SharingSettings` |
| MS.SHAREPOINT.3.3v1 | Reauth within 30 days | SHALL | ✅ Covered | `SPO-SharingSettings` |

**SharePoint Summary: 7 ✅ Covered, 1 ⚠️ Partial**

### Teams — MS.TEAMS (13 Controls)

| CISA ID | Control | Level | Status | Unsere Config |
|---------|---------|-------|--------|--------------|
| MS.TEAMS.1.1v1 | External no request control | SHOULD | ✅ Covered | `TEAMS-MeetingPolicy` |
| MS.TEAMS.1.2v2 | Anonymous can't start meetings | SHALL | ⚠️ Gap | Setting fehlt in Config |
| MS.TEAMS.1.3v1 | Anonymous not auto-admitted | SHOULD | ✅ Covered | `TEAMS-MeetingPolicy` |
| MS.TEAMS.1.4v1 | Internal auto-admitted | SHOULD | ✅ Covered | `TEAMS-MeetingPolicy` |
| MS.TEAMS.1.5v1 | Dial-in no lobby bypass | SHOULD | ⚠️ Gap | Setting fehlt in Config |
| MS.TEAMS.1.6v1 | Recording disabled | SHOULD | ⚠️ Bewusste Abweichung | Wir erlauben Recording (Kundenentscheidung) |
| MS.TEAMS.1.7v2 | Not Always Record events | SHOULD | ⚠️ Gap | Live Events Policy nicht implementiert |
| MS.TEAMS.2.1v2 | External per-domain only | SHALL | ⚠️ Partial | `TEAMS-Federation` (open, nicht per-domain) |
| MS.TEAMS.2.2v2 | Unmanaged can't initiate | SHALL | ✅ Covered | `TEAMS-Federation` (consumer blocked) |
| MS.TEAMS.2.3v2 | Internal no unmanaged contact | SHOULD | ✅ Covered | `TEAMS-Federation` |
| MS.TEAMS.4.1v1 | Email into channel disabled | SHALL | ✅ Covered | `TEAMS-ClientConfig` |
| MS.TEAMS.5.1v2 | Only approved Microsoft apps | SHOULD | ✅ Covered | `TEAMS-AppPermissions` |
| MS.TEAMS.5.2v2 | Only approved third-party apps | SHOULD | ✅ Covered | `TEAMS-AppPermissions` |
| MS.TEAMS.5.3v2 | Only approved custom apps | SHOULD | ✅ Covered | `TEAMS-AppPermissions` |

**Teams Summary: 9 ✅ Covered, 4 ⚠️ Gap/Partial**

---

## Detaillierte Abdeckung: CIS v6 (140 Controls)

### Nach Sektion

| CIS Sektion | Thema | Total | Covered | Gap | N/A |
|-------------|-------|-------|---------|-----|-----|
| 1 | M365 Admin Center | 15 | 4 | 6 | 5 |
| 2 | Defender/EOP | 20 | 12 | 5 | 3 |
| 3 | Microsoft Purview | 4 | 4 | 0 | 0 |
| 4 | Intune | 2 | 2 | 0 | 0 |
| 5 | Entra ID | 42 | 28 | 10 | 4 |
| 6 | Exchange Online | 14 | 9 | 3 | 2 |
| 7 | SharePoint/OneDrive | 13 | 8 | 3 | 2 |
| 8 | Teams | 16 | 10 | 4 | 2 |
| 9 | Power BI/Fabric | 12 | 0 | 12 | 0 |
| **Total** | | **140** | **77 (55%)** | **43 (31%)** | **18 (13%)** |

### Wichtigste CIS-Lücken (L1 Controls nicht abgedeckt)

| CIS ID | Control | Level | Was fehlt |
|--------|---------|-------|-----------|
| 1.1.4 | Admin accounts reduced license footprint | L1 | Operational audit |
| 1.2.2 | Block sign-in for shared mailboxes | L1 | EXO function needed |
| 1.3.4 | Restrict user owned apps/services | L1 | Admin center setting |
| 1.3.5 | Forms phishing protection | L1 | Admin center setting |
| 2.1.6 | Outbound spam admin notifications | L1 | Outbound spam config |
| 2.1.8 | SPF records published | L1 | DNS (N/A) |
| 2.1.10 | DMARC records published | L1 | DNS (N/A) |
| 2.1.12 | Connection filter IP allow list empty | L1 | Defender connection filter config |
| 2.1.13 | Connection filter safe list off | L1 | Defender connection filter config |
| 2.1.14 | No allowed sender domains | L1 | Anti-spam policy check |
| 5.1.2.4 | Restrict Entra admin center access | L1 | Entra setting |
| 5.1.3.1 | Dynamic group for guests | L1 | Group creation function |
| 5.1.3.2 | Users cannot create security groups | L1 | Entra setting (new v6) |
| 5.2.2.11 | Sign-in frequency for Intune enrollment | L1 | New CA policy |
| 5.2.3.4 | All users MFA capable | L1 | Audit/report only |
| 5.2.3.6 | System-preferred MFA | L1 | Auth method setting |
| 5.2.4.1 | SSPR enabled for all | L1 | Entra setting |
| 5.3.2 | Access reviews for guests | L1 | PIM/Governance function |
| 5.3.3 | Access reviews for privileged roles | L1 | PIM/Governance function |
| 6.1.2 | All mailbox audit actions configured | L1 | EXO audit config |
| 6.2.2 | No transport rules whitelisting domains | L1 | Audit/validation function |
| 8.2.4 | Disable Skype communication | L1 | In `TEAMS-Federation` (AllowPublicUsers=false) ✅ |
| 8.6.1 | Users can report security concerns | L1 | Teams setting |
| **9.x** | **Power BI / Fabric (12 Controls)** | **L1** | **Komplett fehlend** |

---

## Abdeckung: Microsoft Standard/Strict Presets

| Policy | Unsere Config | Aligned With | Abweichungen |
|--------|--------------|-------------|--------------|
| Anti-Malware | `DEF-AntiMalware` | ✅ Standard | Keine |
| Anti-Spam (Inbound) | `DEF-AntiSpam` | ✅ Standard | Keine (BulkThreshold=6) |
| Anti-Phishing (EOP) | `DEF-AntiPhish` | ✅ Standard | Keine (PhishThreshold=3) |
| Anti-Phishing (Defender) | `DEF-AntiPhish` | ✅ Standard | QuarantineTag-Werte fehlen |
| Safe Attachments | `DEF-SafeAttachments` | ✅ Standard/Strict | Action=Block korrekt |
| Safe Links | `DEF-SafeLinks` | ✅ Standard | Keine |
| ATP Global | `DEF-AtpGlobal` | ✅ Built-in Protection | Keine |
| Anti-Spam (Outbound) | — | ❌ Nicht implementiert | Outbound Spam Policy fehlt |

---

## Zusammenfassung: Was fehlt

### Prio 1 — Schnelle Gewinne (wenig Aufwand, hohe Compliance-Wirkung)

| # | Was | Betroffene Controls | Aufwand |
|---|-----|--------------------|---------|
| 1 | Teams Meeting Settings ergänzen (AnonymousCanStartMeeting, DialInBypassLobby) | CISA MS.TEAMS.1.2, 1.5 | 2 Settings in JSON |
| 2 | Outbound Spam Policy Config | CIS 2.1.6, 2.1.15 | 1 neue JSON Config |
| 3 | Connection Filter Config (IP Allow empty, Safe List off) | CIS 2.1.12, 2.1.13 | 1 neue JSON Config |
| 4 | System-preferred MFA aktivieren | CIS 5.2.3.6 | 1 Setting in Auth Method |
| 5 | SSPR Enabled for All | CIS 5.2.4.1 | 1 Setting in Auth Policy |
| 6 | Compliance-Referenzen zu den 19 Configs ohne Block hinzufügen | Coverage-Tracking | Metadata nur |

### Prio 2 — Mittlerer Aufwand (neue Functions/Configs)

| # | Was | Betroffene Controls | Aufwand |
|---|-----|--------------------|---------|
| 7 | Shared Mailbox Sign-in Block | CIS 1.2.2 | 1 EXO Function |
| 8 | Entra Admin Center Access Restriction | CIS 5.1.2.4 | 1 Setting |
| 9 | Dynamic Guest Group Creation | CIS 5.1.3.1 | 1 Function |
| 10 | Access Reviews (Guests + Privileged) | CIS 5.3.2, 5.3.3 | 2 Functions |
| 11 | Mailbox Audit Actions vollständig konfigurieren | CIS 6.1.2 | 1 EXO Config |
| 12 | Teams Security Reporting aktivieren | CIS 8.6.1 | 1 Setting |

### Prio 3 — Neues Modul

| # | Was | Betroffene Controls | Aufwand |
|---|-----|--------------------|---------|
| 13 | **Power BI / Fabric Modul** | CIS 9.x (12 Controls) | Neues Modul |
| 14 | Phishing-resistant Auth Strength Policy | CISA MS.AAD.3.1v1, 3.6v1 | CA Policy + Auth Strength |

### Außerhalb Scope (nicht automatisierbar)

| Typ | Controls | Warum nicht automatisierbar |
|-----|----------|---------------------------|
| DNS (SPF, DKIM CNAME, DMARC) | CISA MS.EXO.2-4 | DNS Provider, nicht M365 API |
| SIEM/Log-Forwarding | CISA MS.AAD.4.1v1 | Operational Setup |
| GA Count Audit (2-8) | CISA MS.AAD.7.1v1 | Reporting via `Get-M365EntraPIMReport` |
| Cloud-only Admin Check | CISA MS.AAD.7.3v1 | Reporting/Audit |
| MFA Registration Coverage | CIS 5.2.3.4 | Reporting/Audit |

---

## Empfohlene nächste Schritte

1. **Prio 1 Items** umsetzen — schließt ~10 Controls mit minimalem Aufwand
2. **Power BI Modul** aufbauen — schließt 12 CIS Controls komplett
3. **Phishing-resistant Auth Strength** — hebt CA002/CA003 auf CISA SHALL-Compliance
4. **Fehlende Compliance-Referenzen** in den 19 Configs ohne Block ergänzen
