# M365DSC Coverage Roadmap

This document maps all relevant Microsoft365DSC resources to our M365TenantSuperpowers module structure. It serves as the master plan for which settings to implement, prioritized by baseline criticality.

**Total M365DSC resources analyzed: 300+**
**Resources relevant for tenant baseline: ~120**

---

## Service Overview

| Service Area | M365DSC Resources | Critical/High for Baseline | Our Module |
|---|---|---|---|
| Exchange Online | 99 | ~30 | `src/Exchange/` |
| Entra ID (Identity) | ~30 | ~20 | `src/EntraID/` |
| SharePoint Online | 22 | ~7 | `src/SharePoint/` |
| Microsoft Teams | 44 | ~15 | `src/Teams/` |
| Intune / Endpoint | ~35 | ~20 | `src/Intune/` |
| Security & Compliance | ~30 | ~15 | `src/Security/` |
| Defender for O365 | (under EXO) | ~15 | `src/Defender/` |
| Conditional Access | (under Entra) | 10 (done) | `src/ConditionalAccess/` ✅ |

---

## 1. EXCHANGE ONLINE (`src/Exchange/`)

### Tier 1 — Critical (deploy first at every customer)

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Organization Config** | EXOOrganizationConfig | `Set-M365EXOOrganizationConfig` | `EXO-OrganizationConfig.json` |
| **Anti-Phishing Policy** | EXOAntiPhishPolicy + Rule | `Set-M365EXOAntiPhish` | `EXO-AntiPhishDefault.json` |
| **Anti-Spam Inbound** | EXOHostedContentFilterPolicy + Rule | `Set-M365EXOAntiSpam` | `EXO-AntiSpamInbound.json` |
| **Anti-Spam Outbound** | EXOHostedOutboundSpamFilterPolicy + Rule | `Set-M365EXOAntiSpamOutbound` | `EXO-AntiSpamOutbound.json` |
| **Anti-Malware** | EXOMalwareFilterPolicy + Rule | `Set-M365EXOAntiMalware` | `EXO-AntiMalware.json` |
| **Authentication Policy** | EXOAuthenticationPolicy | `Set-M365EXOAuthPolicy` | `EXO-AuthPolicy.json` |
| **DKIM Signing** | EXODkimSigningConfig | `Set-M365EXODkim` | `EXO-Dkim.json` |
| **Transport Rules** | EXOTransportRule | `Set-M365EXOTransportRules` | `EXO-TransportRules.json` |
| **Accepted Domains** | EXOAcceptedDomain | `Get-M365EXODomainReport` | (read-only) |

**Key settings in EXOOrganizationConfig:**
- `AuditDisabled = $false` (ensure audit logging is on)
- `OAuth2ClientProfileEnabled = $true`
- `DefaultPublicFolderProhibitPostQuota`, `DefaultPublicFolderIssueWarningQuota`
- `MailTipsAllTipsEnabled = $true`
- `MailTipsExternalRecipientsTipsEnabled = $true`
- `MailTipsGroupMetricsEnabled = $true`
- `MailTipsLargeAudienceThreshold = 25`
- `SendFromAliasEnabled = $true`
- `BlockMoveMessagesForGroupFolders = $false`

### Tier 2 — High (standard baseline)

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Defender ATP Global** | EXOAtpPolicyForO365 | `Set-M365DefenderGlobal` | `DEF-AtpGlobal.json` |
| **Safe Attachments** | EXOSafeAttachmentPolicy + Rule | `Set-M365DefenderSafeAttachments` | `DEF-SafeAttachments.json` |
| **Safe Links** | EXOSafeLinksPolicy + Rule | `Set-M365DefenderSafeLinks` | `DEF-SafeLinks.json` |
| **Preset Security (Standard)** | EXOAtpProtectionPolicyRule | `Set-M365DefenderPreset` | `DEF-PresetStandard.json` |
| **Built-in Protection** | EXOATPBuiltInProtectionRule | (auto via Preset) | — |
| **Connection Filter** | EXOHostedConnectionFilterPolicy | `Set-M365EXOConnectionFilter` | `EXO-ConnectionFilter.json` |
| **Transport Config** | EXOTransportConfig | `Set-M365EXOTransportConfig` | `EXO-TransportConfig.json` |
| **Remote Domain** | EXORemoteDomain | `Set-M365EXORemoteDomain` | `EXO-RemoteDomain.json` |
| **OWA Policy** | EXOOwaMailboxPolicy | `Set-M365EXOOwaPolicy` | `EXO-OwaPolicy.json` |
| **Mobile Device Policy** | EXOMobileDeviceMailboxPolicy | `Set-M365EXOMobilePolicy` | `EXO-MobilePolicy.json` |
| **ActiveSync Policy** | EXOActiveSyncMailboxPolicy | `Set-M365EXOActiveSyncPolicy` | `EXO-ActiveSyncPolicy.json` |
| **Sharing Policy** | EXOSharingPolicy | `Set-M365EXOSharingPolicy` | `EXO-SharingPolicy.json` |
| **Retention Policy** | EXORetentionPolicy + Tags | `Set-M365EXORetention` | `EXO-RetentionPolicy.json` |
| **IRM Configuration** | EXOIRMConfiguration | `Set-M365EXOIrmConfig` | `EXO-IrmConfig.json` |
| **External Sender Tag** | EXOExternalInOutlook | `Set-M365EXOExternalTag` | `EXO-ExternalTag.json` |
| **Report Submission** | EXOReportSubmissionPolicy + Rule | `Set-M365EXOReportSubmission` | `EXO-ReportSubmission.json` |
| **Quarantine Policy** | EXOQuarantinePolicy | `Set-M365EXOQuarantinePolicy` | `EXO-QuarantinePolicy.json` |
| **Mailbox Plan** | EXOMailboxPlan | `Set-M365EXOMailboxPlan` | `EXO-MailboxPlan.json` |
| **CAS Mailbox Plan** | EXOCASMailboxPlan | `Set-M365EXOCASMailboxPlan` | `EXO-CASMailboxPlan.json` |
| **App Access Policy** | EXOApplicationAccessPolicy | `Set-M365EXOAppAccessPolicy` | `EXO-AppAccessPolicy.json` |
| **ARC Config** | EXOArcConfig | `Set-M365EXOArcConfig` | `EXO-ArcConfig.json` |
| **Tenant Allow/Block** | EXOTenantAllowBlockListItems | `Set-M365EXOAllowBlockList` | `EXO-AllowBlockList.json` |

### Tier 3 — Medium (as-needed)

| Config Area | M365DSC Resource |
|---|---|
| Email Address Policy | EXOEmailAddressPolicy |
| OME Configuration (branding) | EXOOMEConfiguration |
| Address Book Policies | EXOAddressBookPolicy |
| Inbound/Outbound Connectors | EXOInboundConnector, EXOOutboundConnector |
| Journal Rules | EXOJournalRule |
| Role Assignment Policy | EXORoleAssignmentPolicy |
| Data Classification | EXODataClassification |
| PhishSim Override | EXOPhishSimOverrideRule |
| SecOps Override | EXOSecOpsOverrideRule |

---

## 2. ENTRA ID / IDENTITY (`src/EntraID/`)

### Tier 1 — Critical

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Authorization Policy** | AADAuthorizationPolicy | `Set-M365EntraAuthorizationPolicy` | `ENTRA-AuthorizationPolicy.json` |
| **Auth Method Policy** | AADAuthenticationMethodPolicy | `Set-M365EntraAuthMethodPolicy` | `ENTRA-AuthMethodPolicy.json` |
| **Authenticator Settings** | AADAuthenticationMethodPolicyAuthenticator | `Set-M365EntraAuthenticator` | `ENTRA-Authenticator.json` |
| **FIDO2 Settings** | AADAuthenticationMethodPolicyFido2 | `Set-M365EntraFido2` | `ENTRA-Fido2.json` |
| **Security Defaults** | AADSecurityDefaults | `Set-M365EntraSecurityDefaults` | `ENTRA-SecurityDefaults.json` |
| **Named Locations** | AADNamedLocationPolicy | `Set-M365EntraNamedLocations` | `ENTRA-NamedLocations.json` |
| **Admin Consent Policy** | AADAdminConsentRequestPolicy | `Set-M365EntraAdminConsent` | `ENTRA-AdminConsent.json` |
| **Cross-Tenant Access** | AADCrossTenantAccessPolicyConfigurationDefault | `Set-M365EntraCrossTenantDefault` | `ENTRA-CrossTenantDefault.json` |
| **Password Protection** | AADPasswordRuleSettings | `Set-M365EntraPasswordProtection` | `ENTRA-PasswordProtection.json` |
| **Identity Protection** | AADIdentityProtectionPolicySettings | `Set-M365EntraIdentityProtection` | `ENTRA-IdentityProtection.json` |
| **Auth Strength Policy** | AADAuthenticationStrengthPolicy | `Set-M365EntraAuthStrength` | `ENTRA-AuthStrength.json` |

**Key settings in AADAuthorizationPolicy:**
- `AllowedToSignUpEmailBasedSubscriptions = $false`
- `AllowedToUseSSPR = $true`
- `AllowEmailVerifiedUsersToJoinOrganization = $false`
- `BlockMsolPowerShell = $true`
- `DefaultUserRolePermissions.AllowedToCreateApps = $false`
- `DefaultUserRolePermissions.AllowedToCreateSecurityGroups = $true`
- `DefaultUserRolePermissions.AllowedToReadOtherUsers = $true`
- `GuestUserRoleId` (restrict guest permissions)
- `AllowInvitesFrom = 'adminsAndGuestInviters'`

### Tier 2 — High

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Group Settings** | AADGroupsSettings | `Set-M365EntraGroupSettings` | `ENTRA-GroupSettings.json` |
| **Group Lifecycle** | AADGroupLifecyclePolicy | `Set-M365EntraGroupLifecycle` | `ENTRA-GroupLifecycle.json` |
| **Device Registration** | AADDeviceRegistrationPolicy | `Set-M365EntraDeviceRegistration` | `ENTRA-DeviceRegistration.json` |
| **Permission Grant Policy** | AADPermissionGrantPolicy | `Set-M365EntraPermissionGrant` | `ENTRA-PermissionGrant.json` |
| **App Management Policy** | AADTenantAppManagementPolicy | `Set-M365EntraAppManagement` | `ENTRA-AppManagement.json` |
| **Cross-Tenant Partners** | AADCrossTenantAccessPolicyConfigurationPartner | `Set-M365EntraCrossTenantPartner` | per-partner JSON |
| **SMS Auth Method** | AADAuthenticationMethodPolicySms | `Set-M365EntraSmsAuth` | `ENTRA-SmsAuth.json` |
| **Email Auth Method** | AADAuthenticationMethodPolicyEmail | `Set-M365EntraEmailAuth` | `ENTRA-EmailAuth.json` |
| **Temp Access Pass** | AADAuthenticationMethodPolicyTemporary | `Set-M365EntraTempAccessPass` | `ENTRA-TempAccessPass.json` |
| **Auth Context** | AADAuthenticationContextClassReference | `Set-M365EntraAuthContext` | `ENTRA-AuthContext.json` |

### Tier 3 — Medium

| Config Area | M365DSC Resource |
|---|---|
| Group Naming Policy | AADGroupsNamingPolicy |
| External Identity Policy | AADExternalIdentityPolicy |
| Feature Rollout | AADFeatureRolloutPolicy |
| Certificate Auth | AADAuthenticationMethodPolicyX509 |

---

## 3. SHAREPOINT ONLINE (`src/SharePoint/`)

### Tier 1 — Critical

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Tenant Settings** | SPOTenantSettings | `Set-M365SPOTenantSettings` | `SPO-TenantSettings.json` |
| **Sharing Settings** | SPOSharingSettings | `Set-M365SPOSharing` | `SPO-SharingSettings.json` |
| **Access Control** | SPOAccessControlSettings | `Set-M365SPOAccessControl` | `SPO-AccessControl.json` |

**Key settings in SPOTenantSettings:**
- `LegacyAuthProtocolsEnabled = $false`
- `NotificationsInSharePointEnabled = $true`
- `CommentsOnSitePagesDisabled = $false`

**Key settings in SPOSharingSettings:**
- `SharingCapability` (ExternalUserAndGuestSharing / ExistingExternalUserSharingOnly / Disabled)
- `DefaultSharingLinkType` (Internal / Direct / AnonymousAccess)
- `DefaultLinkPermission` (View / Edit)
- `RequireAcceptingAccountMatchInvitedAccount = $true`
- `PreventExternalUsersFromResharing = $true`
- `FileAnonymousLinkType = View`
- `FolderAnonymousLinkType = View`
- `RequireAnonymousLinksExpireInDays = 30`
- `SharingDomainRestrictionMode` (AllowList/BlockList)

**Key settings in SPOAccessControl:**
- `ConditionalAccessPolicy` (AllowFullAccess / AllowLimitedAccess / BlockAccess)
- `DisallowInfectedFileDownload = $true`
- `IPAddressEnforcement = $false` (or $true with IP ranges)
- `BrowserIdleSignout = $true`
- `BrowserIdleSignoutMinutes = 60`
- `BrowserIdleSignoutWarningMinutes = 5`

### Tier 2 — High

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Browser Idle Signout** | SPOBrowserIdleSignout | (in AccessControl) | — |
| **Home Site** | SPOHomeSite | `Set-M365SPOHomeSite` | `SPO-HomeSite.json` |
| **Site Designs** | SPOSiteDesign | `New-M365SPOSiteDesign` | `SPO-SiteDesigns.json` |
| **Site Scripts** | SPOSiteScript | `New-M365SPOSiteScript` | `SPO-SiteScripts.json` |
| **Hub Sites** | SPOHubSite | `Set-M365SPOHubSite` | per-hub JSON |

### Tier 3 — Medium

| Config Area | M365DSC Resource |
|---|---|
| Themes | SPOTheme |
| Search Managed Properties | SPOSearchManagedProperty |
| Search Result Sources | SPOSearchResultSource |
| App Catalog | SPOApp |
| Org Assets Library | SPOOrgAssetsLibrary |
| CDN Settings | SPOTenantCdnEnabled, SPOTenantCDNPolicy |

---

## 4. MICROSOFT TEAMS (`src/Teams/`)

### Tier 1 — Critical

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Meeting Policy** | TeamsMeetingPolicy | `Set-M365TeamsMeetingPolicy` | `TEAMS-MeetingPolicy.json` |
| **Messaging Policy** | TeamsMessagingPolicy | `Set-M365TeamsMessagingPolicy` | `TEAMS-MessagingPolicy.json` |
| **Calling Policy** | TeamsCallingPolicy | `Set-M365TeamsCallingPolicy` | `TEAMS-CallingPolicy.json` |
| **App Permission Policy** | TeamsAppPermissionPolicy | `Set-M365TeamsAppPermissions` | `TEAMS-AppPermissions.json` |
| **Federation / External** | TeamsFederationConfiguration | `Set-M365TeamsFederation` | `TEAMS-Federation.json` |
| **Guest Calling** | TeamsGuestCallingConfiguration | `Set-M365TeamsGuestCalling` | `TEAMS-GuestCalling.json` |
| **Guest Meetings** | TeamsGuestMeetingConfiguration | `Set-M365TeamsGuestMeeting` | `TEAMS-GuestMeeting.json` |
| **Guest Messaging** | TeamsGuestMessagingConfiguration | `Set-M365TeamsGuestMessaging` | `TEAMS-GuestMessaging.json` |

**Key settings in TeamsMeetingPolicy (Global):**
- `AllowTranscription = $true`
- `AllowCloudRecording = $true`
- `AllowIPVideo = $true`
- `AllowAnonymousUsersToJoinMeeting = $true`
- `AutoAdmittedUsers = 'EveryoneInCompanyExcludingGuests'`
- `AllowExternalParticipantGiveRequestControl = $false`
- `DesignatedPresenterRoleMode = 'EveryoneInCompanyUserOverride'`
- `AllowMeetingChat = 'Enabled'`
- `ScreenSharingMode = 'EntireScreen'`

**Key settings in TeamsFederationConfiguration:**
- `AllowFederatedUsers = $true`
- `AllowTeamsConsumer = $false` (or $true based on policy)
- `AllowTeamsConsumerInbound = $false`
- `AllowPublicUsers = $false` (Skype consumer)
- `AllowedDomains` / `BlockedDomains`

### Tier 2 — High

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **App Setup Policy** | TeamsAppSetupPolicy | `Set-M365TeamsAppSetup` | `TEAMS-AppSetup.json` |
| **Channels Policy** | TeamsChannelsPolicy | `Set-M365TeamsChannelsPolicy` | `TEAMS-ChannelsPolicy.json` |
| **Client Configuration** | TeamsClientConfiguration | `Set-M365TeamsClientConfig` | `TEAMS-ClientConfig.json` |
| **Upgrade Configuration** | TeamsUpgradeConfiguration | `Set-M365TeamsUpgradeConfig` | `TEAMS-UpgradeConfig.json` |
| **Upgrade Policy** | TeamsUpgradePolicy | `Set-M365TeamsUpgradePolicy` | `TEAMS-UpgradePolicy.json` |
| **Encryption Policy** | TeamsEnhancedEncryptionPolicy | `Set-M365TeamsEncryption` | `TEAMS-Encryption.json` |
| **Emergency Calling** | TeamsEmergencyCallingPolicy | `Set-M365TeamsEmergencyCalling` | `TEAMS-EmergencyCalling.json` |
| **Broadcast Policy** | TeamsMeetingBroadcastPolicy | `Set-M365TeamsBroadcast` | `TEAMS-Broadcast.json` |

### Tier 3 — Medium

| Config Area | M365DSC Resource |
|---|---|
| Mobility Policy | TeamsMobilityPolicy |
| Compliance Recording | TeamsComplianceRecordingPolicy |
| Events/Webinar Policy | TeamsEventsPolicy |
| Files Policy | TeamsFilesPolicy |
| Workload Policy | TeamsWorkloadPolicy |
| Templates Policy | TeamsTemplatesPolicy |
| Update Management | TeamsUpdateManagementPolicy |
| Voice Routing | TeamsVoiceRoute, TeamsVoiceRoutingPolicy |
| Dial Plans | TeamsTenantDialPlan |
| Voicemail | TeamsOnlineVoicemailPolicy |

---

## 5. INTUNE / ENDPOINT MANAGEMENT (`src/Intune/`)

### Tier 1 — Critical

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Compliance Settings** | IntuneDeviceManagementComplianceSettings | `Set-M365IntuneComplianceSettings` | `INTUNE-ComplianceSettings.json` |
| **Windows Compliance** | IntuneDeviceCompliancePolicyWindows10 | `New-M365IntuneCompliancePolicy` | `INTUNE-ComplianceWindows.json` |
| **iOS Compliance** | IntuneDeviceCompliancePolicyiOs | `New-M365IntuneCompliancePolicy` | `INTUNE-ComplianceiOS.json` |
| **Android Compliance** | IntuneDeviceCompliancePolicyAndroidDeviceOwner | `New-M365IntuneCompliancePolicy` | `INTUNE-ComplianceAndroid.json` |
| **iOS App Protection** | IntuneAppProtectionPolicyiOS | `New-M365IntuneAppProtection` | `INTUNE-AppProtectioniOS.json` |
| **Android App Protection** | IntuneAppProtectionPolicyAndroid | `New-M365IntuneAppProtection` | `INTUNE-AppProtectionAndroid.json` |
| **Enrollment Restrictions** | IntuneDeviceEnrollmentPlatformRestriction | `Set-M365IntuneEnrollmentRestriction` | `INTUNE-EnrollmentRestriction.json` |
| **MDM Enrollment Scope** | IntuneDeviceEnrollmentScopeConfigurationMdm | `Set-M365IntuneMDMScope` | `INTUNE-MDMScope.json` |
| **Security Baseline Win** | IntuneSecurityBaselineWindows10 | `New-M365IntuneSecurityBaseline` | `INTUNE-SecurityBaselineWin.json` |
| **Security Baseline MDE** | IntuneSecurityBaselineDefenderForEndpoint | `New-M365IntuneSecurityBaseline` | `INTUNE-SecurityBaselineMDE.json` |
| **Endpoint Protection** | IntuneDeviceConfigurationEndpointProtectionPolicyWindows10 | `New-M365IntuneEndpointProtection` | `INTUNE-EndpointProtection.json` |
| **Defender Onboarding** | IntuneDeviceConfigurationDefenderOnboardingPolicyWindows10 | `Set-M365IntuneDefenderOnboarding` | `INTUNE-DefenderOnboarding.json` |
| **Autopilot Profile** | IntuneWindowsAutopilotDeploymentProfileAzureADJoined | `New-M365IntuneAutopilotProfile` | `INTUNE-AutopilotAADJ.json` |

### Tier 2 — High

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **macOS Compliance** | IntuneDeviceCompliancePolicyMacOS | `New-M365IntuneCompliancePolicy` | `INTUNE-ComplianceMacOS.json` |
| **Windows Device Config** | IntuneDeviceConfigurationPolicyWindows10 | `New-M365IntuneDeviceConfig` | `INTUNE-DeviceConfigWin.json` |
| **ADMX Templates** | IntuneDeviceConfigurationAdministrativeTemplatePolicyWindows10 | `New-M365IntuneADMXTemplate` | per-template JSON |
| **Settings Catalog** | IntuneSettingCatalogCustomPolicyWindows10 | `New-M365IntuneSettingsCatalog` | per-policy JSON |
| **WHfB Config** | IntuneDeviceConfigurationIdentityProtectionPolicyWindows10 | `Set-M365IntuneWHfB` | `INTUNE-WHfB.json` |
| **Enrollment Status Page** | IntuneDeviceEnrollmentStatusPageWindows10 | `Set-M365IntuneESP` | `INTUNE-ESP.json` |
| **Enrollment Limit** | IntuneDeviceEnrollmentLimitRestriction | `Set-M365IntuneEnrollmentLimit` | `INTUNE-EnrollmentLimit.json` |
| **MAM Scope** | IntuneDeviceEnrollmentScopeConfigurationMam | `Set-M365IntuneMAMScope` | `INTUNE-MAMScope.json` |
| **Edge Baseline** | IntuneSecurityBaselineMicrosoftEdge | `New-M365IntuneSecurityBaseline` | `INTUNE-SecurityBaselineEdge.json` |
| **Office Baseline** | IntuneSecurityBaselineMicrosoft365AppsForEnterprise | `New-M365IntuneSecurityBaseline` | `INTUNE-SecurityBaselineOffice.json` |

---

## 6. SECURITY & COMPLIANCE / PURVIEW (`src/Security/`)

### Tier 1 — Critical

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **DLP Policy** | SCDLPCompliancePolicy + Rule | `New-M365DLPPolicy` | `SEC-DLP-*.json` |
| **Sensitivity Labels** | SCSensitivityLabel | `New-M365SensitivityLabel` | `SEC-SensitivityLabels.json` |
| **Label Publishing** | SCLabelPolicy | `Set-M365LabelPolicy` | `SEC-LabelPolicy.json` |
| **Retention Policy** | SCRetentionCompliancePolicy + Rule | `New-M365RetentionPolicy` | `SEC-Retention-*.json` |
| **Retention Labels** | SCComplianceTag | `New-M365RetentionLabel` | `SEC-RetentionLabels.json` |
| **Audit Log Retention** | SCUnifiedAuditLogRetentionPolicy | `Set-M365AuditRetention` | `SEC-AuditRetention.json` |

### Tier 2 — High

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Custom Sensitive Info Types** | SCDLPSensitiveInformationType | `New-M365SensitiveInfoType` | per-type JSON |
| **Auto-Labeling** | SCAutoSensitivityLabelPolicy + Rule | `New-M365AutoLabelPolicy` | `SEC-AutoLabeling.json` |
| **Alert Policies** | SCProtectionAlert | `Set-M365AlertPolicy` | `SEC-AlertPolicies.json` |
| **Audit Configuration** | SCAuditConfigurationPolicy | `Set-M365AuditConfig` | `SEC-AuditConfig.json` |
| **Insider Risk Policy** | SCInsiderRiskPolicy | `Set-M365InsiderRiskPolicy` | `SEC-InsiderRisk.json` |
| **Compliance Role Groups** | SCRoleGroup + Member | `Set-M365ComplianceRoles` | `SEC-RoleGroups.json` |

### Tier 3 — Medium

| Config Area | M365DSC Resource |
|---|---|
| Communication Compliance | SCSupervisoryReviewPolicy + Rule |
| eDiscovery / Holds | (managed per-case, not baseline) |
| Information Barriers | (specialized) |
| File Plan Properties | SCFilePlanProperty* |

---

## 7. DEFENDER FOR OFFICE 365 (`src/Defender/`)

### Tier 1 — Critical

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Global ATP Settings** | EXOAtpPolicyForO365 | `Set-M365DefenderGlobal` | `DEF-AtpGlobal.json` |
| **Safe Attachments** | EXOSafeAttachmentPolicy + Rule | `Set-M365DefenderSafeAttachments` | `DEF-SafeAttachments.json` |
| **Safe Links** | EXOSafeLinksPolicy + Rule | `Set-M365DefenderSafeLinks` | `DEF-SafeLinks.json` |
| **Anti-Phishing** | EXOAntiPhishPolicy + Rule | `Set-M365DefenderAntiPhish` | `DEF-AntiPhish.json` |
| **Anti-Malware** | EXOMalwareFilterPolicy + Rule | `Set-M365DefenderAntiMalware` | `DEF-AntiMalware.json` |
| **Anti-Spam** | EXOHostedContentFilterPolicy + Rule | `Set-M365DefenderAntiSpam` | `DEF-AntiSpam.json` |
| **Preset Standard** | EXOAtpProtectionPolicyRule + EXOEOPProtectionPolicyRule | `Set-M365DefenderPreset` | `DEF-PresetStandard.json` |
| **Built-in Protection** | EXOATPBuiltInProtectionRule | (auto via Preset) | — |

### Tier 2 — High

| Config Area | M365DSC Resource | Our Function | JSON Config |
|---|---|---|---|
| **Teams Protection** | EXOTeamsProtectionPolicy | `Set-M365DefenderTeams` | `DEF-TeamsProtection.json` |
| **Quarantine Policy** | EXOQuarantinePolicy | `Set-M365DefenderQuarantine` | `DEF-QuarantinePolicy.json` |
| **Allow/Block List** | EXOTenantAllowBlockListItems | `Set-M365DefenderAllowBlock` | `DEF-AllowBlockList.json` |
| **Outbound Spam** | EXOHostedOutboundSpamFilterPolicy + Rule | `Set-M365DefenderOutboundSpam` | `DEF-OutboundSpam.json` |
| **Connection Filter** | EXOHostedConnectionFilterPolicy | `Set-M365DefenderConnectionFilter` | `DEF-ConnectionFilter.json` |

---

## Implementation Priority (Roadmap)

Based on customer impact and frequency of use:

| Phase | Module | Estimated Configs | Status |
|---|---|---|---|
| **Phase 1** | Conditional Access | 10 policies | ✅ Done |
| **Phase 2** | Entra ID (Identity) | 15-20 configs | Next |
| **Phase 3** | Defender for O365 | 10-15 configs | |
| **Phase 4** | Exchange Online | 20-25 configs | |
| **Phase 5** | SharePoint Online | 5-7 configs | |
| **Phase 6** | Teams | 12-15 configs | |
| **Phase 7** | Intune | 15-20 configs | |
| **Phase 8** | Security & Compliance | 10-15 configs | |

**Total estimated configs at full coverage: ~100-120 JSON config files**

---

## Profile Expansion Plan

With all services implemented, profiles would look like:

### SMB-Standard (expanded)
- CA: Block Legacy Auth, MFA Admins, MFA All, Block High Risk, MFA Guests
- Entra: Authorization Policy, Auth Methods, Password Protection, Admin Consent
- Defender: Preset Standard, Safe Links, Safe Attachments, Anti-Phish
- EXO: Org Config (audit on), DKIM, External Tag, Transport Rules
- SPO: Sharing (restricted), Access Control
- Teams: Meeting Policy, Guest Settings, Federation, App Permissions

### Enterprise-Hardened (expanded)
- Everything in SMB-Standard plus:
- CA: All 10 policies
- Entra: Cross-Tenant Access, Group Settings, Device Registration, Auth Strength
- EXO: Full email security stack, Retention, IRM
- SPO: Strict sharing, Browser Idle Signout
- Teams: Full policy suite, Encryption, Channels Policy
- Intune: Compliance Policies, Security Baselines, App Protection, Autopilot
- Security: DLP, Sensitivity Labels, Retention, Audit Retention
