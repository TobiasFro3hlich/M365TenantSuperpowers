function Get-M365EntraPIMReport {
    <#
    .SYNOPSIS
        Generates a report of PIM role assignments and settings.
    .DESCRIPTION
        Audits active vs eligible role assignments, permanent assignments,
        approval settings, and notification configuration for privileged roles.
        Checks compliance with CISA SCuBA MS.AAD.7.x requirements.
    .EXAMPLE
        Get-M365EntraPIMReport | Export-M365Report -Format HTML -Title 'PIM Audit'
    #>
    [CmdletBinding()]
    param()

    Assert-M365Connection -Service Graph

    $report = [System.Collections.Generic.List[object]]::new()

    # Highly privileged role template IDs
    $privilegedRoles = @{
        '62e90394-69f5-4237-9190-012177145e10' = 'Global Administrator'
        'e8611ab8-c189-46e8-94e1-60213ab1f814' = 'Privileged Role Administrator'
        '194ae4cb-b126-40b2-bd5b-6091b380977d' = 'Security Administrator'
        'f28a1f50-f6e7-4571-818b-6a12f2af6b6c' = 'SharePoint Administrator'
        '29232cdf-9323-42fd-ade2-1d097af3e4de' = 'Exchange Administrator'
        'fe930be7-5e62-47db-91af-98c3a49a38b1' = 'User Administrator'
        'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9' = 'Conditional Access Administrator'
        '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3' = 'Application Administrator'
    }

    # Get all eligible assignments
    try {
        $eligibleAssignments = Invoke-M365EntraGraphRequest -Method GET `
            -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleEligibilityScheduleInstances' `
            -Description 'Get PIM eligible assignments'

        $report.Add([PSCustomObject]@{
            Section = 'PIM Overview'
            Setting = 'Total Eligible Assignments'
            Value   = $eligibleAssignments.value.Count
        })
    }
    catch { Write-M365Log -Message "Could not read eligible assignments: $_" -Level Warning }

    # Get all active assignments
    try {
        $activeAssignments = Invoke-M365EntraGraphRequest -Method GET `
            -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances' `
            -Description 'Get PIM active assignments'

        $report.Add([PSCustomObject]@{
            Section = 'PIM Overview'
            Setting = 'Total Active Assignments'
            Value   = $activeAssignments.value.Count
        })

        # Check for permanent active assignments (CISA MS.AAD.7.4v1)
        $permanentActive = $activeAssignments.value | Where-Object {
            $_.assignmentType -eq 'Assigned' -and
            ($null -eq $_.endDateTime -or $_.endDateTime -eq '')
        }
        $report.Add([PSCustomObject]@{
            Section = 'PIM Compliance'
            Setting = 'Permanent Active Assignments (should be 0 except break-glass)'
            Value   = $permanentActive.Count
        })

        # Count Global Admins (CISA MS.AAD.7.1v1: between 2 and 8)
        $gaRoleId = '62e90394-69f5-4237-9190-012177145e10'
        $gaActive = $activeAssignments.value | Where-Object { $_.roleDefinitionId -eq $gaRoleId }
        $gaEligible = if ($eligibleAssignments) { $eligibleAssignments.value | Where-Object { $_.roleDefinitionId -eq $gaRoleId } } else { @() }
        $gaTotal = ($gaActive.Count + $gaEligible.Count)

        $report.Add([PSCustomObject]@{
            Section = 'PIM Compliance'
            Setting = 'Global Admins (active + eligible, should be 2-8)'
            Value   = "$gaTotal (Active: $($gaActive.Count), Eligible: $($gaEligible.Count))"
        })

        # Per privileged role breakdown
        foreach ($roleId in $privilegedRoles.Keys) {
            $roleName = $privilegedRoles[$roleId]
            $roleActive = $activeAssignments.value | Where-Object { $_.roleDefinitionId -eq $roleId }
            $roleEligible = if ($eligibleAssignments) { $eligibleAssignments.value | Where-Object { $_.roleDefinitionId -eq $roleId } } else { @() }

            if ($roleActive.Count -gt 0 -or $roleEligible.Count -gt 0) {
                $rolePermanent = $roleActive | Where-Object { $null -eq $_.endDateTime -or $_.endDateTime -eq '' }
                $report.Add([PSCustomObject]@{
                    Section = 'Role Assignments'
                    Setting = $roleName
                    Value   = "Active: $($roleActive.Count), Eligible: $($roleEligible.Count), Permanent: $($rolePermanent.Count)"
                })
            }
        }
    }
    catch { Write-M365Log -Message "Could not read active assignments: $_" -Level Warning }

    # Check PIM policy settings for Global Admin
    try {
        $policyAssignments = Invoke-M365EntraGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$gaRoleId'" `
            -Description 'Get GA PIM policy'

        if ($policyAssignments.value.Count -gt 0) {
            $policyId = $policyAssignments.value[0].policyId
            $rules = Invoke-M365EntraGraphRequest -Method GET `
                -Uri "https://graph.microsoft.com/v1.0/policies/roleManagementPolicies/$policyId/rules" `
                -Description 'Get GA PIM rules'

            foreach ($rule in $rules.value) {
                switch ($rule.id) {
                    'Approval_EndUser_Assignment' {
                        $report.Add([PSCustomObject]@{
                            Section = 'GA PIM Settings'
                            Setting = 'Activation Requires Approval (CISA MS.AAD.7.6v1)'
                            Value   = $rule.setting.isApprovalRequired
                        })
                    }
                    'Expiration_Admin_Assignment' {
                        $report.Add([PSCustomObject]@{
                            Section = 'GA PIM Settings'
                            Setting = 'Active Assignment Expiration Required'
                            Value   = $rule.isExpirationRequired
                        })
                    }
                }
            }
        }
    }
    catch { Write-M365Log -Message "Could not read GA PIM policy: $_" -Level Warning }

    return $report
}
