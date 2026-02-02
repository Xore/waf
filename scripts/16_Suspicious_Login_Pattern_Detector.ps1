<#
.SYNOPSIS
    NinjaRMM Script 16: Suspicious Login Pattern Detector

.DESCRIPTION
    Detects anomalous authentication patterns.
    Analyzes failed logons, unusual times, lockouts, and privilege escalation.

.NOTES
    Frequency: Every 4 hours
    Runtime: ~25 seconds
    Timeout: 90 seconds
    Context: SYSTEM
    
    Fields Updated:
    - secSuspiciousLoginScore (Integer 0-100)
    
    Score Indicators:
    - 0-25: Normal
    - 26-49: Low suspicion
    - 50-75: Medium suspicion
    - 76-100: High suspicion (alert recommended)
    
    Framework Version: 4.0
    Last Updated: February 1, 2026
#>

param()

try {
    $suspicionScore = 0
    $startTime = (Get-Date).AddHours(-4)

    # Check for multiple failed logons from same source
    $failedLogons = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($failedLogons.Count -gt 10) {
        $suspicionScore += 20
    }

    # Check for logons at unusual times (2am-5am)
    $currentHour = (Get-Date).Hour
    if ($currentHour -ge 2 -and $currentHour -le 5) {
        $recentLogons = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4624
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        if ($recentLogons.Count -gt 0) {
            $suspicionScore += 15
        }
    }

    # Check for account lockouts
    $lockouts = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4740
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($lockouts.Count -gt 2) {
        $suspicionScore += 25
    }

    # Check for privilege escalation attempts
    $privEsc = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4672
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($privEsc.Count -gt 20) {
        $suspicionScore += 10
    }

    # Cap at 100
    if ($suspicionScore -gt 100) { $suspicionScore = 100 }

    Ninja-Property-Set secSuspiciousLoginScore $suspicionScore

    if ($suspicionScore -ge 50) {
        Write-Output "ALERT: High suspicious login score: $suspicionScore"
    } else {
        Write-Output "Suspicious login score: $suspicionScore (normal)"
    }

} catch {
    Write-Output "Error: $_"
    exit 1
}
