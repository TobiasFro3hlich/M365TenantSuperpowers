function Set-M365EXOMailboxAuditActions {
    <#
    .SYNOPSIS
        Ensures all mailbox audit actions are configured for all mailboxes.
    .DESCRIPTION
        Enables comprehensive mailbox auditing with all audit actions for Owner,
        Delegate, and Admin operations. Required by CIS 6.1.2.
    .PARAMETER ConfigName
        Name of the JSON config from configs/Exchange/.
    .EXAMPLE
        Set-M365EXOMailboxAuditActions -ConfigName 'EXO-MailboxAudit'
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

    Assert-M365Connection -Service ExchangeOnline

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
        $ConfigPath = Join-Path $moduleRoot "configs/Exchange/$ConfigName.json"
    }

    $config = Get-M365Config -ConfigPath $ConfigPath -Parameters $Parameters
    $desired = $config.settings

    if ($PSCmdlet.ShouldProcess('Mailbox Audit Actions', 'Configure audit actions for all mailboxes')) {
        Write-M365Log -Message "Configuring mailbox audit actions..." -Level Info

        try {
            $params = @{}

            if ($desired.AuditAdmin) { $params['AuditAdmin'] = $desired.AuditAdmin }
            if ($desired.AuditDelegate) { $params['AuditDelegate'] = $desired.AuditDelegate }
            if ($desired.AuditOwner) { $params['AuditOwner'] = $desired.AuditOwner }

            # Get all user mailboxes
            $mailboxes = Get-EXOMailbox -ResultSize Unlimited -Properties AuditEnabled -ErrorAction Stop

            $updated = 0
            foreach ($mb in $mailboxes) {
                try {
                    Set-Mailbox -Identity $mb.UserPrincipalName -AuditEnabled $true @params -ErrorAction Stop
                    $updated++
                }
                catch {
                    Write-M365Log -Message "Failed to set audit for $($mb.UserPrincipalName): $_" -Level Warning
                }
            }

            Write-M365Log -Message "Mailbox audit actions configured for $updated of $($mailboxes.Count) mailboxes." -Level Info

            return [PSCustomObject]@{
                ConfigName       = if ($ConfigName) { $ConfigName } else { Split-Path $ConfigPath -Leaf }
                Setting          = 'Mailbox Audit Actions'
                MailboxesUpdated = $updated
                MailboxesTotal   = $mailboxes.Count
                Action           = 'Updated'
                Changed          = ($updated -gt 0)
            }
        }
        catch {
            Write-M365Log -Message "Failed to configure mailbox audit: $_" -Level Error
            throw
        }
    }
}
