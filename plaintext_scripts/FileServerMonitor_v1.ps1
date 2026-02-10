<#
.SYNOPSIS
    File Server Monitor - SMB Share Health and Storage Protection Monitoring

.DESCRIPTION
    Monitors Windows File Server infrastructure including SMB shares, active connections, and
    Volume Shadow Copy (VSS) backup protection. Provides comprehensive file server health
    assessment to ensure data availability, detect access issues, and verify backup readiness.
    
    Critical for environments dependent on centralized file storage, ensuring shares remain
    accessible and protected by shadow copies for point-in-time recovery. Tracks user activity
    and connection patterns to identify performance bottlenecks and capacity constraints.
    
    Monitoring Scope:
    
    File Server Role Detection:
    - Checks for FS-FileServer Windows Feature
    - Gracefully exits if file server role not installed
    - Prevents monitoring overhead on non-file-server systems
    
    SMB Share Inventory:
    - Enumerates all SMB/CIFS shares
    - Excludes system administrative shares:
      * ADMIN$ (remote administration)
      * C$ (administrative drive share)
      * IPC$ (inter-process communication)
      * print$ (printer drivers)
    - Counts user-created data shares only
    - Tracks share availability and configuration
    
    Active User Connections:
    - Monitors open file handles across all shares
    - Counts concurrent user sessions
    - Identifies locked files and active users
    - Performance indicator for file server load
    - Capacity planning metric
    
    Volume Shadow Copy Protection:
    - Verifies VSS is enabled on system drive (C:)
    - Checks for existence of shadow copy snapshots
    - Ensures backup/recovery capability present
    - Critical for ransomware recovery and accidental deletion protection
    
    Health Status Classification:
    
    Healthy:
    - One or more shares configured
    - Shadow Copy enabled and active
    - File server fully operational with backup protection
    
    Warning:
    - Shares present but Shadow Copy disabled
    - Data accessible but not protected
    - Backup vulnerability exists
    - Immediate remediation recommended
    
    Unknown:
    - No shares configured (questionable file server)
    - Script execution error
    - Insufficient permissions
    
    Use Cases:
    - File server availability monitoring
    - User activity and connection tracking
    - Backup protection verification
    - Share configuration auditing
    - Capacity planning (open file trends)
    - Disaster recovery readiness validation

.NOTES
    Frequency: Every 4 hours
    Runtime: ~30 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - fsFileServerInstalled (Checkbox: true if FS-FileServer role installed)
    - fsShareCount (Integer: number of user-created SMB shares)
    - fsOpenFiles (Integer: count of currently open file handles)
    - fsShadowCopyEnabled (Checkbox: true if VSS active on C: drive)
    - fsHealthStatus (Text: Healthy, Warning, Unknown)
    
    Dependencies:
    - Windows File Server role (FS-FileServer feature)
    - SMB PowerShell module (built-in)
    - vssadmin.exe (Volume Shadow Copy Service administration tool)
    - SYSTEM context for share and VSS enumeration
    
    PowerShell Cmdlets Used:
    - Get-WindowsFeature: Role detection
    - Get-SmbShare: Share enumeration
    - Get-SmbOpenFile: Active connection tracking
    
    External Tools:
    - vssadmin list shadows: VSS snapshot detection
    
    Common Issues:
    - Shadow Copy requires sufficient disk space
    - VSS service must be running
    - Share permissions affect enumeration
    - Open file count can spike during backups
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting File Server Monitor (v4.0)..."

    # Detect File Server role installation
    Write-Output "INFO: Checking for File Server role..."
    $fsRole = Get-WindowsFeature -Name FS-FileServer -ErrorAction SilentlyContinue

    if (-not $fsRole -or -not $fsRole.Installed) {
        Write-Output "INFO: File Server role not installed on this system"
        Ninja-Property-Set fsFileServerInstalled $false
        Write-Output "SUCCESS: File server monitoring skipped (role not present)"
        exit 0
    }

    Write-Output "INFO: File Server role detected - beginning monitoring"
    Ninja-Property-Set fsFileServerInstalled $true

    # Enumerate SMB shares (exclude system shares)
    Write-Output "INFO: Enumerating SMB shares..."
    $shares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^(ADMIN\$|C\$|IPC\$|print\$)$'
    }

    $shareCount = $shares.Count
    Write-Output "INFO: Found $shareCount user-created SMB share(s)"
    Ninja-Property-Set fsShareCount $shareCount
    
    if ($shareCount -gt 0) {
        Write-Output "SHARES:"
        $shares | Select-Object -First 10 | ForEach-Object {
            Write-Output "  - $($_.Name): $($_.Path) ($($_.ShareState))"
        }
        if ($shareCount -gt 10) {
            Write-Output "  ... and $($shareCount - 10) more shares"
        }
    }

    # Count open files and active connections
    Write-Output "INFO: Checking active file connections..."
    $openFiles = Get-SmbOpenFile -ErrorAction SilentlyContinue
    $openFileCount = if ($openFiles) { $openFiles.Count } else { 0 }
    
    Write-Output "INFO: Currently open files: $openFileCount"
    Ninja-Property-Set fsOpenFiles $openFileCount
    
    if ($openFileCount -gt 0) {
        # Group by user for activity summary
        $userActivity = $openFiles | Group-Object -Property ClientUserName | Sort-Object Count -Descending | Select-Object -First 5
        Write-Output "TOP USERS BY OPEN FILES:"
        $userActivity | ForEach-Object {
            Write-Output "  - $($_.Name): $($_.Count) open file(s)"
        }
    }

    # Check Volume Shadow Copy (VSS) protection status
    Write-Output "INFO: Checking Volume Shadow Copy (VSS) status..."
    $shadowCopyEnabled = $false
    
    try {
        $vssadmin = vssadmin list shadows /for=C: 2>&1
        $vssOutput = $vssadmin -join "`n"
        
        if ($vssOutput -match "Shadow Copy Volume") {
            $shadowCopyEnabled = $true
            
            # Count shadow copies if possible
            $shadowCopyCount = ([regex]::Matches($vssOutput, "Shadow Copy Volume")).Count
            Write-Output "INFO: Volume Shadow Copy enabled - $shadowCopyCount snapshot(s) found"
        } else {
            Write-Output "WARNING: No Volume Shadow Copy snapshots found for C: drive"
        }
    } catch {
        Write-Output "WARNING: Unable to query Volume Shadow Copy status: $_"
        $shadowCopyEnabled = $false
    }

    Ninja-Property-Set fsShadowCopyEnabled $shadowCopyEnabled

    # Determine overall health status
    Write-Output "INFO: Determining file server health status..."
    if ($shareCount -gt 0 -and $shadowCopyEnabled) {
        $health = "Healthy"
        Write-Output "  ASSESSMENT: File server fully operational with backup protection"
    } elseif ($shareCount -gt 0) {
        $health = "Warning"
        Write-Output "  ASSESSMENT: Shares active but Shadow Copy disabled (backup vulnerability)"
    } else {
        $health = "Unknown"
        Write-Output "  ASSESSMENT: No shares configured (unexpected for file server role)"
    }

    Ninja-Property-Set fsHealthStatus $health

    Write-Output "SUCCESS: File server monitoring complete"
    Write-Output "FILE SERVER METRICS:"
    Write-Output "  - Health Status: $health"
    Write-Output "  - SMB Shares: $shareCount"
    Write-Output "  - Open Files: $openFileCount"
    Write-Output "  - Shadow Copy Enabled: $shadowCopyEnabled"
    
    # Provide recommendations
    if (-not $shadowCopyEnabled) {
        Write-Output "CRITICAL RECOMMENDATION: Enable Volume Shadow Copy for backup protection"
        Write-Output "  - Protects against ransomware and accidental deletions"
        Write-Output "  - Enables file-level recovery without full restoration"
        Write-Output "  - Configure via Computer Management > Shared Folders > All Tasks > Configure Shadow Copies"
    }
    
    if ($openFileCount -gt 100) {
        Write-Output "INFO: High number of open files may indicate heavy usage or locked files"
    }
    
    if ($shareCount -eq 0) {
        Write-Output "WARNING: File Server role installed but no shares configured"
    }

    exit 0
} catch {
    Write-Output "ERROR: File Server Monitor failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    Ninja-Property-Set fsHealthStatus "Unknown"
    exit 1
}
