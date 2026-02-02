# Script 17: UX Application Experience Profiler

**File:** Script_17_UX_Application_Experience_Profiler.md  
**Version:** v1.0  
**Script Number:** 17  
**Category:** Extended Automation - User Experience  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor application performance and user experience through crash/hang tracking.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~30 seconds
- **Timeout:** 90 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [UXExperienceScore](../core/11_AUTO_UX_SRV_Core_Experience.md) (Integer 0-100)
- [UXApplicationHangCount24h](../core/11_AUTO_UX_SRV_Core_Experience.md) (Integer)
- [APPTopCrashingApp](../core/11_AUTO_UX_SRV_Core_Experience.md) (Text)

---

## PowerShell Implementation

```powershell
# Script 17: Application Experience Profiler
# Analyzes application crashes and hangs

param()

try {
    Write-Output "Starting Application Experience Profiler (v1.0)"

    $score = 100
    $startTime = (Get-Date).AddHours(-24)

    # Get application crashes
    $crashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000, 1001
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $crashCount = $crashes.Count

    # Get application hangs
    $hangs = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1002
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    $hangCount = $hangs.Count

    # Calculate score deductions
    $score -= ($crashCount * 5)
    $score -= ($hangCount * 3)

    if ($score -lt 0) { $score = 0 }

    # Find top crashing app
    $topCrasher = "None"
    if ($crashes.Count -gt 0) {
        $crashApps = $crashes | ForEach-Object {
            if ($_.Message -match "Application: (.+?)\s") {
                $matches[1]
            }
        }
        $topCrasher = ($crashApps | Group-Object | Sort-Object Count -Descending | 
            Select-Object -First 1).Name
        
        if ([string]::IsNullOrEmpty($topCrasher)) {
            $topCrasher = "Unknown"
        }
    }

    # Update custom fields
    Ninja-Property-Set uxExperienceScore $score
    Ninja-Property-Set uxApplicationHangCount24h $hangCount
    Ninja-Property-Set appTopCrashingApp $topCrasher

    Write-Output "SUCCESS: UX Experience Score = $score"
    Write-Output "  Application Crashes (24h): $crashCount"
    Write-Output "  Application Hangs (24h): $hangCount"
    Write-Output "  Top Crashing App: $topCrasher"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [UX User Experience Fields](../core/11_AUTO_UX_SRV_Core_Experience.md)
- [STAT Telemetry Fields](../core/11_STAT_Core_Telemetry.md)
- [Script 06: Telemetry Collector](Script_06_STAT_Telemetry_Collector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_17_UX_Application_Experience_Profiler.md  
**Version:** v1.0  
**Status:** Production Ready
