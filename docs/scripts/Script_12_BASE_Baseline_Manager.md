# Script 12: BASE Baseline Manager

**File:** Script_12_BASE_Baseline_Manager.md  
**Version:** v1.0  
**Script Number:** 12  
**Category:** Core Monitoring - Baseline Management  
**Last Updated:** February 2, 2026

---

## Purpose

Establish and track performance baselines, detect drift.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Native Integration (v1.0)

- Uses native metrics (CPU, Memory, Disk) to establish baseline
- Compares current native metrics to baseline for drift detection

---

## Fields Updated

- [BASEBusinessCriticality](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Dropdown: Standard, High, Critical)
- [BASEDriftScore](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer 0-100)
- [BASEPerformanceBaseline](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Text/JSON)

---

## PowerShell Implementation

```powershell
try {
    Write-Output "Starting Baseline Manager (v1.0 Native-Enhanced)"

    # Query current native metrics
    $cpuUtilization = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3 | 
        Select-Object -ExpandProperty CounterSamples | 
        Measure-Object -Property CookedValue -Average).Average

    $os = Get-CimInstance Win32_OperatingSystem
    $memUtilization = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)

    # Get existing baseline
    $baselineJson = Ninja-Property-Get BASEPerformanceBaseline
    
    if ([string]::IsNullOrEmpty($baselineJson)) {
        # First run - establish baseline
        $baseline = @{
            CPUAverage = $cpuUtilization
            MemAverage = $memUtilization
            DiskFreeAverage = $diskFreePercent
            EstablishedDate = (Get-Date -Format 'yyyy-MM-dd')
            SampleCount = 1
        }
        
        $driftScore = 0
        Write-Output "Baseline established (first run)"
    } else {
        # Parse existing baseline
        $baseline = $baselineJson | ConvertFrom-Json
        
        # Calculate drift from baseline
        $cpuDrift = [math]::Abs($cpuUtilization - $baseline.CPUAverage)
        $memDrift = [math]::Abs($memUtilization - $baseline.MemAverage)
        $diskDrift = [math]::Abs($diskFreePercent - $baseline.DiskFreeAverage)
        
        # Calculate drift score (0 = no drift, 100 = maximum drift)
        $driftScore = 0
        if ($cpuDrift -gt 20) { $driftScore += 33 }
        elseif ($cpuDrift -gt 10) { $driftScore += 15 }
        
        if ($memDrift -gt 20) { $driftScore += 33 }
        elseif ($memDrift -gt 10) { $driftScore += 15 }
        
        if ($diskDrift -gt 20) { $driftScore += 34 }
        elseif ($diskDrift -gt 10) { $driftScore += 15 }
        
        Write-Output "Drift detected: CPU=$([math]::Round($cpuDrift,1))%, Mem=$([math]::Round($memDrift,1))%, Disk=$([math]::Round($diskDrift,1))%"
        
        # Update baseline with moving average (80% old, 20% new)
        $baseline.CPUAverage = ($baseline.CPUAverage * 0.8) + ($cpuUtilization * 0.2)
        $baseline.MemAverage = ($baseline.MemAverage * 0.8) + ($memUtilization * 0.2)
        $baseline.DiskFreeAverage = ($baseline.DiskFreeAverage * 0.8) + ($diskFreePercent * 0.2)
        $baseline.SampleCount++
    }

    # Convert baseline back to JSON
    $baselineJson = $baseline | ConvertTo-Json -Compress

    # Update fields
    Ninja-Property-Set BASEPerformanceBaseline $baselineJson
    Ninja-Property-Set BASEDriftScore $driftScore

    Write-Output "SUCCESS: Baseline management completed"
    Write-Output "  Current CPU: $([math]::Round($cpuUtilization,1))% (Baseline: $([math]::Round($baseline.CPUAverage,1))%)"
    Write-Output "  Current Memory: $memUtilization% (Baseline: $([math]::Round($baseline.MemAverage,1))%)"
    Write-Output "  Current Disk Free: $diskFreePercent% (Baseline: $([math]::Round($baseline.DiskFreeAverage,1))%)"
    Write-Output "  Drift Score: $driftScore"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [BASE Baseline Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [DRIFT Drift Detection Fields](../core/12_DRIFT_CAP_BAT_Core_Monitoring.md)
- [Script 13: Drift Detector](Script_13_DRIFT_Detector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_12_BASE_Baseline_Manager.md  
**Version:** v1.0  
**Status:** Production Ready
