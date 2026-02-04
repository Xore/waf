<#
.SYNOPSIS
    Telemetry Collector - System Stability and Reliability Metrics

.DESCRIPTION
    Collects custom reliability telemetry not available through native monitoring including
    application crashes, application hangs, service failures, blue screen events (BSODs), and
    system uptime metrics. Provides stability trending and early warning indicators for
    system reliability issues.
    
    Analyzes Windows event logs across multiple time windows (24 hours for recent issues, 30 days
    for BSOD trends) to identify patterns of instability that may indicate hardware failures,
    driver issues, or application compatibility problems.
    
    Telemetry Metrics Collected:
    
    Application Crashes (24-hour window):
    - Event IDs: 1000, 1001 (Application Error events)
    - Indicates: Application stability issues, compatibility problems
    - Threshold guidance: >5 crashes may indicate systemic issues
    
    Application Hangs (24-hour window):
    - Event ID: 1002 (Application Hang events)
    - Indicates: Resource contention, deadlocks, performance issues
    - Threshold guidance: >3 hangs may indicate resource problems
    
    Service Failures (24-hour window):
    - Event IDs: 7031, 7034 (Service crash and unexpected termination)
    - Indicates: Service instability, dependencies missing
    - Threshold guidance: >2 failures may indicate configuration issues
    
    Blue Screen Events (30-day window):
    - Event IDs: 1001, 41 (BugCheck, unexpected shutdown)
    - Indicates: Critical system failures, driver/hardware issues
    - Threshold guidance: >0 requires immediate investigation
    
    System Uptime:
    - Calculates days since last boot
    - Indicates: Reboot frequency, patch application
    - Threshold guidance: >90 days may indicate missing patches

.NOTES
    Frequency: Every 4 hours
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - STATAppCrashes24h (Integer: application crash count in last 24 hours)
    - STATAppHangs24h (Integer: application hang count in last 24 hours)
    - STATServiceFailures24h (Integer: service failure count in last 24 hours)
    - STATBSODCount30d (Integer: blue screen count in last 30 days)
    - STATUptimeDays (Integer: days since last boot)
    - STATLastTelemetryUpdate (Text: timestamp in yyyy-MM-dd HH:mm:ss format)
    
    Dependencies:
    - Windows Event Logs: Application, System
    - WMI/CIM: Win32_OperatingSystem
    
    Use Cases:
    - Proactive hardware failure detection
    - Application compatibility monitoring
    - Service health tracking
    - Patch compliance verification (uptime)
    - Reliability trending and reporting
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Telemetry Collector (v4.0)..."

    # Define time windows for telemetry collection
    $startTime24h = (Get-Date).AddHours(-24)
    $startTime30d = (Get-Date).AddDays(-30)
    Write-Output "INFO: Collection windows - Recent: last 24h, Historical: last 30d"

    # Collect Application Crashes (24 hours)
    Write-Output "INFO: Collecting application crash events (Event IDs 1000, 1001)..."
    $appCrashes = 0
    try {
        $appCrashes = (Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Id = 1000, 1001
            StartTime = $startTime24h
        } -ErrorAction SilentlyContinue | Measure-Object).Count
        
        if ($appCrashes -gt 0) {
            Write-Output "WARNING: Detected $appCrashes application crash(es) in last 24 hours"
        } else {
            Write-Output "INFO: No application crashes detected in last 24 hours"
        }
    } catch {
        Write-Output "WARNING: Unable to query application crash events"
        $appCrashes = 0
    }

    # Collect Application Hangs (24 hours)
    Write-Output "INFO: Collecting application hang events (Event ID 1002)..."
    $appHangs = 0
    try {
        $appHangs = (Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Id = 1002
            StartTime = $startTime24h
        } -ErrorAction SilentlyContinue | Measure-Object).Count
        
        if ($appHangs -gt 0) {
            Write-Output "WARNING: Detected $appHangs application hang(s) in last 24 hours"
        } else {
            Write-Output "INFO: No application hangs detected in last 24 hours"
        }
    } catch {
        Write-Output "WARNING: Unable to query application hang events"
        $appHangs = 0
    }

    # Collect Service Failures (24 hours)
    Write-Output "INFO: Collecting service failure events (Event IDs 7031, 7034)..."
    $serviceFailures = 0
    try {
        $serviceFailures = (Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Id = 7031, 7034
            StartTime = $startTime24h
        } -ErrorAction SilentlyContinue | Measure-Object).Count
        
        if ($serviceFailures -gt 0) {
            Write-Output "WARNING: Detected $serviceFailures service failure(s) in last 24 hours"
        } else {
            Write-Output "INFO: No service failures detected in last 24 hours"
        }
    } catch {
        Write-Output "WARNING: Unable to query service failure events"
        $serviceFailures = 0
    }

    # Collect Blue Screen Events (30 days)
    Write-Output "INFO: Collecting BSOD events (Event IDs 1001, 41)..."
    $bsodCount = 0
    try {
        $bsodEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Id = 1001, 41
            StartTime = $startTime30d
        } -ErrorAction SilentlyContinue | Where-Object { 
            $_.Message -match 'bugcheck|Blue Screen|unexpected shutdown' 
        }
        
        $bsodCount = ($bsodEvents | Measure-Object).Count
        
        if ($bsodCount -gt 0) {
            Write-Output "CRITICAL: Detected $bsodCount blue screen event(s) in last 30 days"
        } else {
            Write-Output "INFO: No blue screen events detected in last 30 days"
        }
    } catch {
        Write-Output "WARNING: Unable to query BSOD events"
        $bsodCount = 0
    }

    # Calculate System Uptime
    Write-Output "INFO: Calculating system uptime..."
    $os = Get-CimInstance Win32_OperatingSystem
    $uptimeDays = [int]((Get-Date) - $os.LastBootUpTime).Days
    $lastBoot = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
    
    Write-Output "INFO: System last booted: $lastBoot ($uptimeDays days ago)"
    if ($uptimeDays -gt 90) {
        Write-Output "WARNING: Uptime exceeds 90 days - patches may be pending installation"
    }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating telemetry fields..."
    Ninja-Property-Set STATAppCrashes24h $appCrashes
    Ninja-Property-Set STATAppHangs24h $appHangs
    Ninja-Property-Set STATServiceFailures24h $serviceFailures
    Ninja-Property-Set STATBSODCount30d $bsodCount
    Ninja-Property-Set STATUptimeDays $uptimeDays
    Ninja-Property-Set STATLastTelemetryUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Telemetry collection complete"
    Write-Output "TELEMETRY SUMMARY:"
    Write-Output "  - Application Crashes (24h): $appCrashes"
    Write-Output "  - Application Hangs (24h): $appHangs"
    Write-Output "  - Service Failures (24h): $serviceFailures"
    Write-Output "  - Blue Screens (30d): $bsodCount"
    Write-Output "  - System Uptime: $uptimeDays days"
    
    # Provide stability assessment
    $totalIssues = $appCrashes + $appHangs + $serviceFailures + $bsodCount
    if ($totalIssues -eq 0) {
        Write-Output "ASSESSMENT: Excellent system stability"
    } elseif ($bsodCount -gt 0) {
        Write-Output "ASSESSMENT: Critical stability issues - BSODs detected"
    } elseif ($totalIssues -gt 10) {
        Write-Output "ASSESSMENT: Poor stability - multiple reliability issues"
    } else {
        Write-Output "ASSESSMENT: Acceptable stability - minor issues detected"
    }

    exit 0
} catch {
    Write-Output "ERROR: Telemetry Collector failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
