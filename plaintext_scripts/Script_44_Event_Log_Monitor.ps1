<#
.SYNOPSIS
    Event Log Monitor - Windows Event Log Error and Warning Detection

.DESCRIPTION
    Monitors Windows Event Logs for critical errors, warnings, security events, and full logs.
    Identifies top error sources and provides HTML summary dashboard. Essential for proactive
    issue detection and system health monitoring across Application, System, and Security logs.
    
    Critical for detecting system errors before they cause outages, identifying security events
    requiring investigation, and preventing event log corruption from full logs. Foundational
    for Windows system administration and troubleshooting.
    
    Monitoring Scope:
    
    Event Log Enumeration:
    - Queries all available event logs via Get-WinEvent -ListLog
    - Filters logs with non-zero record counts
    - Focuses on key logs: Application, System, Security
    
    Full Log Detection:
    - Identifies logs where IsLogFull = true
    - Full logs stop recording new events
    - Critical issue requiring immediate action
    - Tracks count of full logs
    
    Critical Error Counting (24h):
    - Queries Application and System logs
    - Filters Level 1 (Critical) events
    - Time window: Last 24 hours
    - High counts indicate system instability
    
    Warning Event Counting (24h):
    - Queries Application and System logs
    - Filters Level 3 (Warning) events
    - Time window: Last 24 hours
    - Trending warnings predict future failures
    
    Security Event Monitoring (24h):
    - Queries Security log only
    - Filters Level 1 (Critical) and 2 (Error)
    - Detects authentication failures, privilege escalation
    - Security incident early warning
    
    Top Error Source Analysis:
    - Groups errors by ProviderName (event source)
    - Samples last 1000 error events
    - Identifies noisiest error source
    - Critical for targeted troubleshooting
    
    Event Log Summary Table:
    - HTML formatted table for key logs
    - Includes record count, max size, full status
    - Recent error count per log (24h)
    - Color-coded full status: red (full), green (ok)
    - Dashboard visualization in WYSIWYG field
    
    Health Status Classification:
    
    Healthy:
    - No full event logs
    - Low error rates (<100 critical/24h)
    - Normal security event activity (<50/24h)
    
    Warning:
    - High error rate (>100 critical/24h)
    - High security event activity (>50/24h)
    - Attention needed
    
    Critical:
    - One or more event logs full
    - Events not being recorded
    - Data loss risk
    
    Unknown:
    - Script execution error
    - Event log service unavailable

.NOTES
    Frequency: Daily (full scan), Every 4 hours (recent events)
    Runtime: ~40 seconds
    Timeout: 120 seconds
    Context: SYSTEM
    
    Fields Updated:
    - EVTEventLogFullCount (Integer: number of full logs)
    - EVTCriticalErrors24h (Integer: critical events in 24h)
    - EVTWarnings24h (Integer: warning events in 24h)
    - EVTSecurityEvents24h (Integer: security errors in 24h)
    - EVTTopErrorSource (Text: noisiest event source with count)
    - EVTEventLogSummary (WYSIWYG: HTML formatted log table)
    - EVTHealthStatus (Text: Healthy, Warning, Critical, Unknown)
    
    Dependencies:
    - Windows Event Log service (EventLog)
    - Get-WinEvent cmdlet (Windows Vista+)
    - Event log read permissions
    
    Monitored Logs:
    - Application: Application and service errors
    - System: Windows system component errors
    - Security: Authentication, authorization, audit events
    
    Event Levels:
    - Level 1: Critical (system failures)
    - Level 2: Error (significant problems)
    - Level 3: Warning (potential future problems)
    - Level 4: Information (informational messages)
    - Level 5: Verbose (detailed tracing)
    
    Common Error Sources:
    - Application Hang (kernel hangs)
    - Application Error (crash dumps)
    - Microsoft-Windows-DistributedCOM (DCOM issues)
    - Disk (storage errors)
    - Service Control Manager (service failures)
    
    Full Event Log Causes:
    - Log size limit reached
    - "Overwrite as needed" disabled
    - Rapid event generation (errors/loops)
    - Insufficient disk space
    
    Common Issues:
    - Access denied: Run as administrator
    - Event log service stopped: Start EventLog service
    - High query time: Reduce time window or event count
    - Missing events: Logs cleared or rotated
    
    Framework Version: 4.0
    Last Updated: February 5, 2026
#>

[CmdletBinding()]
param()

try {
    Write-Output "Starting Event Log Monitor (v4.0)..."
    $ErrorActionPreference = 'Stop'
    
    $fullLogCount = 0
    $criticalErrors24h = 0
    $warnings24h = 0
    $securityEvents24h = 0
    $topErrorSource = "None"
    $eventLogSummary = ""
    $healthStatus = "Healthy"
    
    $startTime = (Get-Date).AddHours(-24)
    
    Write-Output "INFO: Scanning event logs..."
    $eventLogs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | 
        Where-Object { $_.RecordCount -gt 0 }
    
    Write-Output "INFO: Checking for full event logs..."
    $fullLogs = $eventLogs | Where-Object { $_.IsLogFull -eq $true }
    $fullLogCount = $fullLogs.Count
    
    if ($fullLogCount -gt 0) {
        Write-Output "WARNING: Found $fullLogCount full event log(s): $($fullLogs.LogName -join ', ')"
    } else {
        Write-Output "INFO: No full event logs detected"
    }
    
    Write-Output "INFO: Counting critical errors (24h)..."
    try {
        $criticalEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 1
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $criticalErrors24h = if ($criticalEvents) { $criticalEvents.Count } else { 0 }
        Write-Output "INFO: Critical errors: $criticalErrors24h"
    } catch {
        Write-Output "WARNING: Failed to count critical errors: $_"
    }
    
    Write-Output "INFO: Counting warnings (24h)..."
    try {
        $warningEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 3
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $warnings24h = if ($warningEvents) { $warningEvents.Count } else { 0 }
        Write-Output "INFO: Warnings: $warnings24h"
    } catch {
        Write-Output "WARNING: Failed to count warnings: $_"
    }
    
    Write-Output "INFO: Counting security events (24h)..."
    try {
        $secEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            Level = 1,2
            StartTime = $startTime
        } -ErrorAction SilentlyContinue
        
        $securityEvents24h = if ($secEvents) { $secEvents.Count } else { 0 }
        Write-Output "INFO: Security events: $securityEvents24h"
    } catch {
        Write-Output "WARNING: Failed to count security events: $_"
    }
    
    Write-Output "INFO: Identifying top error source..."
    try {
        $allErrors = Get-WinEvent -FilterHashtable @{
            LogName = 'Application', 'System'
            Level = 1,2
            StartTime = $startTime
        } -MaxEvents 1000 -ErrorAction SilentlyContinue
        
        if ($allErrors -and $allErrors.Count -gt 0) {
            $topSource = $allErrors | Group-Object -Property ProviderName | 
                Sort-Object -Property Count -Descending | 
                Select-Object -First 1
            
            if ($topSource) {
                $topErrorSource = "$($topSource.Name) ($($topSource.Count) errors)"
                Write-Output "INFO: Top error source: $topErrorSource"
            }
        } else {
            $topErrorSource = "None"
        }
    } catch {
        Write-Output "WARNING: Failed to identify top error source: $_"
        $topErrorSource = "Unable to determine"
    }
    
    Write-Output "INFO: Building event log summary..."
    $htmlRows = @()
    
    $keyLogs = @('Application', 'System', 'Security')
    foreach ($logName in $keyLogs) {
        try {
            $log = Get-WinEvent -ListLog $logName -ErrorAction Stop
            
            $recordCount = $log.RecordCount
            $maxSize = [Math]::Round($log.MaximumSizeInBytes / 1MB, 1)
            $isFull = if ($log.IsLogFull) { "Yes" } else { "No" }
            $fullColor = if ($log.IsLogFull) { "red" } else { "green" }
            
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
            Write-Output "WARNING: Failed to get info for $logName log: $_"
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
    
    Write-Output "INFO: Determining health status..."
    if ($fullLogCount -gt 0) {
        $healthStatus = "Critical"
        Write-Output "  ASSESSMENT: Critical - Full event logs detected"
    } elseif ($criticalErrors24h -gt 100 -or $securityEvents24h -gt 50) {
        $healthStatus = "Warning"
        Write-Output "  ASSESSMENT: Warning - High error count"
    } else {
        $healthStatus = "Healthy"
        Write-Output "  ASSESSMENT: Event logs healthy"
    }
    
    Write-Output "INFO: Updating NinjaRMM custom fields..."
    
    Ninja-Property-Set evtEventLogFullCount $fullLogCount
    Ninja-Property-Set evtCriticalErrors24h $criticalErrors24h
    Ninja-Property-Set evtWarnings24h $warnings24h
    Ninja-Property-Set evtSecurityEvents24h $securityEvents24h
    Ninja-Property-Set evtTopErrorSource $topErrorSource
    Ninja-Property-Set evtEventLogSummary $eventLogSummary
    Ninja-Property-Set evtHealthStatus $healthStatus
    
    Write-Output "SUCCESS: Event Log monitoring complete"
    Write-Output "EVENT LOG METRICS:"
    Write-Output "  - Health Status: $healthStatus"
    Write-Output "  - Full Logs: $fullLogCount"
    Write-Output "  - Critical Errors (24h): $criticalErrors24h"
    Write-Output "  - Warnings (24h): $warnings24h"
    Write-Output "  - Security Events (24h): $securityEvents24h"
    Write-Output "  - Top Error Source: $topErrorSource"
    
    exit 0
    
} catch {
    $errorMessage = $_.Exception.Message
    Write-Output "ERROR: Event Log Monitor failed: $errorMessage"
    Write-Output "$($_.ScriptStackTrace)"
    
    Ninja-Property-Set evtHealthStatus "Unknown"
    Ninja-Property-Set evtEventLogSummary "Monitor script error: $errorMessage"
    
    exit 1
}
