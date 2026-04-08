function Set-M365EntraPIMRoleSettings {
    <#
    .SYNOPSIS
        Configures PIM (Privileged Identity Management) role settings.
    .DESCRIPTION
        Sets activation requirements (approval, MFA, justification), assignment rules
        (no permanent active, max eligibility duration), and notification settings
        for highly privileged Entra ID roles. Required by CISA SCuBA MS.AAD.7.x.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        Set-M365EntraPIMRoleSettings -ConfigName 'ENTRA-PIMRoleSettings'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$ConfigName,

        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [string]$ConfigPath,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    Assert-M365Connection -Service Graph

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/EntraID/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('PIM Role Settings', 'Configure Privileged Identity Management')) {
        Write-M365Log -Message "Applying PIM role settings..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        foreach ($roleSetting in $desired.roleSettings) {
            $roleDisplayName = $roleSetting.roleDisplayName
            $roleTemplateId = $roleSetting.roleTemplateId

            Write-M365Log -Message "Configuring PIM settings for role: $roleDisplayName" -Level Info

            try {
                # Get the policy assignment for this role
                $policyAssignments = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$roleTemplateId'" `
                    -Description "Get PIM policy for $roleDisplayName"

                if (-not $policyAssignments.value -or $policyAssignments.value.Count -eq 0) {
                    Write-M365Log -Message "No PIM policy assignment found for role: $roleDisplayName" -Level Warning
                    $results.Add([PSCustomObject]@{ Role = $roleDisplayName; Action = 'NotFound'; Changed = $false })
                    continue
                }

                $policyId = $policyAssignments.value[0].policyId

                # Get the policy rules
                $policyRules = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$policyId/rules" `
                    -Description "Get PIM rules for $roleDisplayName"

                # Update activation rules
                foreach ($rule in $policyRules.value) {
                    $ruleId = $rule.id
                    $ruleType = $rule.'@odata.type'
                    $updated = $false
                    $updateBody = @{
                        '@odata.type' = $ruleType
                        id            = $ruleId
                        target        = $rule.target
                    }

                    switch ($ruleId) {
                        # Activation: require approval
                        'Approval_EndUser_Assignment' {
                            if ($null -ne $roleSetting.activationRequireApproval) {
                                $updateBody['setting'] = @{
                                    isApprovalRequired               = $roleSetting.activationRequireApproval
                                    isApprovalRequiredForExtension   = $false
                                    isRequestorJustificationRequired = $true
                                    approvalMode                     = 'SingleStage'
                                    approvalStages                   = @(@{
                                        approvalStageTimeOutInDays      = 1
                                        isApproverJustificationRequired = $true
                                        isEscalationEnabled             = $false
                                        primaryApprovers                = if ($roleSetting.approvers) { $roleSetting.approvers } else { @() }
                                    })
                                }
                                $updated = $true
                            }
                        }

                        # Activation: require MFA
                        'AuthenticationContext_EndUser_Assignment' {
                            if ($null -ne $roleSetting.activationRequireMFA) {
                                $updateBody['isEnabled'] = $roleSetting.activationRequireMFA
                                if ($roleSetting.activationRequireMFA) {
                                    $updateBody['claimValue'] = 'c1'
                                }
                                $updated = $true
                            }
                        }

                        # Activation: max duration
                        'Expiration_EndUser_Assignment' {
                            if ($roleSetting.activationMaxDurationHours) {
                                $updateBody['isExpirationRequired'] = $true
                                $updateBody['maximumDuration'] = "PT$($roleSetting.activationMaxDurationHours)H"
                                $updated = $true
                            }
                        }

                        # Eligible assignment: max duration
                        'Expiration_Admin_Eligibility' {
                            if ($roleSetting.eligibleAssignmentMaxDays) {
                                $updateBody['isExpirationRequired'] = $true
                                $updateBody['maximumDuration'] = "P$($roleSetting.eligibleAssignmentMaxDays)D"
                                $updated = $true
                            }
                        }

                        # Active assignment: no permanent
                        'Expiration_Admin_Assignment' {
                            if ($null -ne $roleSetting.permanentActiveAssignmentAllowed) {
                                $updateBody['isExpirationRequired'] = (-not $roleSetting.permanentActiveAssignmentAllowed)
                                if ($roleSetting.activeAssignmentMaxDays) {
                                    $updateBody['maximumDuration'] = "P$($roleSetting.activeAssignmentMaxDays)D"
                                }
                                $updated = $true
                            }
                        }

                        # Notification: role assignment alerts
                        'Notification_Admin_Admin_Assignment' {
                            if ($roleSetting.notifyOnActiveAssignment) {
                                $updateBody['isDefaultRecipientsEnabled'] = $true
                                if ($roleSetting.notificationRecipients) {
                                    $updateBody['notificationRecipients'] = $roleSetting.notificationRecipients
                                }
                                $updateBody['notificationLevel'] = 'All'
                                $updated = $true
                            }
                        }

                        # Notification: eligible assignment alerts
                        'Notification_Admin_Admin_Eligibility' {
                            if ($roleSetting.notifyOnEligibleAssignment) {
                                $updateBody['isDefaultRecipientsEnabled'] = $true
                                if ($roleSetting.notificationRecipients) {
                                    $updateBody['notificationRecipients'] = $roleSetting.notificationRecipients
                                }
                                $updateBody['notificationLevel'] = 'All'
                                $updated = $true
                            }
                        }

                        # Notification: activation alerts
                        'Notification_Admin_EndUser_Assignment' {
                            if ($roleSetting.notifyOnActivation) {
                                $updateBody['isDefaultRecipientsEnabled'] = $true
                                if ($roleSetting.notificationRecipients) {
                                    $updateBody['notificationRecipients'] = $roleSetting.notificationRecipients
                                }
                                $updateBody['notificationLevel'] = 'All'
                                $updated = $true
                            }
                        }
                    }

                    if ($updated) {
                        Invoke-M365EntraGraphRequest -Method PATCH `
                            -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$policyId/rules/$ruleId" `
                            -Body $updateBody `
                            -Description "Update PIM rule $ruleId for $roleDisplayName"
                    }
                }

                $results.Add([PSCustomObject]@{
                    Role     = $roleDisplayName
                    RoleId   = $roleTemplateId
                    PolicyId = $policyId
                    Action   = 'Updated'
                    Changed  = $true
                })
                Write-M365Log -Message "PIM settings for '$roleDisplayName' updated." -Level Info
            }
            catch {
                Write-M365Log -Message "Failed to configure PIM for '$roleDisplayName': $_" -Level Error
                $results.Add([PSCustomObject]@{ Role = $roleDisplayName; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
            }
        }

        return $results
    }
}
