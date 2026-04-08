# M365TenantSuperpowers Documentation

Welcome to the M365TenantSuperpowers documentation. This module provides a modular toolkit for Microsoft 365 tenant setup, configuration, and governance.

## Table of Contents

- [Getting Started](getting-started.md) — Installation, prerequisites, first connection
- [Core Module](core-module.md) — Authentication, logging, reporting, prerequisites
- [Conditional Access](conditional-access.md) — CA policy management, configs, drift detection
- [Entra ID](entra-id.md) — Identity settings, auth methods, password protection, cross-tenant access
- [Defender for Office 365](defender.md) — Safe Links, Safe Attachments, anti-phish/spam/malware
- [Exchange Online](exchange-online.md) — Org config, DKIM, transport rules, client access policies
- [SharePoint Online](sharepoint-online.md) — Tenant settings, sharing, access control, idle signout
- [Microsoft Teams](teams.md) — Meeting, messaging, calling, federation, guest, apps, channels
- [Profiles](profiles.md) — Pre-built configuration bundles, custom profiles
- [Configuration Reference](configuration-reference.md) — JSON config format, schema, parameters
- [Examples](examples.md) — Real-world usage scenarios and workflows
- [Coverage Overview](coverage-overview.md) — Abdeckung vs. CISA SCuBA, CIS v6, MS Standard/Strict mit Gap-Analyse
- [Compliance Mapping](compliance-mapping.md) — Detailliertes Control-zu-Config Mapping
- [M365DSC Coverage Roadmap](m365dsc-coverage-roadmap.md) — Full service-by-service implementation plan

## Architecture Overview

```
M365TenantSuperpowers
├── Core                    Auth, logging, reporting, prerequisites
├── ConditionalAccess       CA policy CRUD, import/export, drift detection
├── EntraID                 Authorization, auth methods, password, cross-tenant, groups
├── Defender                Safe Links, Safe Attachments, anti-phish/spam/malware, ATP global
├── Exchange                Org config, DKIM, transport rules, OWA, mobile, sharing
├── SharePoint              Tenant settings, sharing, access control, idle signout
├── Teams                   Meeting, messaging, calling, federation, guest, apps, channels
├── configs/                JSON policy definitions (data-driven, 45 configs)
├── profiles/               Pre-built bundles (SMB-Standard, Enterprise-Hardened)
└── tests/                  Pester tests
```

### Design Principles

1. **Modular** — Each service area is an independent sub-module
2. **Data-driven** — Policies defined as JSON, not hardcoded in scripts
3. **Idempotent** — Check-before-apply pattern, safe to re-run
4. **Safe by default** — CA policies deploy in report-only mode
5. **Composable** — Mix and match individual policies or use profiles
