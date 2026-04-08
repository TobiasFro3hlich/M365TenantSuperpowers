function Set-M365EXOSharedMailboxBlock {
    <#
    .SYNOPSIS
        Blocks direct sign-in for all shared mailboxes.
    .DESCRIPTION
        Shared mailboxes should not allow direct sign-in. This function finds all
        shared mailboxes and disables their user account sign-in. Required by CIS 1.2.2.
    .EXAMPLE
        Set-M365EXOSharedMailboxBlock
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Assert-M365Connection -Service ExchangeOnline

    if ($PSCmdlet.ShouldProcess('All Shared Mailboxes', 'Block direct sign-in')) {
        Write-M365Log -Message "Blocking sign-in for shared mailboxes..." -Level Info

        $results = [System.Collections.Generic.List[object]]::new()

        try {
            $sharedMailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -ErrorAction Stop

            foreach ($mb in $sharedMailboxes) {
                try {
                    $user = Get-MgUser -UserId $mb.ExternalDirectoryObjectId -Property 'accountEnabled' -ErrorAction Stop

                    if ($user.AccountEnabled) {
                        Update-MgUser -UserId $mb.ExternalDirectoryObjectId -AccountEnabled:$false -ErrorAction Stop
                        $results.Add([PSCustomObject]@{
                            Mailbox = $mb.DisplayName
                            UPN     = $mb.UserPrincipalName
                            Action  = 'Blocked'
                            Changed = $true
                        })
                        Write-M365Log -Message "Blocked sign-in: $($mb.UserPrincipalName)" -Level Info
                    }
                    else {
                        $results.Add([PSCustomObject]@{
                            Mailbox = $mb.DisplayName
                            UPN     = $mb.UserPrincipalName
                            Action  = 'AlreadyBlocked'
                            Changed = $false
                        })
                    }
                }
                catch {
                    Write-M365Log -Message "Failed to process $($mb.UserPrincipalName): $_" -Level Warning
                    $results.Add([PSCustomObject]@{
                        Mailbox = $mb.DisplayName
                        UPN     = $mb.UserPrincipalName
                        Action  = 'Failed'
                        Changed = $false
                    })
                }
            }

            $blocked = ($results | Where-Object Action -eq 'Blocked').Count
            Write-M365Log -Message "Shared mailbox sign-in block: $blocked blocked, $($sharedMailboxes.Count) total" -Level Info
        }
        catch {
            Write-M365Log -Message "Failed to get shared mailboxes: $_" -Level Error
            throw
        }

        return $results
    }
}
