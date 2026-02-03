<#
.SYNOPSIS
    NinjaRMM Script 5: File Server Monitor

.DESCRIPTION
    Monitors file server shares, open files, and shadow copy status.
    Tracks SMB share health and storage utilization.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - fsShareCount (Integer)
    - fsOpenFiles (Integer)
    - fsShadowCopyEnabled (Checkbox)
    - fsHealthStatus (Text)
    
    Framework Version: 4.0
    Last Updated: February 3, 2026
#>

param()

try {
    # Check if File Server role is installed
    $fsRole = Get-WindowsFeature -Name FS-FileServer -ErrorAction SilentlyContinue

    if (-not $fsRole -or -not $fsRole.Installed) {
        Ninja-Property-Set fsFileServerInstalled $false
        Write-Output "File Server role not installed"
        exit 0
    }

    Ninja-Property-Set fsFileServerInstalled $true

    # Get SMB shares (excluding default system shares)
    $shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^(ADMIN\$|C\$|IPC\$|print\$)$'
    }

    $shareCount = $shares.Count
    Ninja-Property-Set fsShareCount $shareCount

    # Get open files count
    $openFiles = Get-SmbOpenFile -ErrorAction SilentlyContinue
    $openFileCount = if ($openFiles) { $openFiles.Count } else { 0 }

    Ninja-Property-Set fsOpenFiles $openFileCount

    # Check Shadow Copy status on system drive
    $shadowCopyEnabled = $false
    try {
        $vssadmin = vssadmin list shadows /for=C: 2>&1
        if ($vssadmin -match "Shadow Copy Volume") {
            $shadowCopyEnabled = $true
        }
    } catch {
        $shadowCopyEnabled = $false
    }

    Ninja-Property-Set fsShadowCopyEnabled $shadowCopyEnabled

    # Determine health status
    if ($shareCount -gt 0 -and $shadowCopyEnabled) {
        $health = "Healthy"
    } elseif ($shareCount -gt 0) {
        $health = "Warning"
    } else {
        $health = "Unknown"
    }

    Ninja-Property-Set fsHealthStatus $health

    Write-Output "File Server Health: $health | Shares: $shareCount | Open Files: $openFileCount | Shadow Copy: $shadowCopyEnabled"

} catch {
    Write-Output "Error: $_"
    Ninja-Property-Set fsHealthStatus "Unknown"
    exit 1
}
