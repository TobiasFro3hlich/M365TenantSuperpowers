# Configuration Reference

All policies in M365TenantSuperpowers are defined as JSON files. This page documents the JSON config format, the parameter system, and schema validation.

## Config File Structure

Every config file has three sections:

```json
{
    "metadata": { },    // Human-readable info (not sent to API)
    "policy": { },      // Maps directly to Graph API body
    "parameters": { }   // Runtime variables resolved at deploy time
}
```

### metadata

Information for documentation, filtering, and auditing. Never sent to the API.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier (e.g., `CA001`) |
| `name` | string | Yes | Human-readable name |
| `description` | string | Yes | What the policy does and why |
| `severity` | string | Yes | `Critical`, `High`, `Medium`, or `Low` |
| `category` | string | Yes | `Identity`, `Device`, `Location`, `Application`, or `Session` |
| `tags` | string[] | No | Searchable tags |
| `microsoftReference` | string | No | URL to Microsoft Learn documentation |

### policy

Maps directly to the Microsoft Graph API `conditionalAccessPolicy` resource. The structure mirrors the [Graph API schema](https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy).

```json
{
    "policy": {
        "displayName": "CA001 - Block Legacy Authentication",
        "state": "enabledForReportingButNotEnforced",
        "conditions": {
            "clientAppTypes": ["exchangeActiveSync", "other"],
            "applications": {
                "includeApplications": ["All"],
                "excludeApplications": []
            },
            "users": {
                "includeUsers": ["All"],
                "excludeUsers": [],
                "includeGroups": [],
                "excludeGroups": [],
                "includeRoles": [],
                "excludeRoles": []
            },
            "platforms": {
                "includePlatforms": ["all"],
                "excludePlatforms": []
            },
            "locations": {
                "includeLocations": ["All"],
                "excludeLocations": ["AllTrusted"]
            },
            "signInRiskLevels": ["high", "medium"],
            "userRiskLevels": ["high"]
        },
        "grantControls": {
            "operator": "OR",
            "builtInControls": ["mfa", "block", "compliantDevice", "approvedApplication"],
            "termsOfUse": ["<termsOfUseId>"]
        },
        "sessionControls": {
            "signInFrequency": {
                "isEnabled": true,
                "type": "hours",
                "value": 24
            },
            "persistentBrowser": {
                "isEnabled": true,
                "mode": "never"
            }
        }
    }
}
```

#### Policy State Values

| Value | Description |
|-------|-------------|
| `enabledForReportingButNotEnforced` | **Default.** Report-only mode. Logs what would happen without blocking. |
| `enabled` | Fully enforced. Blocks or requires controls. |
| `disabled` | Policy exists but is not active. |

#### Common Grant Controls

| Control | Description |
|---------|-------------|
| `block` | Block access entirely |
| `mfa` | Require multi-factor authentication |
| `compliantDevice` | Require Intune-compliant device |
| `domainJoinedDevice` | Require Hybrid Azure AD joined device |
| `approvedApplication` | Require approved client app |
| `compliantApplication` | Require app protection policy |

#### Common User Targets

| Value | Description |
|-------|-------------|
| `All` | All users in the directory |
| `GuestsOrExternalUsers` | All guest and external users |
| `<objectId>` | Specific user or group by Object ID |

#### Admin Role GUIDs

The built-in configs reference these commonly protected admin roles:

| GUID | Role |
|------|------|
| `62e90394-69f5-4237-9190-012177145e10` | Global Administrator |
| `194ae4cb-b126-40b2-bd5b-6091b380977d` | Security Administrator |
| `f28a1f50-f6e7-4571-818b-6a12f2af6b6c` | SharePoint Administrator |
| `29232cdf-9323-42fd-ade2-1d097af3e4de` | Exchange Administrator |
| `b1be1c3e-b65d-4f19-8427-f6fa0d97feb9` | Conditional Access Administrator |
| `729827e3-9c14-49f7-bb1b-9608f156bbb8` | Helpdesk Administrator |
| `b0f54661-2d74-4c50-afa3-1ec803f12efe` | Billing Administrator |
| `fe930be7-5e62-47db-91af-98c3a49a38b1` | User Administrator |
| `c4e39bd9-1100-46d3-8c65-fb160da0071f` | Authentication Administrator |
| `9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3` | Application Administrator |
| `158c047a-c907-4556-b7ef-446551a6b5f7` | Cloud Application Administrator |
| `966707d0-3269-4727-9be2-8c3a10f19b9d` | Password Administrator |
| `7be44c8a-adaf-4e2a-84d6-ab2649e08a13` | Privileged Authentication Administrator |
| `e8611ab8-c189-46e8-94e1-60213ab1f814` | Privileged Role Administrator |

### parameters

Runtime variables that differ per tenant. Resolved at deploy time.

```json
{
    "parameters": {
        "excludeBreakGlassGroup": {
            "description": "Object ID of the break-glass/emergency access group",
            "required": true,
            "type": "groupObjectId"
        },
        "termsOfUseId": {
            "description": "Object ID of the Terms of Use document",
            "required": true,
            "type": "string"
        }
    }
}
```

#### Parameter Types

| Type | Behavior |
|------|----------|
| `groupObjectId` | Automatically added to `conditions.users.excludeGroups` |
| `stringArray` | Replaces the value at `targetProperty` in the policy |
| `string` | Available in the parameters hashtable for custom resolution |
| `boolean` | Available in the parameters hashtable for custom resolution |

#### Providing Parameters

Parameters are passed as a hashtable at runtime:

```powershell
New-M365CAPolicy -PolicyName 'CA001-BlockLegacyAuth' -Parameters @{
    excludeBreakGlassGroup = '00000000-0000-0000-0000-000000000000'
}
```

If a required parameter is not provided, the function throws an error with a description of what is needed.

## Schema Validation

Config files can be validated against the JSON schema at `configs/ConditionalAccess/_schema.json`. The Pester tests automatically validate all built-in configs against this schema.

## Creating Custom Configs

1. Copy an existing config as a starting point
2. Update the `metadata` section
3. Modify the `policy` section to match your requirements
4. Add any tenant-specific `parameters`
5. Save to `configs/ConditionalAccess/` with a descriptive name
6. Test with `New-M365CAPolicy -PolicyName 'YourConfig' -WhatIf`

```powershell
# Example: Create a custom policy
Copy-Item ./configs/ConditionalAccess/CA003-RequireMFAAllUsers.json `
          ./configs/ConditionalAccess/CUSTOM001-RequireMFAFinance.json

# Edit the file, then test
New-M365CAPolicy -PolicyName 'CUSTOM001-RequireMFAFinance' -Parameters @{
    excludeBreakGlassGroup = '...'
} -WhatIf
```
