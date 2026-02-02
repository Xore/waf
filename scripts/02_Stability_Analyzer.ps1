#!/usr/bin/env pwsh
# Script 02: Stability Analyzer
# Purpose: Calculate system and application stability score based on crashes and failures
# Frequency: Every 4 hours
# Runtime: ~10 seconds
# Timeout: 60 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Stability Analyzer (v4.0 Native-Enhanced)"

    $stabilityScore = 100

    $appCrashes = Ninja-Property-Get STATAppCrashes24h
    if ([string]::IsNullOrEmpty($appCrashes)) { $appCrashes = 0 }

    $appHangs = Ninja-Property-Get STATAppHangs24h
    if ([string]::IsNullOrEmpty($appHangs)) { $appHangs = 0 }

    $bsodCount = Ninja-Property-Get STATBSODCount30d
    if ([string]::IsNullOrEmpty($bsodCount)) { $bsodCount = 0 }

    $serviceFailures = 0
    try {
        $yesterday = (Get-Date).AddDays(-1)
        $serviceFailures = (Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Id = 7031, 7034
            StartTime = $yesterday
        } -ErrorAction SilentlyContinue | Measure-Object).Count
    } catch {
        $serviceFailures = 0
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $uptimeDays = ((Get-Date) - $os.LastBootUpTime).Days

    if ($appCrashes -gt 0) {
        $deduction = $appCrashes * 2
        if ($deduction -gt 40) { $deduction = 40 }
        $stabilityScore -= $deduction
    }

    if ($appHangs -gt 0) {
        $deduction = [math]::Round($appHangs * 1.5)
        if ($deduction -gt 30) { $deduction = 30 }
        $stabilityScore -= $deduction
    }

    if ($serviceFailures -gt 0) {
        $deduction = $serviceFailures * 3
        if ($deduction -gt 30) { $deduction = 30 }
        $stabilityScore -= $deduction
    }

    if ($bsodCount -gt 0) {
        $deduction = $bsodCount * 20
        if ($deduction -gt 50) { $deduction = 50 }
        $stabilityScore -= $deduction
    }

    if ($uptimeDays -lt 1 -and $appCrashes -gt 0) {
        $stabilityScore -= 10
    }

    if ($stabilityScore -lt 0) { $stabilityScore = 0 }
    if ($stabilityScore -gt 100) { $stabilityScore = 100 }

    Ninja-Property-Set OPSStabilityScore $stabilityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Stability Score = $stabilityScore"
    Write-Output "  App Crashes (24h): $appCrashes"
    Write-Output "  App Hangs (24h): $appHangs"
    Write-Output "  Service Failures (24h): $serviceFailures"
    Write-Output "  BSODs (30d): $bsodCount"
    Write-Output "  Uptime: $uptimeDays days"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
