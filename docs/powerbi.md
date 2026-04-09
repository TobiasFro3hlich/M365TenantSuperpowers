# Power BI / Microsoft Fabric Module

Manages Power BI and Microsoft Fabric tenant-level settings. Covers all 11 CIS v6 Section 9 controls for guest access, external sharing, publish to web, R/Python visuals, sensitivity labels, and service principal restrictions.

**Requires:** Graph connection with Power BI Admin role

## Functions

### Set-M365PowerBITenantSettings

Configures all Power BI tenant settings from a JSON config.

```powershell
Set-M365PowerBITenantSettings -ConfigName 'PBI-TenantSettings'
```

**Default config covers all CIS 9.x controls:**

| CIS Control | Setting | Value | Why |
|-------------|---------|-------|-----|
| 9.1.1 | Guest user access | **Disabled** | Prevent unauthorized external access |
| 9.1.2 | External user invitations | **Disabled** | Control who can invite externals |
| 9.1.3 | Guest access to content | **Disabled** | Block external content browsing |
| 9.1.4 | Publish to web | **Disabled** | Prevent public data exposure |
| 9.1.5 | R and Python visuals | **Disabled** | Prevent code execution risks |
| 9.1.6 | Sensitivity labels | **Enabled** | Classification for BI content |
| 9.1.7 | Shareable links | **Disabled** | Prevent uncontrolled sharing |
| 9.1.8 | External data sharing | **Disabled** | Keep data within org boundary |
| 9.1.9 | ResourceKey Authentication | **Blocked** | Close legacy auth vector |
| 9.1.10 | Service Principal API access | **Disabled** | Restrict to security group |
| 9.1.11 | Service Principal profiles | **Disabled** | Prevent profile abuse |

**Note:** Some Power BI settings may require the Power BI Admin Portal if the Graph API endpoint is not available. The function falls back gracefully and reports which settings need manual configuration.

---

### Get-M365PowerBIReport

Generates a report of current Power BI tenant settings.

```powershell
Get-M365PowerBIReport | Export-M365Report -Format HTML -Title 'Power BI Audit'
```

**Note:** Requires Power BI Admin role. If access is denied, reports the error clearly.

---

### Import-M365PowerBIConfigSet

Bulk-applies Power BI configs.

```powershell
Import-M365PowerBIConfigSet -ConfigNames 'PBI-TenantSettings'
```

## Built-in Configs

| Config | Severity | What it configures |
|--------|----------|--------------------|
| PBI-TenantSettings | High | All 11 CIS 9.x controls in one config |
