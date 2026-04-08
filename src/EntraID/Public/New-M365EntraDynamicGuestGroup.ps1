function New-M365EntraDynamicGuestGroup {
    <#
    .SYNOPSIS
        Creates a dynamic security group containing all guest users.
    .DESCRIPTION
        Creates a dynamic group with membership rule (user.userType -eq "Guest").
        Required by CIS 5.1.3.1 for guest lifecycle management and access reviews.
    .PARAMETER GroupName
        Display name for the group. Default: 'All Guest Users (Dynamic)'.
    .EXAMPLE
        New-M365EntraDynamicGuestGroup
    .EXAMPLE
        New-M365EntraDynamicGuestGroup -GroupName 'External Users - Dynamic'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$GroupName = 'All Guest Users (Dynamic)'
    )

    Assert-M365Connection -Service Graph

    # Check if group already exists
    $existing = Invoke-M365EntraGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'" `
        -Description "Check for existing group '$GroupName'"

    if ($existing.value.Count -gt 0) {
        Write-M365Log -Message "Dynamic guest group '$GroupName' already exists (ID: $($existing.value[0].id))." -Level Info
        return [PSCustomObject]@{
            GroupName = $GroupName
            GroupId   = $existing.value[0].id
            Action    = 'AlreadyExists'
            Changed   = $false
        }
    }

    if ($PSCmdlet.ShouldProcess($GroupName, "Create dynamic guest group")) {
        Write-M365Log -Message "Creating dynamic guest group: $GroupName" -Level Info

        $body = @{
            displayName                = $GroupName
            description                = 'Dynamic security group containing all guest/external users. Created by M365TenantSuperpowers for guest lifecycle management.'
            mailEnabled                = $false
            mailNickname               = ($GroupName -replace '[^\w]', '') + (Get-Random -Maximum 9999)
            securityEnabled            = $true
            groupTypes                 = @('DynamicMembership')
            membershipRule             = '(user.userType -eq "Guest")'
            membershipRuleProcessingState = 'On'
        }

        try {
            $response = Invoke-M365EntraGraphRequest -Method POST `
                -Uri 'https://graph.microsoft.com/v1.0/groups' `
                -Body $body `
                -Description "Create dynamic guest group"

            Write-M365Log -Message "Dynamic guest group created: $GroupName (ID: $($response.id))" -Level Info

            return [PSCustomObject]@{
                GroupName = $GroupName
                GroupId   = $response.id
                Action    = 'Created'
                Changed   = $true
            }
        }
        catch {
            Write-M365Log -Message "Failed to create dynamic guest group: $_" -Level Error
            throw
        }
    }
}
