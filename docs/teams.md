# Microsoft Teams Module

Manages Microsoft Teams policies and configuration. Covers meeting, messaging, calling, app permissions, external access/federation, guest access, channels, and client settings.

**Requires:** Teams connection (`Connect-M365Tenant -Services Teams`)

## Functions

### Set-M365TeamsMeetingPolicy

Configures the Teams meeting policy (Global or named).

```powershell
Set-M365TeamsMeetingPolicy -ConfigName 'TEAMS-MeetingPolicy'
```

**Default config (Global policy):**

| Setting | Value | Impact |
|---------|-------|--------|
| Cloud recording | Allowed | Users can record meetings |
| Transcription | Allowed | Live transcription available |
| IP video | Allowed | Video in meetings |
| Anonymous join | Allowed | External users can join via link |
| Auto-admitted | `EveryoneInCompanyExcludingGuests` | Guests wait in lobby |
| External give control | `false` | External users cannot take control |
| Screen sharing | Entire screen | Full screen sharing allowed |
| Meeting reactions | Allowed | Emoji reactions in meetings |

---

### Set-M365TeamsMessagingPolicy

Configures the Teams messaging policy.

```powershell
Set-M365TeamsMessagingPolicy -ConfigName 'TEAMS-MessagingPolicy'
```

**Default config:** Edit/delete messages allowed, Giphy at Moderate rating, memes and stickers allowed, read receipts as user preference, URL previews enabled, inline translation enabled.

---

### Set-M365TeamsCallingPolicy

Configures the Teams calling policy.

```powershell
Set-M365TeamsCallingPolicy -ConfigName 'TEAMS-CallingPolicy'
```

**Default config:** Private calling, voicemail, call forwarding (to user and phone), call groups, delegation all allowed. Busy-on-busy enabled.

---

### Set-M365TeamsAppPermissions

Configures which Teams apps are allowed or blocked.

```powershell
Set-M365TeamsAppPermissions -ConfigName 'TEAMS-AppPermissions'
```

**Default config:** Microsoft apps and third-party apps allowed. Custom (LOB) apps blocked by default — enable per org as needed.

---

### Set-M365TeamsFederation

Configures external access (federation) — who your users can communicate with.

```powershell
Set-M365TeamsFederation -ConfigName 'TEAMS-Federation'
```

**Default config:**

| Setting | Value | Why |
|---------|-------|-----|
| Federated users (other Teams orgs) | **Allowed** | Business communication |
| Teams consumer (personal accounts) | **Blocked** | Security risk — unmanaged accounts |
| Teams consumer inbound | **Blocked** | Prevents unsolicited contact |
| Skype consumer (public users) | **Blocked** | Legacy, security risk |

**Customize:** Use `allowedDomains` / `blockedDomains` parameters to restrict federation to specific partner organizations.

---

### Set-M365TeamsGuestConfig

Configures all three guest access settings in one function: calling, meeting, and messaging.

```powershell
Set-M365TeamsGuestConfig -ConfigName 'TEAMS-GuestConfig'
```

**Default config:**
- **Guest calling:** Private calling allowed
- **Guest meeting:** IP video allowed, full screen sharing
- **Guest messaging:** Edit/delete allowed, chat allowed, Giphy at Moderate, memes and stickers allowed

---

### Set-M365TeamsChannelsPolicy

Configures private and shared channel creation policies.

```powershell
Set-M365TeamsChannelsPolicy -ConfigName 'TEAMS-ChannelsPolicy'
```

**Default config:**
- Private channel creation: Allowed
- Shared channel creation: Allowed
- External shared channel participation: **Blocked**
- Channel sharing to external users: **Blocked**

This allows internal collaboration via private/shared channels but prevents data leakage through external shared channels.

---

### Set-M365TeamsClientConfig

Configures Teams client-wide settings, particularly third-party cloud storage.

```powershell
Set-M365TeamsClientConfig -ConfigName 'TEAMS-ClientConfig'
```

**Default config:**

| Setting | Value | Why |
|---------|-------|-----|
| DropBox | **Blocked** | Use OneDrive/SharePoint instead |
| Google Drive | **Blocked** | Use OneDrive/SharePoint instead |
| Box | **Blocked** | Use OneDrive/SharePoint instead |
| Egnyte | **Blocked** | Use OneDrive/SharePoint instead |
| ShareFile | **Blocked** | Use OneDrive/SharePoint instead |
| Email into channel | Allowed | Useful for workflows |
| Org tab | Allowed | Organization tab in Teams |

Blocking third-party storage ensures all files stay within the M365 ecosystem where DLP, retention, and sensitivity labels apply.

---

### Get-M365TeamsReport

Generates a comprehensive report of current Teams configuration.

```powershell
Get-M365TeamsReport | Export-M365Report -Format HTML -Title 'Teams Config Audit'
```

Reports on: Meeting policy (Global), Messaging policy (Global), Federation, Guest access (calling, meeting, messaging), Client configuration.

---

### Import-M365TeamsConfigSet

Bulk-applies Teams configs.

```powershell
# Deploy full Teams baseline
Import-M365TeamsConfigSet -ConfigNames @(
    'TEAMS-MeetingPolicy', 'TEAMS-MessagingPolicy', 'TEAMS-CallingPolicy',
    'TEAMS-AppPermissions', 'TEAMS-Federation', 'TEAMS-GuestConfig',
    'TEAMS-ChannelsPolicy', 'TEAMS-ClientConfig'
)
```

## Built-in Configs

| Config | Severity | What it configures |
|--------|----------|--------------------|
| TEAMS-MeetingPolicy | Critical | Recording, transcription, lobby, screen sharing |
| TEAMS-MessagingPolicy | Critical | Edit/delete, Giphy, read receipts, translation |
| TEAMS-CallingPolicy | Critical | Private calling, voicemail, forwarding, delegation |
| TEAMS-AppPermissions | Critical | Microsoft/third-party allowed, custom blocked |
| TEAMS-Federation | Critical | Allow federated, block consumer/Skype |
| TEAMS-GuestConfig | Critical | Guest calling, meeting, messaging capabilities |
| TEAMS-ChannelsPolicy | High | Private/shared channels allowed, external sharing blocked |
| TEAMS-ClientConfig | High | Third-party cloud storage blocked |

## Security Impact Summary

The Teams baseline addresses:

1. **Data leakage** — Third-party storage blocked, external shared channels blocked
2. **Unmanaged access** — Consumer/Skype federation blocked
3. **Meeting security** — Lobby for external users, no external control sharing
4. **Guest governance** — Controlled guest capabilities with sensible defaults
5. **App control** — Custom apps blocked by default, reviewed before enabling
