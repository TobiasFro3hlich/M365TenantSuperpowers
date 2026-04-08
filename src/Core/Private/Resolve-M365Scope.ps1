function Resolve-M365Scope {
    <#
    .SYNOPSIS
        Aggregates required Graph scopes from all loaded sub-module manifests.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$AdditionalScopes = @()
    )

    $allScopes = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    # Scan sub-module manifests for required scopes
    $moduleRoot = (Get-Module 'M365TenantSuperpowers').ModuleBase
    $subModulePaths = Get-ChildItem -Path (Join-Path $moduleRoot 'src') -Filter '*.psd1' -Recurse -ErrorAction SilentlyContinue

    foreach ($manifestPath in $subModulePaths) {
        try {
            $manifestData = Import-PowerShellDataFile -Path $manifestPath.FullName
            $m365Data = $manifestData.PrivateData.M365TenantSuperpowers
            if ($m365Data -and $m365Data.RequiredScopes) {
                foreach ($scope in $m365Data.RequiredScopes) {
                    [void]$allScopes.Add($scope)
                }
            }
        }
        catch {
            Write-Verbose "Could not read manifest: $($manifestPath.FullName) - $_"
        }
    }

    # Add any additional scopes requested
    foreach ($scope in $AdditionalScopes) {
        [void]$allScopes.Add($scope)
    }

    return [string[]]$allScopes
}
