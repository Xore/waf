# Script 05: OPS Capacity Analyzer

**File:** Script_05_OPS_Capacity_Analyzer.md  
**Version:** v1.0  
**Script Number:** 05  
**Category:** Core Monitoring - OPS Scores  
**Last Updated:** February 2, 2026

---

## Purpose

Calculate resource capacity and headroom score.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~15 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Queries **Disk Free Space** (native) for storage capacity
- Queries **Memory Utilization** (native) for memory capacity
- Combines with [CAPDaysUntilDiskFull](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md) (custom predictive field)

---

## Fields Updated

- [OPSCapacityScore](../core/10_OPS_Core_Operational_Scores.md) (Integer 0-100)
- [OPSLastScoreUpdate](../core/10_OPS_Core_Operational_Scores.md) (DateTime)

---

## Scoring Logic

```text
Base Score: 100

Deductions (using native metrics):
  - Disk Free Space < 20% (native): -30 points
  - Disk Free Space < 10% (native): -50 points (override)
  - Memory Utilization > 85% (native): -20 points
  - Days until disk full < 30 (custom): -15 points

Minimum Score: 0
```

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Capacity Analyzer (v1.0 Native-Enhanced)"

    $capacityScore = 100

    # Query native disk metrics
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    # Query native memory metrics
    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    # Query custom predictive field
    $daysUntilFull = Ninja-Property-Get CAPDaysUntilDiskFull
    if ([string]::IsNullOrEmpty($daysUntilFull)) { $daysUntilFull = 999 }

    # Calculate deductions
    if ($diskFreePercent -lt 10) {
        $capacityScore -= 50
        Write-Output "DEDUCTION: Disk < 10% free (-50)"
    } elseif ($diskFreePercent -lt 20) {
        $capacityScore -= 30
        Write-Output "DEDUCTION: Disk < 20% free (-30)"
    }

    if ($memUtilization -gt 85) {
        $capacityScore -= 20
        Write-Output "DEDUCTION: Memory > 85% utilized (-20)"
    }

    if ($daysUntilFull -lt 30 -and $daysUntilFull -gt 0) {
        $capacityScore -= 15
        Write-Output "DEDUCTION: Disk full in < 30 days (-15)"
    }

    # Ensure score stays within bounds
    if ($capacityScore -lt 0) { $capacityScore = 0 }
    if ($capacityScore -gt 100) { $capacityScore = 100 }

    Ninja-Property-Set OPSCapacityScore $capacityScore
    Ninja-Property-Set OPSLastScoreUpdate (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    Write-Output "SUCCESS: Capacity Score = $capacityScore"
    Write-Output "  Disk Free: $diskFreePercent%"
    Write-Output "  Memory Utilization: $memUtilization%"
    Write-Output "  Days Until Full: $daysUntilFull"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [OPS Custom Fields](../core/10_OPS_Core_Operational_Scores.md)
- [CAP Capacity Fields](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md)
- [Script 01: Health Score Calculator](Script_01_OPS_Health_Score_Calculator.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_05_OPS_Capacity_Analyzer.md  
**Version:** v1.0  
**Status:** Production Ready
