#!/usr/bin/env pwsh
# Script 06: Telemetry Collector
# Purpose: Collect custom telemetry not available natively (crashes, hangs, failures)
# Frequency: Every 4 hours
# Runtime: ~25 seconds
# Timeout: 90 seconds
# Context: SYSTEM
# Version: 4.0 (Native Integration)

try {
    Write-Output "Starting Telemetry Collector (v4.0 Native-Enhanced)"

    $startTime24h = (Get-Date).AddHours(-24)
    $startTime30d = (Get-Date).AddDays(-30)

    $appCrashes = 0
    try {
        $appCrashes = (Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Id = 1000, 1001
            StartTime = $startTime24h
        } -ErrorAction SilentlyContinue | Measure-Object).Count
    } catch {
        $appCrashes = 0
    }

    $appHangs = 0
    try {
        $appHangs = (Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Id = 1002
            StartTime = $startTime24h
        } -ErrorAction SilentlyContinue | Measure-Object).Count
    } catch {
        $appHangs = 0
    }

    $serviceFailures = 0
    try {
        $serviceFailures = (Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Id = 7031, 7034
            StartTime = $startTime24h
        } -ErrorAction SilentlyContinue | Measure-Object).Count
    } catch {
        $serviceFailures = 0
    }

    $bsodCount = 0
    try {
        $bsodCount = (Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Id = 1001, 41
            StartTime = $startTime30d
        } -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'bugcheck|Blue Screen|unexpected shutdown' } | Measure-Object).Count
    } catch {
        $bsodCount = 0
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $uptimeDays = [int]((Get-Date) - $os.LastBootUpTime).Days

    Ninja-Property-Set STATAppCrashes24h $appCrashes
    Ninja-Property-Set STATAppHangs24h $appHangs
    Ninja-Property-Set STATServiceFailures24h $serviceFailures
    Ninja-Property-Set STATBSODCount30d $bsodCount
    Ninja-Property-Set STATUptimeDays $uptimeDays
    Ninja-Property-Set STATLastTelemetryUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Telemetry collected"
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
