<#
.SYNOPSIS
    Script 44: Event Log Monitor
    NinjaRMM Custom Field Framework v3.0

.DESCRIPTION
    Monitors Windows Event Logs for critical errors, warnings, security events, full logs,
    and identifies top error sources. Updates 7 EVT fields with HTML summary.

.FIELDS UPDATED
    - EVTEventLogFullCount (Integer)
    - EVTCriticalErrors24h (Integer)
    - EVTWarnings24h (Integer)
    - EVTSecurityEvents24h (Integer)
    - EVTTopErrorSource (Text)
    - EVTEventLogSummary (WYSIWYG)
    - EVTHealthStatus (Dropdown)

.EXECUTION
    Frequency: Daily (full scan), Every 4 hours (recent events)
    Runtime: ~40 seconds
    Requires: Event log read permissions

.NOTES
    File: Script_44_Event_Log_Monitor.ps1
    Author: Windows Automation Framework
    Version: 1.0
    Created: February 3, 2026
    Category: Server Role Monitoring
    Dependencies: Windows Event Log service

.RELATED DOCUMENTATION
    - docs/core/16_ROLE_Additional.md
    - docs/ACTION_PLAN_Missing_Scripts.md (Phase 4)
#>

[CmdletBinding()]
param()

try {
    Write-Host "Starting Event Log Monitor (Script 44)..."
    $ErrorActionPreference = 'Stop'
    
    # Initialize variables
    $fullLogCount = 0
    $criticalErrors24h = 0
    $warnings24h = 0
    $securityEvents24h = 0
    $topErrorSource = "None"
    $eventLogSummary = ""
    $healthStatus = "Healthy"
    
    # Define time range (last 24 hours)
    $startTime = (Get-Date).AddHours(-24)
    
    # Get list of event logs
    Write-Host "Scanning event logs..."
    $eventLogs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | 
        Where-Object { $_.RecordCount -gt 0 }
    
    # Check for full event logs
    Write-Host "Checking for full event logs..."
    $fullLogs = $eventLogs | Where-Object { $_.IsLogFull -eq $true }
    $fullLogCount = $fullLogs.Count
    
    if ($fullLogCount -gt 0) {
        Write-Warning "Found $fullLogCount full event log(s): $($fullLogs.LogName -join ', ')"
    } else {
        Write-Host "No full event logs detected."
    }
    
    # Get critical errors from last 24 hours
    Write-Host "Counting critical errors (24h)..."
    try {
        $criticalEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 1  # Critical
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $criticalErrors24h = if ($criticalEvents) { $criticalEvents.Count } else { 0 }
        Write-Host "Critical Errors: $criticalErrors24h"
    } catch {
        Write-Warning "Failed to count critical errors: $_"
    }
    
    # Get warnings from last 24 hours
    Write-Host "Counting warnings (24h)..."
    try {
        $warningEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 3  # Warning
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $warnings24h = if ($warningEvents) { $warningEvents.Count } else { 0 }
        Write-Host "Warnings: $warnings24h"
    } catch {
        Write-Warning "Failed to count warnings: $_"
    }
    
    # Get security events from last 24 hours
    Write-Host "Counting security events (24h)..."
    try {
        $secEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $securityEvents24h = if ($secEvents) { $secEvents.Count } else { 0 }
        Write-Host "Security Events: $securityEvents24h"
    } catch {
        Write-Warning "Failed to count security events: $_"
    }
    
    # Identify top error source
    Write-Host "Identifying top error source..."
    try {
        $allErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 1,2  # Critical and Error
            StartTime = $startTime
        } -MaxEvents 1000 -ErrorAction SilentlyContinue
        
        if ($allErrors -and $allErrors.Count -gt 0) {
            $topSource = $allErrors | Group-Object -Property ProviderName | 
                Sort-Object -Property Count -Descending | 
                Select-Object -First 1
            
            if ($topSource) {
                $topErrorSource = "$($topSource.Name) ($($topSource.Count) errors)"
                Write-Host "Top Error Source: $topErrorSource"
            }
        } else {
            $topErrorSource = "None"
        }
    } catch {
        Write-Warning "Failed to identify top error source: $_"
        $topErrorSource = "Unable to determine"
    }
    
    # Build event log summary HTML
    Write-Host "Building event log summary..."
    $htmlRows = @()
    
    # Summary of key logs
    $keyLogs = @('Application', 'System', 'Security')
    foreach ($logName in $keyLogs) {
        try {
            $log = Get-WinEvent -ListLog $logName -ErrorAction Stop
            
            $recordCount = $log.RecordCount
            $maxSize = [Math]::Round($log.MaximumSizeInBytes / 1MB, 1)
            $isFull = if ($log.IsLogFull) { "Yes" } else { "No" }
            $fullColor = if ($log.IsLogFull) { "red" } else { "green" }
            
            # Get recent error count for this log
            $recentErrors = 0
            try {
                $logErrors = Get-WinEvent -FilterHashtable @{
                    LogName = $logName
                    Level = 1,2
                    StartTime = $startTime
                } -ErrorAction SilentlyContinue
                $recentErrors = if ($logErrors) { $logErrors.Count } else { 0 }
            } catch {
                $recentErrors = 0
            }
            
            $htmlRows += "<tr><td>$logName</td><td>$recordCount</td><td>$maxSize MB</td><td style='color:$fullColor'>$isFull</td><td>$recentErrors</td></tr>"
        } catch {
            Write-Warning "Failed to get info for $logName log: $_"
        }
    }
    
    $eventLogSummary = @"
<table border='1' style='border-collapse:collapse; width:100%; font-family:Arial,sans-serif;'>
<tr style='background-color:#f0f0f0;'>
    <th>Log Name</th>
    <th>Records</th>
    <th>Max Size</th>
    <th>Full</th>
    <th>Errors (24h)</th>
</tr>
$($htmlRows -join "`n")
</table>
<p style='font-size:0.9em; margin-top:10px;'>
<strong>Summary (24h):</strong><br/>
Critical: $criticalErrors24h | Warnings: $warnings24h | Security: $securityEvents24h<br/>
<strong>Top Error Source:</strong> $topErrorSource
</p>
"@
    
    # Determine health status
    if ($fullLogCount -gt 0) {
        $healthStatus = "Critical"
        Write-Host "Health Status: Critical (full logs detected)"
    } elseif ($criticalErrors24h -gt 100 -or $securityEvents24h -gt 50) {
        $healthStatus = "Warning"
        Write-Host "Health Status: Warning (high error count)"
    } else {
        $healthStatus = "Healthy"
        Write-Host "Health Status: Healthy"
    }
    
    # Update NinjaRMM custom fields
    Write-Host "Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set evtEventLogFullCount $fullLogCount
    Ninja-Property-Set evtCriticalErrors24h $criticalErrors24h
    Ninja-Property-Set evtWarnings24h $warnings24h
    Ninja-Property-Set evtSecurityEvents24h $securityEvents24h
    Ninja-Property-Set evtTopErrorSource $topErrorSource
    Ninja-Property-Set evtEventLogSummary $eventLogSummary
    Ninja-Property-Set evtHealthStatus $healthStatus
    
    Write-Host "Event Log Monitor complete. Status: $healthStatus"
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Event Log Monitor failed: $errorMessage"
    
    # Set error state in fields
    Ninja-Property-Set evtHealthStatus "Unknown"
    Ninja-Property-Set evtEventLogSummary "Monitor script error: $errorMessage"
    
    exit 1
}
