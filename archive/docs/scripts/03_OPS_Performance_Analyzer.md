# Script 03: OPS Performance Analyzer

**File:** Script_03_OPS_Performance_Analyzer.md  
**Version:** v1.0  
**Script Number:** 03  
**Category:** Core Monitoring - OPS Scores  
**Last Updated:** February 2, 2026

---

## Purpose

Calculate system performance and responsiveness score.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Queries **CPU Utilization** (native) for processor load
- Queries **Memory Utilization** (native) for memory pressure
- Queries **Disk Active Time** (native) for I/O performance
- Supplements with custom boot time measurement

---

## Fields Updated

- [OPSPerformanceScore](../core/10_OPS_Core_Operational_Scores.md) (Integer 0-100)
- [OPSLastScoreUpdate](../core/10_OPS_Core_Operational_Scores.md) (DateTime)

---

## Scoring Logic

```text
Base Score: 100

Deductions (using native metrics):
  - CPU Utilization > 80%: -15 points
  - Memory Utilization > 85%: -15 points
  - Disk Active Time > 80%: -10 points
  - Boot time > 120s: -15 points (custom)

Minimum Score: 0
```

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Performance Analyzer (v1.0 Native-Enhanced)"

    # Initialize base score
    $performanceScore = 100

    # Query native CPU metrics
    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    # Query native memory metrics
    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    # Query native disk metrics
    $diskActiveTime = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    # Query custom boot time
    $bootTime = Ninja-Property-Get STATBootTimeSeconds
    if ([string]::IsNullOrEmpty($bootTime)) { $bootTime = 0 }

    # Calculate deductions
    if ($cpuUtilization -gt 80) { $performanceScore -= 15 }
    if ($memUtilization -gt 85) { $performanceScore -= 15 }
    if ($diskActiveTime -gt 80) { $performanceScore -= 10 }
    if ($bootTime -gt 120) { $performanceScore -= 15 }

    # Ensure score stays within bounds
    if ($performanceScore -lt 0) { $performanceScore = 0 }
    if ($performanceScore -gt 100) { $performanceScore = 100 }

    # Update fields
    Ninja-Property-Set OPSPerformanceScore $performanceScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Performance Score = $performanceScore"
    Write-Output "  CPU Utilization: $([math]::Round($cpuUtilization, 1))%"
    Write-Output "  Memory Utilization: $memUtilization%"
    Write-Output "  Disk Active Time: $([math]::Round($diskActiveTime, 1))%"
    Write-Output "  Boot Time: ${bootTime}s"

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
- [Script 01: Health Score Calculator](Script_01_OPS_Health_Score_Calculator.md)
- [Script 02: Stability Analyzer](Script_02_OPS_Stability_Analyzer.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_03_OPS_Performance_Analyzer.md  
**Version:** v1.0  
**Status:** Production Ready
