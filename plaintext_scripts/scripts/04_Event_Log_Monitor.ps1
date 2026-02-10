<#
.SYNOPSIS
    NinjaRMM Script 4: Event Log Monitor

.DESCRIPTION
    Monitors critical Windows Event Log entries for errors and warnings.
    Tracks application crashes, service failures, and system errors.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - evtCriticalErrors24h (Integer)
    - evtApplicationErrors24h (Integer)
    - evtServiceFailures24h (Integer)
    - evtLastCheckTime (DateTime)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    Write-Output "Starting Event Log Monitor"

    $startTime = (Get-Date).AddHours(-24)

    # Count critical errors in System log
    $criticalErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level = 1  # Critical
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $criticalCount = if ($criticalErrors) { $criticalErrors.Count } else { 0 }

    # Count application errors
    $appErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        Level = 2  # Error
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $appErrorCount = if ($appErrors) { $appErrors.Count } else { 0 }

    # Count service failures (Event ID 7034, 7031)
    $serviceFailures = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 7034, 7031
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $serviceFailureCount = if ($serviceFailures) { $serviceFailures.Count } else { 0 }

    # Update custom fields
    Ninja-Property-Set evtCriticalErrors24h $criticalCount
    Ninja-Property-Set evtApplicationErrors24h $appErrorCount
    Ninja-Property-Set evtServiceFailures24h $serviceFailureCount
    Ninja-Property-Set evtLastCheckTime (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Critical=$criticalCount | App Errors=$appErrorCount | Service Failures=$serviceFailureCount"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
