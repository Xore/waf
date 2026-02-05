<#
.SYNOPSIS
    File Server Monitor - Windows File Server Share and Activity Monitoring

.DESCRIPTION
    Monitors Windows File Server infrastructure including SMB shares, open files, connected
    users, FSRM quota compliance, and access errors. Essential for file server capacity planning,
    detecting access issues, and ensuring storage quota compliance.
    
    Critical for preventing quota violations that block users, detecting share access problems
    before they impact productivity, and monitoring file server load. Foundational for enterprise
    file storage management and user collaboration infrastructure.
    
    Monitoring Scope:
    
    File Server Role Detection:
    - Checks FS-FileServer Windows feature
    - Verifies SMB PowerShell module availability
    - Gracefully exits if role not installed
    
    SMB Share Inventory:
    - Enumerates all SMB shares via Get-SmbShare
    - Filters out administrative shares (C$, ADMIN$, IPC$)
    - Tracks share count for capacity management
    - Calculates share size (folder tree total) when path accessible
    
    Share Summary Reporting:
    - Generates HTML formatted share table
    - Includes share name, path, calculated size in GB
    - Stores in WYSIWYG field for dashboard visualization
    - Size calculation may be slow for large shares
    
    Open File Monitoring:
    - Queries Get-SmbOpenFile for currently open files
    - Counts active file handles across all shares
    - High counts indicate heavy file server usage
    - Locking/contention detection metric
    
    Connected User Tracking:
    - Queries Get-SmbSession for active SMB sessions
    - Counts unique client usernames
    - User activity and capacity metric
    - Helps identify peak usage patterns
    
    FSRM Quota Monitoring:
    - Checks for FS-Resource-Manager feature
    - Queries Get-FsrmQuota for configured quotas
    - Identifies quotas where Usage > Limit
    - Prevents user storage exhaustion
    - Only available if FSRM installed
    
    Access Error Detection:
    - Queries System event log for SMBServer errors (24h)
    - Provider: Microsoft-Windows-SMBServer
    - Severity: Critical (Level 1) and Error (Level 2)
    - Detects permission issues, share access failures
    - High error rates suggest misconfiguration
    
    Health Status Classification:
    
    Healthy:
    - No quota violations
    - Low error rate (<10/24h)
    - Normal operations
    
    Warning:
    - Quota violations detected (users blocked)
    - Moderate errors (10-50/24h)
    - Action recommended
    
    Critical:
    - High error rate (>50/24h)
    - Widespread access issues
    - Service degraded
    
    Unknown:
    - File Server role not installed
    - Script execution error
    - Query failures

.NOTES
    Frequency: Daily (config), Every 4 hours (usage)
    Runtime: ~35 seconds (may be longer with large shares)
    Timeout: 120 seconds
    Context: SYSTEM
    
    Fields Updated:
    - FSFileServerRole (Checkbox)
    - FSShareCount (Integer: non-administrative shares)
    - FSShareSummary (WYSIWYG: HTML formatted share table)
    - FSOpenFilesCount (Integer: currently open file handles)
    - FSConnectedUsers (Integer: unique active SMB sessions)
    - FSQuotaViolations (Integer: quotas exceeding limit)
    - FSAccessErrors24h (Integer: SMB errors in 24h)
    - FSHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - FS-FileServer Windows feature
    - SMB PowerShell module (SmbShare)
    - Optional: FS-Resource-Manager for quota monitoring
    - Administrator privileges
    - Event log read access
    
    Share Size Calculation:
    - Recursive folder tree enumeration
    - May be slow for shares with millions of files
    - Uses Get-ChildItem -Recurse -File
    - Requires read access to share path
    
    FSRM Integration:
    - File Server Resource Manager (FSRM) required for quotas
    - Get-FsrmQuota cmdlet checks quota compliance
    - Quota violations prevent users from writing files
    
    Event Log Sources:
    - Provider: Microsoft-Windows-SMBServer
    - LogName: System
    - Access denied, share failures, protocol errors
    
    Common Issues:
    - Slow execution: Large shares with many files (size calculation)
    - Access denied: SYSTEM account needs share path read access
    - Quota not available: FSRM not installed
    - No sessions: Normal if no users currently connected
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting File Server Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $fileServerRole = $false
    $shareCount = 0
    $shareSummary = ""
    $openFilesCount = 0
    $connectedUsers = 0
    $quotaViolations = 0
    $accessErrors24h = 0
    $healthStatus = "Unknown"
    
    Write-Output "INFO: Checking for File Server role..."
    $fsRole = Get-WindowsFeature -Name "FS-FileServer" -ErrorAction SilentlyContinue
    
    if ($null -eq $fsRole -or -not $fsRole.Installed) {
        Write-Output "INFO: File Server role not installed"
        
        Ninja-Property-Set fsFileServerRole $false
        Ninja-Property-Set fsShareCount 0
        Ninja-Property-Set fsShareSummary "File Server role not installed"
        Ninja-Property-Set fsOpenFilesCount 0
        Ninja-Property-Set fsConnectedUsers 0
        Ninja-Property-Set fsQuotaViolations 0
        Ninja-Property-Set fsAccessErrors24h 0
        Ninja-Property-Set fsHealthStatus "Unknown"
        
        Write-Output "SUCCESS: File Server monitoring skipped (role not installed)"
        exit 0
    }
    
    $fileServerRole = $true
    Write-Output "INFO: File Server role detected"
    
    Write-Output "INFO: Enumerating SMB shares..."
    try {
        $shares = Get-SmbShare | Where-Object { $_.Special -eq $false }
        $shareCount = $shares.Count
        Write-Output "INFO: Shares found: $shareCount"
        
        if ($shareCount -gt 0) {
            $htmlRows = @()
            foreach ($share in $shares) {
                $sharePath = $share.Path
                $shareType = $share.ShareType
                
                Write-Output "  Share: $($share.Name) -> $sharePath"
                
                $shareSize = "N/A"
                if ($sharePath -and (Test-Path $sharePath)) {
                    try {
                        $folderSize = (Get-ChildItem -Path $sharePath -Recurse -File -ErrorAction SilentlyContinue | 
                            Measure-Object -Property Length -Sum).Sum
                        $shareSizeGB = [Math]::Round($folderSize / 1GB, 2)
                        $shareSize = "$shareSizeGB GB"
                        Write-Output "    Size: $shareSize"
                    } catch {
                        $shareSize = "Unknown"
                        Write-Output "    Size: Unknown (access denied or error)"
                    }
                }
                
                $htmlRows += "<tr><td>$($share.Name)</td><td>$sharePath</td><td>$shareSize</td></tr>"
            }
            
            $shareSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'><th>Share Name</th><th>Path</th><th>Size</th></tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; color:#666; margin-top:10px;'>Total Shares: $shareCount</p>
"@
        } else {
            $shareSummary = "No file shares configured"
        }
    } catch {
        Write-Output "WARNING: Failed to enumerate shares: $_"
        $shareSummary = "Unable to retrieve share information"
    }
    
    Write-Output "INFO: Counting open files..."
    try {
        $openFiles = Get-SmbOpenFile -ErrorAction SilentlyContinue
        $openFilesCount = if ($openFiles) { $openFiles.Count } else { 0 }
        Write-Output "INFO: Open files: $openFilesCount"
    } catch {
        Write-Output "WARNING: Failed to get open files count: $_"
    }
    
    Write-Output "INFO: Counting connected users..."
    try {
        $sessions = Get-SmbSession -ErrorAction SilentlyContinue
        $connectedUsers = if ($sessions) { ($sessions | Select-Object -Unique -Property ClientUserName).Count } else { 0 }
        Write-Output "INFO: Connected users: $connectedUsers"
    } catch {
        Write-Output "WARNING: Failed to get connected users count: $_"
    }
    
    Write-Output "INFO: Checking FSRM quota violations..."
    try {
        $fsrmFeature = Get-WindowsFeature -Name "FS-Resource-Manager" -ErrorAction SilentlyContinue
        
        if ($fsrmFeature -and $fsrmFeature.Installed) {
            $quotas = Get-FsrmQuota -ErrorAction SilentlyContinue
            
            if ($quotas) {
                $quotaViolations = ($quotas | Where-Object { $_.Usage -gt $_.Limit }).Count
                Write-Output "INFO: Quota violations: $quotaViolations"
            } else {
                Write-Output "INFO: No quotas configured"
            }
        } else {
            Write-Output "INFO: FSRM not installed (quota monitoring unavailable)"
        }
    } catch {
        Write-Output "WARNING: Failed to check quota violations: $_"
    }
    
    Write-Output "INFO: Checking SMB access errors (24h)..."
    try {
        $startTime = (Get-Date).AddHours(-24)
        $fsErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Microsoft-Windows-SMBServer'
            Level = 1,2
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $accessErrors24h = if ($fsErrors) { $fsErrors.Count } else { 0 }
        Write-Output "INFO: Access errors (24h): $accessErrors24h"
    } catch {
        Write-Output "WARNING: Failed to check access errors: $_"
    }
    
    Write-Output "INFO: Determining health status..."
    if ($accessErrors24h -gt 50) {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Critical - High error rate (>50/24h)"
    } elseif ($quotaViolations -gt 0 -or $accessErrors24h -gt 10) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - Quota violations or elevated errors"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: File server healthy"
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set fsFileServerRole $true
    Ninja-Property-Set fsShareCount $shareCount
    Ninja-Property-Set fsShareSummary $shareSummary
    Ninja-Property-Set fsOpenFilesCount $openFilesCount
    Ninja-Property-Set fsConnectedUsers $connectedUsers
    Ninja-Property-Set fsQuotaViolations $quotaViolations
    Ninja-Property-Set fsAccessErrors24h $accessErrors24h
    Ninja-Property-Set fsHealthStatus $healthStatus
    
    Write-Output "SUCCESS: File Server monitoring complete"
    Write-Output "FILE SERVER METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Shares: $shareCount"
    Write-Output "  - Open Files: $openFilesCount"
    Write-Output "  - Connected Users: $connectedUsers"
    Write-Output "  - Quota Violations: $quotaViolations"
    Write-Output "  - Access Errors (24h): $accessErrors24h"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: File Server Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set fsFileServerRole $false
    Ninja-Property-Set fsHealthStatus "Unknown"
    Ninja-Property-Set fsShareSummary "Monitor script error: $errorMessage"
    
    exit 1
}
