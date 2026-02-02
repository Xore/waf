# Script 30: UX User Environment Friction Tracker

**File:** Script_30_UX_User_Environment_Friction.md  
**Version:** v1.0  
**Script Number:** 30  
**Category:** Advanced Telemetry - User Experience  
**Last Updated:** February 2, 2026

---

## Purpose

Track login retries, credential issues, and authentication friction.

---

## Execution Details

- **Frequency:** Daily
- **Runtime:** ~20 seconds
- **Timeout:** 60 seconds
- **Context:** SYSTEM

---

## Fields Updated

- [UXLoginRetryCount24h](../core/11_AUTO_UX_SRV_Core_Experience.md) (Integer)

---

## PowerShell Implementation

```powershell
# Script 30: User Environment Friction Tracker
# Tracks login retries and credential issues

param()

try {
    Write-Output "Starting User Environment Friction Tracker (v1.0)"

    $startTime = (Get-Date).AddHours(-24)

    # Check for credential manager errors
    $credErrors = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ProviderName = 'Microsoft-Windows-User Profiles Service'
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.LevelDisplayName -eq 'Error'
    }

    # Check for failed interactive logons (wrong password)
    $failedInteractive = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = $startTime
    } -ErrorAction SilentlyContinue | Where-Object {
        # Logon Type 2 = Interactive
        $_.Properties[10].Value -eq 2
    }

    $totalRetries = $credErrors.Count + $failedInteractive.Count

    Ninja-Property-Set uxLoginRetryCount24h $totalRetries

    Write-Output "SUCCESS: User friction tracking completed"
    Write-Output "  Credential Errors: $($credErrors.Count)"
    Write-Output "  Failed Interactive Logons: $($failedInteractive.Count)"
    Write-Output "  Total Login Retries (24h): $totalRetries"

    exit 0
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}
```

---

## Related Documentation

- [UX User Experience Fields](../core/11_AUTO_UX_SRV_Core_Experience.md)
- [Script 16: Suspicious Login Detector](Script_16_SEC_Suspicious_Login_Detector.md)
- [Framework Architecture](../../01_Framework_Architecture.md)

---

**File:** Script_30_UX_User_Environment_Friction.md  
**Version:** v1.0  
**Status:** Production Ready
