# Script 16: SEC Suspicious Login Pattern Detector

**File:** Script_16_SEC_Suspicious_Login_Detector.md  
**Version:** v1.0  
**Script Number:** 16  
**Category:** Extended Automation - Security Threat Detection  
**Last Updated:** February 2, 2026

---

## Purpose

Detect anomalous authentication patterns and suspicious login activity.

---

## Execution Details

- **Frequency:** Every 4 hours
- **Runtime:** ~25 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [SECSuspiciousLoginScore](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md) (Integer 0-100)

---

## PowerShell Implementation

```powershell
# Script 16: Suspicious Login Pattern Detector
# Analyzes authentication events for anomalies

param()

try {
    Write-Output "Starting Suspicious Login Pattern Detector (v1.0)"

    $suspicionScore = 0
    $startTime = (Get-Date).AddHours(-4)

    # Check for multiple failed logons from same source
    $failedLogons = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($failedLogons.Count -gt 10) {
        $suspicionScore += 20
        Write-Output "ALERT: $($failedLogons.Count) failed logons detected (+20)"
    }

    # Check for logons at unusual times (2am-5am)
    $currentHour = (Get-Date).Hour
    if ($currentHour -ge 2 -and $currentHour -le 5) {
        $recentLogons = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4624
            StartTime = $startTime
        } -ErrorAction SilentlyContinue

        if ($recentLogons.Count -gt 0) {
            $suspicionScore += 15
            Write-Output "ALERT: Logon during unusual hours (2am-5am) (+15)"
        }
    }

    # Check for account lockouts
    $lockouts = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4740
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($lockouts.Count -gt 2) {
        $suspicionScore += 25
        Write-Output "ALERT: $($lockouts.Count) account lockouts detected (+25)"
    }

    # Check for privilege escalation attempts
    $privEsc = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4672
        StartTime = $startTime
    } -ErrorAction SilentlyContinue

    if ($privEsc.Count -gt 20) {
        $suspicionScore += 10
        Write-Output "ALERT: Excessive privilege escalations detected (+10)"
    }

    # Cap at 100
    if ($suspicionScore -gt 100) { $suspicionScore = 100 }

    Ninja-Property-Set secSuspiciousLoginScore $suspicionScore

    if ($suspicionScore -ge 50) {
        Write-Output "CRITICAL: High suspicious login score: $suspicionScore"
    } else {
        Write-Output "SUCCESS: Suspicious login score: $suspicionScore (normal)"
    }

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [SEC Security Fields](../core/14_BASE_SEC_UPD_Core_Security_Baseline.md)
- [Script 15: Security Posture Consolidator](Script_15_SEC_Security_Posture_Consolidator.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_16_SEC_Suspicious_Login_Detector.md  
**Version:** v1.0  
**Status:** Production Ready
