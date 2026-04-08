# Getting Started

## Prerequisites

M365TenantSuperpowers requires **PowerShell 7.2+** and the following modules:

| Module | Min. Version | Required For |
|--------|-------------|--------------|
| Microsoft.Graph.Authentication | 2.0.0 | All Graph operations |
| Microsoft.Graph.Identity.SignIns | 2.0.0 | Conditional Access |
| Microsoft.Graph.Users | 2.0.0 | User operations |
| Microsoft.Graph.Groups | 2.0.0 | Group operations |
| ExchangeOnlineManagement | 3.0.0 | Exchange Online (future) |
| PnP.PowerShell | 2.0.0 | SharePoint Online (future) |
| MicrosoftTeams | 5.0.0 | Teams (future) |

### Check Prerequisites

```powershell
Import-Module ./M365TenantSuperpowers.psd1
Test-M365Prerequisites
```

This returns a table showing which modules are installed, outdated, or missing.

### Auto-Install Missing Modules

```powershell
Test-M365Prerequisites -Install
```

### Install Only What You Need

```powershell
Test-M365Prerequisites -Services Graph -Install
Test-M365Prerequisites -Services Graph, ExchangeOnline -Install
```

## Import the Module

```powershell
Import-Module ./M365TenantSuperpowers.psd1 -Force
```

## Connect to a Tenant

### Interactive Authentication (Browser)

```powershell
# Connect to Graph only (default)
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com'

# Connect to multiple services
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services Graph, ExchangeOnline
```

The module automatically aggregates the required Graph API scopes from all loaded sub-modules. You do not need to specify scopes manually.

### Check Connection Status

```powershell
Get-M365TenantConnection
```

Returns:

```
TenantId          : contoso.onmicrosoft.com
ConnectedServices : {Graph}
Account           : admin@contoso.onmicrosoft.com
Timestamp         : 2026-04-07 10:30:00
IsConnected       : True
```

### Disconnect

```powershell
# Disconnect all services
Disconnect-M365Tenant

# Disconnect specific service
Disconnect-M365Tenant -Services ExchangeOnline
```

## Quick Start: Full Tenant Baseline

```powershell
# 1. Import module and connect (Graph + Exchange Online)
Import-Module ./M365TenantSuperpowers.psd1
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services Graph, ExchangeOnline

# 2. Preview what the SMB profile would do (10 steps)
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = '00000000-0000-0000-0000-000000000000'
} -WhatIf

# 3. Apply the full baseline
#    - Entra ID: Authorization policy, auth methods, password protection, named locations
#    - Conditional Access: 6 policies in report-only mode
#    - Defender: Safe Links, Safe Attachments, anti-phish/spam/malware
#    - Exchange: Org config (audit on), DKIM, external tag, block auto-forwarding
#    - Governance: Group restrictions, 365-day expiration
Invoke-M365Profile -Name 'SMB-Standard' -Parameters @{
    excludeBreakGlassGroup = '00000000-0000-0000-0000-000000000000'
}

# 4. Review CA policies in the Entra admin center, then enable
Set-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -State enabled
Set-M365CAPolicy -PolicyName 'CA002-RequireMFAAdmins' -State enabled

# 5. Generate audit report
Get-M365EntraReport | Export-M365Report -Format HTML -Title 'Entra ID Audit'
Get-M365DefenderReport | Export-M365Report -Format HTML -Title 'Defender Audit'
Get-M365EXOReport | Export-M365Report -Format HTML -Title 'Exchange Audit'
```

## Quick Start: Individual Modules

You can also use modules individually without a profile:

```powershell
# Only Entra ID hardening
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com'
Import-M365EntraConfigSet -ConfigNames 'ENTRA-AuthorizationPolicy', 'ENTRA-PasswordProtection'

# Only Defender
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services ExchangeOnline
Import-M365DefenderConfigSet -ConfigNames 'DEF-SafeLinks', 'DEF-SafeAttachments'

# Only Exchange baseline
Import-M365EXOConfigSet -ConfigNames 'EXO-OrganizationConfig', 'EXO-Dkim', 'EXO-RemoteDomain'
```
