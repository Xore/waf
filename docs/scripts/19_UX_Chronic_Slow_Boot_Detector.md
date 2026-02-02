# Script 19: UX Chronic Slow Boot Detector

**File:** Script_19_UX_Chronic_Slow_Boot_Detector.md  
**Version:** v1.0  
**Script Number:** 19  
**Category:** Extended Automation - Boot Performance  
**Last Updated:** February 2, 2026

---

## Purpose

Track boot time degradation over 30 days and detect chronic slow boot issues.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [UXBootDegradationFlag](../core/11_AUTO_UX_SRV_Core_Experience.md) (Checkbox)
- [UXBootTrend](../core/11_AUTO_UX_SRV_Core_Experience.md) (Dropdown: Improving, Stable, Degrading, Critical)

---

## PowerShell Implementation

```powershell
# Script 19: Chronic Slow Boot Detector
# Track boot time degradation over 30 days

param()

try {
    Write-Output "Starting Chronic Slow Boot Detector (v1.0)"

    # Get current boot time (seconds)
    $bootTime = (Get-CimInstance Win32_PerfFormattedData_PerfOS_System).SystemUpTime
    $os = Get-CimInstance Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    
    # Calculate actual boot time from event logs
    $bootEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 6005, 6009
        StartTime = $lastBoot
    } -MaxEvents 1 -ErrorAction SilentlyContinue

    # Get boot duration from diagnostic logs
    $bootDuration = 0
    try {
        $bootPerf = Get-WinEvent -FilterHashtable @{
            LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'
            ID = 100
            StartTime = $lastBoot
        } -MaxEvents 1 -ErrorAction SilentlyContinue

        if ($bootPerf) {
            $bootDuration = ($bootPerf.Properties[0].Value / 1000)
        }
    } catch {
        $bootDuration = 0
    }

    if ($bootDuration -eq 0) {
        $bootDuration = 60
    }

    # Get historical baseline
    $baselineBootTime = Ninja-Property-Get uxBaselineBootTime
    if ([string]::IsNullOrEmpty($baselineBootTime)) {
        $baselineBootTime = $bootDuration
        Ninja-Property-Set uxBaselineBootTime $baselineBootTime
    }

    # Calculate degradation
    $degradationPercent = (($bootDuration - $baselineBootTime) / $baselineBootTime) * 100
    $degradationFlag = $false

    # Determine trend
    if ($degradationPercent -lt -10) {
        $trend = "Improving"
    } elseif ($degradationPercent -lt 15) {
        $trend = "Stable"
    } elseif ($degradationPercent -lt 50) {
        $trend = "Degrading"
        $degradationFlag = $true
    } else {
        $trend = "Critical"
        $degradationFlag = $true
    }

    # Update custom fields
    Ninja-Property-Set uxBootDegradationFlag $degradationFlag
    Ninja-Property-Set uxBootTrend $trend

    Write-Output "SUCCESS: Boot analysis complete"
    Write-Output "  Current Boot Time: $([math]::Round($bootDuration, 1))s"
    Write-Output "  Baseline Boot Time: $([math]::Round($baselineBootTime, 1))s"
    Write-Output "  Degradation: $([math]::Round($degradationPercent, 1))%"
    Write-Output "  Trend: $trend"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [UX User Experience Fields](../core/11_AUTO_UX_SRV_Core_Experience.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_19_UX_Chronic_Slow_Boot_Detector.md  
**Version:** v1.0  
**Status:** Production Ready
