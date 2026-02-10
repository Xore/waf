# Script 06: STAT Telemetry Collector

**File:** Script_06_STAT_Telemetry_Collector.md  
**Version:** v1.0  
**Script Number:** 06  
**Category:** Core Monitoring - Telemetry  
**Last Updated:** February 2, 2026

---

## Purpose

Collect custom telemetry not available natively (crashes, hangs, failures).

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~25 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Why Custom (Not Native)

NinjaOne doesn't aggregate crash/hang/failure counts over time periods. This script provides historical frequency tracking essential for stability scoring.

---

## Fields Updated

- [STATAppCrashes24h](../core/11_STAT_Core_Telemetry.md) (Integer) - Application crash count
- [STATAppHangs24h](../core/11_STAT_Core_Telemetry.md) (Integer) - Application hang count
- [STATServiceFailures24h](../core/11_STAT_Core_Telemetry.md) (Integer) - Service failure count
- [STATBSODCount30d](../core/11_STAT_Core_Telemetry.md) (Integer) - BSOD count
- [STATUptimeDays](../core/11_STAT_Core_Telemetry.md) (Integer) - Days since reboot
- [STATLastTelemetryUpdate](../core/11_STAT_Core_Telemetry.md) (DateTime) - Last collection timestamp

---

## Event Sources

- **Application Event Log:** Event IDs 1000, 1001 (crashes), 1002 (hangs)
- **System Event Log:** Event IDs 7031, 7034 (service failures), 1001 (BugCheck), 41 (Kernel-Power)

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Telemetry Collector (v1.0)"

    # Calculate time windows
    $now = Get-Date
    $24hAgo = $now.AddHours(-24)
    $30dAgo = $now.AddDays(-30)

    # Collect application crashes (24h)
    $crashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000, 1001
        StartTime = $24hAgo
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    # Collect application hangs (24h)
    $hangs = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1002
        StartTime = $24hAgo
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    # Collect service failures (24h)
    $serviceFailures = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 7031, 7034
        StartTime = $24hAgo
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    # Collect BSODs (30d)
    $bsods = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 1001, 41
        StartTime = $30dAgo
    } -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count

    # Calculate uptime
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = $now - $os.LastBootUpTime
    $uptimeDays = [math]::Round($uptime.TotalDays, 1)

    # Update fields
    Ninja-Property-Set STATAppCrashes24h $crashes
    Ninja-Property-Set STATAppHangs24h $hangs
    Ninja-Property-Set STATServiceFailures24h $serviceFailures
    Ninja-Property-Set STATBSODCount30d $bsods
    Ninja-Property-Set STATUptimeDays $uptimeDays
    Ninja-Property-Set STATLastTelemetryUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Telemetry collected"
    Write-Output "  Crashes (24h): $crashes"
    Write-Output "  Hangs (24h): $hangs"
    Write-Output "  Service Failures (24h): $serviceFailures"
    Write-Output "  BSODs (30d): $bsods"
    Write-Output "  Uptime (days): $uptimeDays"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [STAT Telemetry Fields](../core/11_STAT_Core_Telemetry.md)
- [Script 01: Health Score Calculator](Script_01_OPS_Health_Score_Calculator.md)
- [Script 02: Stability Analyzer](Script_02_OPS_Stability_Analyzer.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_06_STAT_Telemetry_Collector.md  
**Version:** v1.0  
**Status:** Production Ready
