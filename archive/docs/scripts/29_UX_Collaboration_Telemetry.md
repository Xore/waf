# Script 29: UX Collaboration and Outlook Telemetry

**File:** Script_29_UX_Collaboration_Telemetry.md  
**Version:** v1.0  
**Script Number:** 29  
**Category:** Advanced Telemetry - Collaboration Tools  
**Last Updated:** February 2, 2026

---

## Purpose

Monitor Microsoft Teams and Outlook performance and failures.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~25 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [UXCollabFailures24h](../core/11_AUTO_UX_SRV_Core_Experience.md) (Integer)
- [UXCollabPoorQuality24h](../core/11_AUTO_UX_SRV_Core_Experience.md) (Integer)
- APPOutlookFailures24h (Integer)

---

## PowerShell Implementation

```powershell
# Script 29: Collaboration and Outlook UX Telemetry
# Monitors Teams and Outlook performance

param()

try {
    Write-Output "Starting Collaboration Telemetry (v1.0)"

    $startTime = (Get-Date).AddHours(-24)

    # Check Teams crashes
    $teamsCrashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match "Teams.exe"
    }

    $teamsFailures = $teamsCrashes.Count

    # Check Outlook crashes
    $outlookCrashes = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1000
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match "OUTLOOK.EXE"
    }

    $outlookFailures = $outlookCrashes.Count

    # Check Teams performance issues (hangs)
    $teamsHangs = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1002
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match "Teams.exe"
    }

    $poorQuality = $teamsHangs.Count

    # Update custom fields
    Ninja-Property-Set uxCollabFailures24h $teamsFailures
    Ninja-Property-Set uxCollabPoorQuality24h $poorQuality
    Ninja-Property-Set appOutlookFailures24h $outlookFailures

    Write-Output "SUCCESS: Collaboration telemetry collected"
    Write-Output "  Teams Failures (24h): $teamsFailures"
    Write-Output "  Teams Poor Quality (24h): $poorQuality"
    Write-Output "  Outlook Failures (24h): $outlookFailures"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [UX User Experience Fields](../core/11_AUTO_UX_SRV_Core_Experience.md)
- [Script 17: Application Experience Profiler](Script_17_UX_Application_Experience_Profiler.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_29_UX_Collaboration_Telemetry.md  
**Version:** v1.0  
**Status:** Production Ready
