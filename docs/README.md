# M365TenantSuperpowers Documentation

Modular PowerShell toolkit for Microsoft 365 tenant setup, configuration, and governance. 10 modules, 94 functions, 70 configs, aligned with CISA SCuBA, CIS v6, and Microsoft Standard/Strict baselines.

## Table of Contents

### Module Documentation
- [Getting Started](getting-started.md) — Installation, prerequisites, first connection
- [Core Module](core-module.md) — Authentication, logging, reporting, compliance audit
- [Conditional Access](conditional-access.md) — 15 CA policies, import/export, drift detection
- [Entra ID](entra-id.md) — Authorization, auth methods, PIM, password, cross-tenant, groups, access reviews
- [Defender for Office 365](defender.md) — Safe Links/Attachments, anti-phish/spam/malware, connection filter
- [Exchange Online](exchange-online.md) — Org config, DKIM, transport rules, shared mailbox, audit actions
- [SharePoint Online](sharepoint-online.md) — Tenant settings, sharing restrictions, access control
- [Microsoft Teams](teams.md) — Meeting, messaging, calling, federation, guest, apps, channels
- [Security & Compliance](security-purview.md) — DLP, sensitivity labels, retention, audit, alerts
- [Intune](intune.md) — Device compliance, enrollment, app protection (MAM)
- [Power BI / Fabric](powerbi.md) — Tenant settings (all 11 CIS 9.x controls)

### Configuration & Compliance
- [Profiles](profiles.md) — Pre-built bundles (SMB-Standard, Enterprise-Hardened)
- [Configuration Reference](configuration-reference.md) — JSON config format, schema, parameters
- [Coverage Overview](coverage-overview.md) — Gap analysis vs. CISA SCuBA, CIS v6, MS Standard/Strict
- [Compliance Mapping](compliance-mapping.md) — Control-to-config mapping per baseline
- [Examples](examples.md) — Real-world usage scenarios and workflows
- [M365DSC Coverage Roadmap](m365dsc-coverage-roadmap.md) — Service-by-service comparison with M365DSC

## Architecture Overview

```
M365TenantSuperpowers/
├── Core                    Auth, logging, reporting, compliance audit
├── ConditionalAccess       15 CA policies, CRUD, import/export, drift detection
├── EntraID                 Authorization, auth methods, PIM, password, cross-tenant, groups, access reviews
├── Defender                Safe Links/Attachments, anti-phish/spam/malware, outbound spam, connection filter
├── Exchange                Org config, DKIM, transport rules, OWA, mobile, sharing, shared MB, audit
├── SharePoint              Tenant settings, sharing, access control, idle signout
├── Teams                   Meeting, messaging, calling, federation, guest, apps, channels
├── Security                DLP, sensitivity labels, retention, audit retention, alerts
├── Intune                  Device compliance (Win/iOS/Android), enrollment, app protection (MAM)
├── PowerBI                 Tenant settings (11 CIS controls)
├── configs/                70 JSON config files with compliance references
├── profiles/               SMB-Standard (17 steps), Enterprise-Hardened (23 steps)
└── tests/                  Pester tests
```

## Key Numbers

| Metric | Value |
|--------|-------|
| Modules | 10 |
| Exported Functions | 94 |
| JSON Configs | 70 (all with compliance references) |
| CA Policies | 15 |
| CISA SCuBA Controls | ~65 of 76 covered or auditable (86%) |
| CIS v6 Controls | ~100 of 140 covered or auditable (71%) |
| MS Standard/Strict | ~98% aligned |
| Profiles | SMB-Standard (17 steps), Enterprise-Hardened (23 steps) |

### Design Principles

1. **Modular** — Each service area is an independent sub-module
2. **Data-driven** — Policies defined as JSON, not hardcoded in scripts
3. **Compliance-referenced** — Every config maps to CISA SCuBA, CIS v6, and/or MS baselines
4. **Idempotent** — Check-before-apply pattern, safe to re-run
5. **Safe by default** — CA policies deploy in report-only mode
6. **Composable** — Mix and match individual policies or use profiles
7. **Auditable** — `Invoke-M365ComplianceAudit` checks operational items with pass/fail
