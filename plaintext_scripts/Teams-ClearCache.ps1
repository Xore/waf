<#
.SYNOPSIS
    Clears all Microsoft Teams cache for the current user (Classic and New Teams)
.DESCRIPTION
    This script stops Teams processes and clears all cache directories for both
    Classic Teams and New Teams to resolve performance and sync issues.
.NOTES
    Author: MoellerGroup IT
    Version: 1.1
#>

Write-Output "Microsoft Teams Cache Cleaner"
Write-Output "=============================="
Write-Output ""
Write-Output "Stopping Teams processes..."

# Stop all Teams processes
try {
    # Stop Classic Teams
    Get-Process -Name "Teams" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Stop New Teams (ms-teams)
    Get-Process -Name "ms-teams" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Additional Teams related processes
    Get-Process -Name "TeamsMeetingAddin" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process -Name "TeamsWebView" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Output "Teams processes stopped successfully"
    
    # Wait a moment to ensure processes are fully terminated
    Start-Sleep -Seconds 2
}
catch {
    Write-Output "Warning: Could not stop all Teams processes - $_"
}

# Define cache paths for Classic Teams
$classicTeamsPaths = @(
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

# Define cache paths for New Teams
$newTeamsPaths = @(
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache"
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\AC\INetCache"
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\AC\INetCookies"
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\AC\INetHistory"
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\TempState"
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalState\Microsoft\Teams\Cache"
    "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalState\Microsoft\Teams\Logs"
)

# Additional cache locations
$additionalPaths = @(
    "$env:TEMP\teams"
    "$env:LOCALAPPDATA\Microsoft\Teams"
)

# Combine all paths
$allPaths = $classicTeamsPaths + $newTeamsPaths + $additionalPaths

Write-Output ""
Write-Output "Clearing cache directories..."
Write-Output ""

$clearedCount = 0
$errorCount = 0

foreach ($path in $allPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Output "Cleared: $path"
            $clearedCount++
        }
        catch {
            Write-Output "Failed to clear: $path - $_"
            $errorCount++
        }
    }
    else {
        Write-Output "Not found: $path"
    }
}


# Summary
Write-Output ""
Write-Output "Summary"
Write-Output "======="
Write-Output "Cache directories cleared: $clearedCount"
if ($errorCount -gt 0) {
    Write-Output "Errors encountered: $errorCount"
}

Write-Output ""
Write-Output "Teams cache cleanup completed"
Write-Output "Please restart Microsoft Teams manually"
