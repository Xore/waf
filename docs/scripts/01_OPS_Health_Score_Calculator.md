# Script 01: OPS Health Score Calculator

**File:** Script_01_OPS_Health_Score_Calculator.md  
**Version:** v1.0  
**Script Number:** 01  
**Category:** Core Monitoring - OPS Scores  
**Last Updated:** February 2, 2026

---

## Purpose

Calculate overall device health composite score combining multiple data sources.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~15 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Queries **Disk Free Space** (native) for capacity assessment
- Queries **Memory Utilization** (native) for pressure detection
- Queries **CPU Utilization** (native) for performance assessment
- Combines with custom telemetry ([STATAppCrashes24h](../core/11_STAT_Core_Telemetry.md), etc.)

---

## Fields Updated

- [OPSHealthScore](../core/10_OPS_Core_Operational_Scores.md) (Integer 0-100)
- [OPSLastScoreUpdate](../core/10_OPS_Core_Operational_Scores.md) (DateTime)

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Health Score Calculator (v1.0 Native-Enhanced)"

    # Initialize base score
    $healthScore = 100

    # Query native metrics
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    # Query custom telemetry
    $crashes = Ninja-Property-Get STATAppCrashes24h
    if ([string]::IsNullOrEmpty($crashes)) { $crashes = 0 }

    # Calculate deductions
    if ($crashes -gt 10) { $healthScore -= 20 }
    elseif ($crashes -gt 5) { $healthScore -= 10 }
    elseif ($crashes -gt 2) { $healthScore -= 5 }

    if ($diskFreePercent -lt 5) { $healthScore -= 30 }
    elseif ($diskFreePercent -lt 10) { $healthScore -= 20 }
    elseif ($diskFreePercent -lt 15) { $healthScore -= 15 }

    if ($memUtilization -gt 95) { $healthScore -= 20 }
    elseif ($memUtilization -gt 90) { $healthScore -= 15 }
    elseif ($memUtilization -gt 85) { $healthScore -= 10 }

    if ($cpuUtilization -gt 90) { $healthScore -= 15 }
    elseif ($cpuUtilization -gt 80) { $healthScore -= 10 }

    # Ensure score stays within bounds
    if ($healthScore -lt 0) { $healthScore = 0 }
    if ($healthScore -gt 100) { $healthScore = 100 }

    # Update fields
    Ninja-Property-Set OPSHealthScore $healthScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Health Score = $healthScore"
    Write-Output "  Disk Free: $diskFreePercent%"
    Write-Output "  Memory Utilization: $memUtilization%"
    Write-Output "  CPU Utilization: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  Crashes (24h): $crashes"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [OPS Custom Fields](../core/10_OPS_Core_Operational_Scores.md)
- [STAT Telemetry Fields](../core/11_STAT_Core_Telemetry.md)
- [Script 02: Stability Analyzer](Script_02_OPS_Stability_Analyzer.md)
- [Script 06: Telemetry Collector](Script_06_STAT_Telemetry_Collector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_01_OPS_Health_Score_Calculator.md  
**Version:** v1.0  
**Status:** Production Ready
