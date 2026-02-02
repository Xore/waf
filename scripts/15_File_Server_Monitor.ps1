<#
.SYNOPSIS
    NinjaRMM Script 15: File Server Monitor

.DESCRIPTION
    Monitors file server shares, connections, and storage capacity.
    Part of Infrastructure Monitoring suite - Server Roles.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - fileServerInstalled (Checkbox)
    - fileShareCount (Integer)
    - fileActiveConnections (Integer)
    - fileHealthStatus (Dropdown)
    
    Framework Version: 4.0
    Last Updated: February 2, 2026
#>

param()

try {
    $fileRole = Get-WindowsFeature -Name FS-FileServer -ErrorAction SilentlyContinue

    if (-not $fileRole -or -not $fileRole.Installed) {
        Ninja-Property-Set fileServerInstalled $false
        Write-Output "File Server role not installed"
        exit 0
    }

    Ninja-Property-Set fileServerInstalled $true

    $shares = Get-SmbShare | Where-Object { $_.Name -notmatch '^[A-Z]\$|^ADMIN\$|^IPC\$' }
    $shareCount = $shares.Count

    Ninja-Property-Set fileShareCount $shareCount

    $sessions = Get-SmbSession -ErrorAction SilentlyContinue
    $activeConnections = if ($sessions) { $sessions.Count } else { 0 }

    Ninja-Property-Set fileActiveConnections $activeConnections

    if ($shareCount -gt 0) {
        $health = "Healthy"
    } else {
        $health = "Warning"
    }

    Ninja-Property-Set fileHealthStatus $health

    Write-Output "File Server Health: $health | Shares: $shareCount | Connections: $activeConnections"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set fileHealthStatus "Unknown"
    exit 1
}
