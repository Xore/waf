#Requires -Version 5.1
Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Clears Microsoft Teams cache.
.DESCRIPTION
    Clears all Microsoft Teams cache for the current user including Classic and New Teams.
    Stops Teams processes and clears all cache directories.
.EXAMPLE
    No parameters needed
    Clears Microsoft Teams cache.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Refactored to V3.0 standards with Write-Log function
#>

[CmdletBinding()]
param ()

begin {
    $StartTime = Get-Date

    function Write-Log {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $Output = "[$Timestamp] [$Level] $Message"
        Write-Host $Output
    }

    $ClassicTeamsPaths = @(
        "$env:APPDATA\Microsoft\Teams\Application Cache\Cache"
        "$env:APPDATA\Microsoft\Teams\blob_storage"
        "$env:APPDATA\Microsoft\Teams\Cache"
        "$env:APPDATA\Microsoft\Teams\databases"
        "$env:APPDATA\Microsoft\Teams\GPUCache"
        "$env:APPDATA\Microsoft\Teams\IndexedDB"
        "$env:APPDATA\Microsoft\Teams\Local Storage"
        "$env:APPDATA\Microsoft\Teams\tmp"
        "$env:APPDATA\Microsoft\Teams\Code Cache"
        "$env:APPDATA\Microsoft\Teams\Service Worker\CacheStorage"
        "$env:APPDATA\Microsoft\Teams\Service Worker\ScriptCache"
    )

    $NewTeamsPaths = @(
        "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache"
        "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\AC\INetCache"
        "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\AC\INetCookies"
        "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\AC\INetHistory"
        "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\TempState"
        "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalState\Microsoft\Teams\Cache"
        "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalState\Microsoft\Teams\Logs"
    )

    $AdditionalPaths = @(
        "$env:TEMP\teams"
        "$env:LOCALAPPDATA\Microsoft\Teams"
    )

    $AllPaths = $ClassicTeamsPaths + $NewTeamsPaths + $AdditionalPaths
}

process {
    Write-Log "Microsoft Teams Cache Cleaner"
    Write-Log "Stopping Teams processes..."

    try {
        Get-Process -Name "Teams" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Get-Process -Name "ms-teams" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Get-Process -Name "TeamsMeetingAddin" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Get-Process -Name "TeamsWebView" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        Write-Log "Teams processes stopped successfully"
        Start-Sleep -Seconds 2
    }
    catch {
        Write-Log "Could not stop all Teams processes: $_" -Level Warning
    }

    Write-Log "Clearing cache directories..."

    $ClearedCount = 0
    $ErrorCount = 0

    foreach ($Path in $AllPaths) {
        if (Test-Path $Path) {
            try {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                Write-Log "Cleared: $Path"
                $ClearedCount++
            }
            catch {
                Write-Log "Failed to clear: $Path - $_" -Level Warning
                $ErrorCount++
            }
        }
    }

    Write-Log "Cache directories cleared: $ClearedCount"
    if ($ErrorCount -gt 0) {
        Write-Log "Errors encountered: $ErrorCount" -Level Warning
    }

    Write-Log "Teams cache cleanup completed. Please restart Microsoft Teams manually"
}

end {
    $EndTime = Get-Date
    $ExecutionTime = ($EndTime - $StartTime).TotalSeconds
    Write-Log "Script execution completed in $ExecutionTime seconds"
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
