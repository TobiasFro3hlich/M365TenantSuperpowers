# SharePoint Sub-Module Loader
$Private = @(Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue)
foreach ($file in $Private) { . $file.FullName }

$Public = @(Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue)
foreach ($file in $Public) { . $file.FullName }

Export-ModuleMember -Function $Public.BaseName
