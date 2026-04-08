function New-M365EntraAccessReview {
    <#
    .SYNOPSIS
        Creates access reviews for guest users and/or privileged roles.
    .DESCRIPTION
        Configures recurring access reviews per CIS 5.3.2 (guests) and 5.3.3 (privileged roles).
        Reviews prompt designated reviewers to confirm or deny access periodically.
    .PARAMETER ConfigName
        Name of the JSON config from configs/EntraID/.
    .EXAMPLE
        New-M365EntraAccessReview -ConfigName 'ENTRA-AccessReviews'
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
    $reviews = $config.settings.accessReviews

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($review in $reviews) {
        $reviewName = $review.displayName

        if ($PSCmdlet.ShouldProcess($reviewName, "Create access review")) {
            Write-M365Log -Message "Creating access review: $reviewName" -Level Info

            try {
                # Check if review already exists
                $existing = Invoke-M365EntraGraphRequest -Method GET `
                    -Uri "https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions?`$filter=displayName eq '$reviewName'" `
                    -Description "Check existing review '$reviewName'"

                if ($existing.value.Count -gt 0) {
                    $results.Add([PSCustomObject]@{ ReviewName = $reviewName; Action = 'AlreadyExists'; Changed = $false })
                    Write-M365Log -Message "Access review '$reviewName' already exists." -Level Info
                    continue
                }

                $body = @{
                    displayName                    = $reviewName
                    descriptionForAdmins           = $review.descriptionForAdmins
                    descriptionForReviewers        = $review.descriptionForReviewers
                    scope                          = $review.scope
                    reviewers                      = $review.reviewers
                    settings                       = @{
                        mailNotificationsEnabled        = $true
                        reminderNotificationsEnabled    = $true
                        justificationRequiredOnApproval = $true
                        defaultDecisionEnabled          = $true
                        defaultDecision                 = $review.defaultDecision
                        autoApplyDecisionsEnabled       = $review.autoApplyDecisions
                        recommendationsEnabled          = $true
                        recurrence                      = $review.recurrence
                    }
                }

                $response = Invoke-M365EntraGraphRequest -Method POST `
                    -Uri 'https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions' `
                    -Body $body `
                    -Description "Create access review '$reviewName'"

                $results.Add([PSCustomObject]@{
                    ReviewName = $reviewName
                    ReviewId   = $response.id
                    Action     = 'Created'
                    Changed    = $true
                })
                Write-M365Log -Message "Access review '$reviewName' created (ID: $($response.id))." -Level Info
            }
            catch {
                Write-M365Log -Message "Failed to create access review '$reviewName': $_" -Level Error
                $results.Add([PSCustomObject]@{ ReviewName = $reviewName; Action = 'Failed'; Changed = $false; Error = $_.ToString() })
            }
        }
    }

    return $results
}
