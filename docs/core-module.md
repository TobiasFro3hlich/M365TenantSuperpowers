# Core Module

The Core module provides shared infrastructure used by all other sub-modules: authentication, logging, reporting, and prerequisite checks.

## Functions

### Connect-M365Tenant

Connects to one or more Microsoft 365 services. This is the single entry point for all authentication.

```powershell
Connect-M365Tenant
    -TenantId <string>          # Required. Tenant GUID or domain (e.g. contoso.onmicrosoft.com)
    -Services <string[]>        # Optional. Default: 'Graph'. Values: Graph, ExchangeOnline, SharePoint, Teams
    -GraphScopes <string[]>     # Optional. Additional Graph scopes beyond auto-detected ones
    -SharePointAdminUrl <string> # Required when -Services includes SharePoint
```

**How scope aggregation works:**

Each sub-module declares its required Graph API scopes in its manifest. At connect time, the module reads all sub-module manifests and unions the scopes. This means you always get exactly the permissions you need — no more, no less.

**Examples:**

```powershell
# Basic — Graph only
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com'

# Multiple services
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' -Services Graph, ExchangeOnline

# With SharePoint (requires admin URL)
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' `
    -Services Graph, SharePoint `
    -SharePointAdminUrl 'https://contoso-admin.sharepoint.com'

# Add extra Graph scopes
Connect-M365Tenant -TenantId 'contoso.onmicrosoft.com' `
    -GraphScopes 'Mail.Read', 'Calendars.Read'
```

---

### Disconnect-M365Tenant

Cleanly disconnects from all or specific services.

```powershell
Disconnect-M365Tenant
    -Services <string[]>    # Optional. If omitted, disconnects all connected services
```

**Examples:**

```powershell
# Disconnect everything
Disconnect-M365Tenant

# Disconnect only Exchange
Disconnect-M365Tenant -Services ExchangeOnline
```

---

### Get-M365TenantConnection

Returns the current connection state as a `PSCustomObject`.

```powershell
Get-M365TenantConnection
```

**Output properties:**

| Property | Type | Description |
|----------|------|-------------|
| TenantId | string | Connected tenant ID |
| ConnectedServices | string[] | List of connected services |
| Account | string | Authenticated user account |
| Timestamp | DateTime | When the connection was established |
| IsConnected | bool | Whether any service is connected |

---

### Test-M365Prerequisites

Checks that required PowerShell modules are installed and meet version requirements.

```powershell
Test-M365Prerequisites
    -Services <string[]>    # Optional. Default: 'All'. Filter to specific services
    -Install                # Optional. Auto-install missing or outdated modules
```

**Output:** Array of objects with Service, Module, RequiredVersion, InstalledVersion, Status (OK/Missing/Outdated).

**Examples:**

```powershell
# Check all
Test-M365Prerequisites

# Check only Graph modules
Test-M365Prerequisites -Services Graph

# Auto-install missing
Test-M365Prerequisites -Services Graph, ExchangeOnline -Install
```

---

### Export-M365Report

Standardized export for any data. Accepts pipeline input and outputs to Console, CSV, HTML, or JSON.

```powershell
Export-M365Report
    -InputData <object[]>   # Required. Accepts pipeline input
    -Format <string[]>      # Optional. Default: 'Console'. Values: Console, CSV, HTML, JSON
    -OutputPath <string>    # Optional. Default: './output'. Directory for file output
    -Title <string>         # Optional. Default: 'M365 Report'. Used in HTML title and filename
    -PassThru               # Optional. Also return data as pipeline output
```

**HTML reports** use a built-in template with Microsoft-themed styling (Segoe UI, blue headers, hover effects).

**Examples:**

```powershell
# Display in console
Get-M365CAPolicy | Export-M365Report

# Export to CSV and HTML simultaneously
Get-M365CAPolicy | Export-M365Report -Format CSV, HTML -Title 'CA Policy Audit'

# Export and continue pipeline
$data = Get-M365CAPolicy | Export-M365Report -Format JSON -PassThru
```

---

### Write-M365Log

Structured logging with severity levels and color-coded console output.

```powershell
Write-M365Log
    -Message <string>       # Required. The log message
    -Level <string>         # Optional. Default: 'Info'. Values: Debug, Info, Warning, Error
    -LogFile <string>       # Optional. File path to append log messages to
```

**Console colors:**

| Level | Color |
|-------|-------|
| Debug | Verbose (hidden unless -Verbose) |
| Info | Cyan |
| Warning | Yellow |
| Error | Red |

**Examples:**

```powershell
Write-M365Log -Message "Starting deployment" -Level Info
Write-M365Log -Message "Policy mismatch detected" -Level Warning
Write-M365Log -Message "Full run log" -Level Info -LogFile './logs/deployment.log'
```

All module functions use `Write-M365Log` internally, so you always get consistent, timestamped output.

---

### Invoke-M365ComplianceAudit

Runs a comprehensive compliance audit against CISA SCuBA, CIS v6, and Microsoft baselines. Checks all operational items that cannot be deployed via config-as-code but CAN be audited programmatically.

```powershell
Invoke-M365ComplianceAudit
    -Services <string[]>    # Optional. Default: All connected. Values: EntraID, Exchange, Defender, SharePoint, Teams
    -Domains <string[]>     # Optional. Domains for DNS checks. Default: auto-detect from accepted domains
    -OutputFormat <string[]> # Optional. Default: Console. Values: Console, HTML, CSV, JSON
    -OutputPath <string>    # Optional. Default: ./output/audit
```

**Checks performed (15 total):**

| Section | Check | Baseline |
|---------|-------|----------|
| Entra ID | Global Admin count 2-8 | CISA MS.AAD.7.1v1, CIS 1.1.3 |
| Entra ID | Cloud-only privileged accounts | CISA MS.AAD.7.3v1, CIS 1.1.1 |
| Entra ID | Auth methods migration complete | CISA MS.AAD.3.4v1 |
| Entra ID | Audit logs accessible (SIEM) | CISA MS.AAD.4.1v1 |
| Entra ID | MFA registration coverage % | CIS 5.2.3.4 |
| Entra ID | No permanent PIM assignments | CISA MS.AAD.7.4v1, CIS 5.3.1 |
| Exchange | Shared mailbox sign-in blocked | CIS 1.2.2 |
| Exchange | No audit bypass mailboxes | CIS 6.1.3 |
| Exchange | No transport rule whitelisting | CIS 6.2.2 |
| DNS | SPF record with -all | CISA MS.EXO.2.2v3, CIS 2.1.8 |
| DNS | DMARC record with p=reject | CISA MS.EXO.4.1-4.2, CIS 2.1.10 |
| DNS | DKIM CNAME records | CISA MS.EXO.3.1v1, CIS 2.1.9 |
| Defender | Standard preset assigned | CISA MS.DEFENDER.1.2v1 |
| Defender | Strict preset for sensitive accounts | CISA MS.DEFENDER.1.4v1 |
| Defender | No allowed sender domains | CIS 2.1.14 |

**Output:** Color-coded PASS/FAIL/WARN with remediation guidance for each failed check.

**Examples:**

```powershell
# Full audit to console
Invoke-M365ComplianceAudit

# HTML report for customer handover
Invoke-M365ComplianceAudit -OutputFormat HTML -OutputPath './reports/customer'

# Only Entra ID + Exchange checks
Invoke-M365ComplianceAudit -Services EntraID, Exchange

# Specific domains for DNS
Invoke-M365ComplianceAudit -Domains 'contoso.com' -OutputFormat HTML, CSV
```
