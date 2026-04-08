function Test-M365Prerequisites {
    <#
    .SYNOPSIS
        Checks that required PowerShell modules are installed and meet version requirements.
    .DESCRIPTION
        Validates all module dependencies needed for M365TenantSuperpowers operations.
        Returns a report of installed/missing modules.
    .PARAMETER Services
        Which service modules to check. Default: all.
    .PARAMETER Install
        If specified, attempts to install missing modules.
    .EXAMPLE
        Test-M365Prerequisites
    .EXAMPLE
        Test-M365Prerequisites -Services Graph, ExchangeOnline -Install
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Graph', 'ExchangeOnline', 'SharePoint', 'Teams', 'All')]
        [string[]]$Services = @('All'),

        [Parameter()]
        [switch]$Install
    )

    $requirements = @{
        Graph = @(
            @{ Name = 'Microsoft.Graph.Authentication'; MinVersion = '2.0.0' }
            @{ Name = 'Microsoft.Graph.Identity.SignIns'; MinVersion = '2.0.0' }
            @{ Name = 'Microsoft.Graph.Users'; MinVersion = '2.0.0' }
            @{ Name = 'Microsoft.Graph.Groups'; MinVersion = '2.0.0' }
        )
        ExchangeOnline = @(
            @{ Name = 'ExchangeOnlineManagement'; MinVersion = '3.0.0' }
        )
        SharePoint = @(
            @{ Name = 'PnP.PowerShell'; MinVersion = '2.0.0' }
        )
        Teams = @(
            @{ Name = 'MicrosoftTeams'; MinVersion = '5.0.0' }
        )
    }

    if ('All' -in $Services) {
        $Services = @('Graph', 'ExchangeOnline', 'SharePoint', 'Teams')
    }

    $report = [System.Collections.Generic.List[object]]::new()

    foreach ($service in $Services) {
        foreach ($req in $requirements[$service]) {
            $installed = Get-Module -ListAvailable -Name $req.Name |
                Sort-Object Version -Descending |
                Select-Object -First 1

            $status = if (-not $installed) {
                'Missing'
            }
            elseif ($installed.Version -lt [version]$req.MinVersion) {
                'Outdated'
            }
            else {
                'OK'
            }

            $entry = [PSCustomObject]@{
                Service         = $service
                Module          = $req.Name
                RequiredVersion = $req.MinVersion
                InstalledVersion = if ($installed) { $installed.Version.ToString() } else { '-' }
                Status          = $status
            }
            $report.Add($entry)

            if ($status -ne 'OK' -and $Install) {
                Write-M365Log -Message "Installing $($req.Name)..." -Level Info
                try {
                    Install-Module -Name $req.Name -MinimumVersion $req.MinVersion -Scope CurrentUser -Force -AllowClobber
                    Write-M365Log -Message "Installed $($req.Name) successfully." -Level Info
                }
                catch {
                    Write-M365Log -Message "Failed to install $($req.Name): $_" -Level Error
                }
            }
        }
    }

    # Summary
    $missing = $report | Where-Object Status -ne 'OK'
    if ($missing) {
        Write-M365Log -Message "$($missing.Count) module(s) need attention. Use -Install to auto-install." -Level Warning
    }
    else {
        Write-M365Log -Message "All prerequisites met." -Level Info
    }

    return $report
}
