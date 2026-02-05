<#
.SYNOPSIS
    File Server Monitor - SMB Share and Connection Monitoring

.DESCRIPTION
    Monitors Windows File Server infrastructure with focus on SMB share availability and active
    user sessions. Tracks share configuration and concurrent user connections for capacity
    planning and performance monitoring.
    
    Alternative implementation to 05_File_Server_Monitor.ps1 with different field names and
    session-based connection tracking instead of open file handles.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - fileServerInstalled (Checkbox)
    - fileShareCount (Integer)
    - fileActiveConnections (Integer: SMB sessions)
    - fileHealthStatus (Dropdown: Healthy, Warning, Unknown)
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

param()

try {
    Write-Output "Starting File Server Monitor (v4.0 - Script 15)..."

    Write-Output "INFO: Checking for File Server role..."
    $fileRole = Get-WindowsFeature -Name FS-FileServer -ErrorAction SilentlyContinue

    if (-not $fileRole -or -not $fileRole.Installed) {
        Write-Output "INFO: File Server role not installed"
        Ninja-Property-Set fileServerInstalled $false
        exit 0
    }

    Write-Output "INFO: File Server role detected"
    Ninja-Property-Set fileServerInstalled $true

    Write-Output "INFO: Enumerating SMB shares..."
    $shares = Get-SmbShare | Where-Object { $_.Name -notmatch '^[A-Z]\$|^ADMIN\$|^IPC\$' }
    $shareCount = $shares.Count

    Write-Output "INFO: Found $shareCount share(s)"
    Ninja-Property-Set fileShareCount $shareCount

    Write-Output "INFO: Checking active SMB sessions..."
    $sessions = Get-SmbSession -ErrorAction SilentlyContinue
    $activeConnections = if ($sessions) { $sessions.Count } else { 0 }

    Write-Output "INFO: Active connections: $activeConnections"
    Ninja-Property-Set fileActiveConnections $activeConnections

    if ($shareCount -gt 0) {
        $health = "Healthy"
        Write-Output "  ASSESSMENT: File server operational"
    } else {
        $health = "Warning"
        Write-Output "  ASSESSMENT: No shares configured"
    }

    Ninja-Property-Set fileHealthStatus $health

    Write-Output "SUCCESS: File Server Health: $health | Shares: $shareCount | Connections: $activeConnections"

    exit 0
} catch {
    Write-Output "ERROR: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set fileHealthStatus "Unknown"
    exit 1
}
