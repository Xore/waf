<#
.SYNOPSIS
    Stability Analyzer - System and Application Stability Scoring

.DESCRIPTION
    Calculates comprehensive stability score based on system reliability metrics including
    application crashes, application hangs, service failures, blue screen events (BSODs), and
    uptime patterns. Provides quantitative assessment of system stability to identify unreliable
    systems requiring intervention.
    
    Aggregates reliability telemetry from multiple sources (custom fields populated by telemetry
    collectors and real-time event log queries) to produce weighted stability score. Lower scores
    indicate higher instability and increased risk of service disruption.
    
    Stability Scoring Model (100 points, deductions applied):
    
    Application Crashes (40 points maximum):
    - Deduction: 2 points per crash in last 24 hours
    - Maximum deduction: 40 points
    - Indicates: Application instability, compatibility issues
    - Source: STATAppCrashes24h field (from telemetry collector)
    
    Application Hangs (30 points maximum):
    - Deduction: 1.5 points per hang in last 24 hours
    - Maximum deduction: 30 points
    - Indicates: Resource contention, deadlocks
    - Source: STATAppHangs24h field (from telemetry collector)
    
    Service Failures (30 points maximum):
    - Deduction: 3 points per service failure in last 24 hours
    - Maximum deduction: 30 points
    - Indicates: Service instability, dependencies missing
    - Source: Real-time query of System event log (Event IDs 7031, 7034)
    
    Blue Screen Events (50 points maximum):
    - Deduction: 20 points per BSOD in last 30 days
    - Maximum deduction: 50 points (critical severity)
    - Indicates: Hardware failures, driver issues, system corruption
    - Source: STATBSODCount30d field (from telemetry collector)
    
    Recent Reboot Instability Penalty:
    - Deduction: 10 points if uptime < 1 day AND crashes > 0
    - Indicates: Post-reboot instability, boot process issues
    - Source: Win32_OperatingSystem LastBootUpTime
    
    Score Interpretation:
    - 90-100: Excellent stability
    - 75-89: Good stability
    - 60-74: Fair stability - monitor for trends
    - 50-59: Poor stability - investigation required
    - Below 50: Critical instability - immediate action required

.NOTES
    Frequency: Every 4 hours
    Runtime: ~10 seconds
    Timeout: 60 seconds
    Context: SYSTEM
    
    Fields Updated:
    - OPSStabilityScore (Integer: 0-100 stability score)
    - OPSLastScoreUpdate (Text: timestamp in yyyy-MM-dd HH:mm:ss format)
    
    Fields Read (from other scripts):
    - STATAppCrashes24h (Integer: from 06_Telemetry_Collector.ps1)
    - STATAppHangs24h (Integer: from 06_Telemetry_Collector.ps1)
    - STATBSODCount30d (Integer: from 06_Telemetry_Collector.ps1)
    
    Dependencies:
    - Windows System event log
    - WMI/CIM: Win32_OperatingSystem
    - Telemetry collector scripts must run first
    
    Event IDs Monitored:
    - 7031: Service crash
    - 7034: Service unexpected termination
    
    Integration Pattern:
    - Reads reliability metrics from telemetry fields
    - Performs additional real-time service failure check
    - Combines multiple signals into unified stability score
    - Provides operational health metric for alerting
    
    Framework Version: 4.0
    Last Updated: February 4, 2026
#>

param()

try {
    Write-Output "Starting Stability Analyzer (v4.0)..."

    # Initialize score at maximum
    $stabilityScore = 100
    $deductions = @()

    # Read telemetry metrics from custom fields
    Write-Output "INFO: Reading reliability telemetry..."
    
    $appCrashes = Ninja-Property-Get STATAppCrashes24h
    if ([string]::IsNullOrEmpty($appCrashes)) { $appCrashes = 0 }
    Write-Output "INFO: Application crashes (24h): $appCrashes"

    $appHangs = Ninja-Property-Get STATAppHangs24h
    if ([string]::IsNullOrEmpty($appHangs)) { $appHangs = 0 }
    Write-Output "INFO: Application hangs (24h): $appHangs"

    $bsodCount = Ninja-Property-Get STATBSODCount30d
    if ([string]::IsNullOrEmpty($bsodCount)) { $bsodCount = 0 }
    Write-Output "INFO: Blue screens (30d): $bsodCount"

    # Query service failures in real-time
    Write-Output "INFO: Querying service failure events..."
    $serviceFailures = 0
    try {
        $yesterday = (Get-Date).AddDays(-1)
        $serviceFailures = (Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Id = 7031, 7034
            StartTime = $yesterday
        } -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Output "INFO: Service failures (24h): $serviceFailures"
    } catch {
        Write-Output "WARNING: Unable to query service failure events"
        $serviceFailures = 0
    }

    # Get system uptime
    $os = Get-CimInstance Win32_OperatingSystem
    $uptimeDays = ((Get-Date) - $os.LastBootUpTime).Days
    $lastBoot = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
    Write-Output "INFO: System uptime: $uptimeDays days (last boot: $lastBoot)"

    # Calculate deductions
    Write-Output "INFO: Calculating stability deductions..."

    # Deduction 1: Application Crashes (max 40 points)
    if ($appCrashes -gt 0) {
        $deduction = $appCrashes * 2
        if ($deduction -gt 40) { $deduction = 40 }
        $stabilityScore -= $deduction
        $deductions += "Application crashes: -$deduction ($appCrashes events)"
        Write-Output "  Application crashes: -$deduction points"
    }

    # Deduction 2: Application Hangs (max 30 points)
    if ($appHangs -gt 0) {
        $deduction = [math]::Round($appHangs * 1.5)
        if ($deduction -gt 30) { $deduction = 30 }
        $stabilityScore -= $deduction
        $deductions += "Application hangs: -$deduction ($appHangs events)"
        Write-Output "  Application hangs: -$deduction points"
    }

    # Deduction 3: Service Failures (max 30 points)
    if ($serviceFailures -gt 0) {
        $deduction = $serviceFailures * 3
        if ($deduction -gt 30) { $deduction = 30 }
        $stabilityScore -= $deduction
        $deductions += "Service failures: -$deduction ($serviceFailures events)"
        Write-Output "  Service failures: -$deduction points"
    }

    # Deduction 4: Blue Screens (max 50 points, critical)
    if ($bsodCount -gt 0) {
        $deduction = $bsodCount * 20
        if ($deduction -gt 50) { $deduction = 50 }
        $stabilityScore -= $deduction
        $deductions += "Blue screens: -$deduction ($bsodCount events)"
        Write-Output "  Blue screens: -$deduction points (CRITICAL)"
    }

    # Deduction 5: Recent Reboot Instability
    if ($uptimeDays -lt 1 -and $appCrashes -gt 0) {
        $stabilityScore -= 10
        $deductions += "Post-reboot instability: -10 (crashes after recent boot)"
        Write-Output "  Post-reboot instability: -10 points"
    }

    # Enforce score boundaries
    if ($stabilityScore -lt 0) { $stabilityScore = 0 }
    if ($stabilityScore -gt 100) { $stabilityScore = 100 }

    # Update NinjaRMM custom fields
    Write-Output "INFO: Updating stability metrics..."
    Ninja-Property-Set OPSStabilityScore $stabilityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Stability analysis complete"
    Write-Output "FINAL SCORE: $stabilityScore/100"
    Write-Output "RELIABILITY METRICS:"
    Write-Output "  - Application Crashes (24h): $appCrashes"
    Write-Output "  - Application Hangs (24h): $appHangs"
    Write-Output "  - Service Failures (24h): $serviceFailures"
    Write-Output "  - Blue Screens (30d): $bsodCount"
    Write-Output "  - System Uptime: $uptimeDays days"
    
    if ($deductions.Count -gt 0) {
        Write-Output "STABILITY ISSUES IDENTIFIED:"
        $deductions | ForEach-Object { Write-Output "  - $_" }
    } else {
        Write-Output "No stability issues detected"
    }
    
    # Provide stability assessment
    if ($stabilityScore -ge 90) {
        Write-Output "ASSESSMENT: Excellent stability"
    } elseif ($stabilityScore -ge 75) {
        Write-Output "ASSESSMENT: Good stability"
    } elseif ($stabilityScore -ge 60) {
        Write-Output "ASSESSMENT: Fair stability - monitor for trends"
    } elseif ($stabilityScore -ge 50) {
        Write-Output "ASSESSMENT: Poor stability - investigation required"
    } else {
        Write-Output "ASSESSMENT: Critical instability - immediate action required"
    }
    
    if ($bsodCount -gt 0) {
        Write-Output "CRITICAL: Blue screen events detected - hardware or driver issues likely"
    }

    exit 0
} catch {
    Write-Output "ERROR: Stability Analyzer failed: $_"
    Write-Output "$($_.ScriptStackTrace)"
    exit 1
}
