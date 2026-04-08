function Write-M365Log {
    <#
    .SYNOPSIS
        Writes a structured log message to the console and optionally to a file.
    .DESCRIPTION
        Provides consistent logging across all M365TenantSuperpowers functions
        with severity levels and color-coded console output.
    .PARAMETER Message
        The log message.
    .PARAMETER Level
        Severity level: Debug, Info, Warning, Error. Default: Info.
    .PARAMETER LogFile
        Optional file path to append log messages to.
    .EXAMPLE
        Write-M365Log -Message "Connected successfully" -Level Info
    .EXAMPLE
        Write-M365Log -Message "Policy not found" -Level Warning -LogFile './logs/run.log'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Debug', 'Info', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [Parameter()]
        [string]$LogFile
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"

    # Console output with color
    switch ($Level) {
        'Debug'   { Write-Verbose $logEntry }
        'Info'    { Write-Host $logEntry -ForegroundColor Cyan }
        'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
        'Error'   { Write-Host $logEntry -ForegroundColor Red }
    }

    # File output
    if ($LogFile) {
        $logDir = Split-Path $LogFile -Parent
        if ($logDir -and -not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $logEntry | Add-Content -Path $LogFile -Encoding UTF8
    }
}
